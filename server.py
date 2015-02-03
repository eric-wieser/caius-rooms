# system includes
import random
import re
import logging
import contextlib
from datetime import datetime

# pip includes
import sqlalchemy
from sqlalchemy.orm.exc import NoResultFound, MultipleResultsFound
import bottle
from bottle import *
from bottle.ext.sqlalchemy import SQLAlchemyPlugin
from beaker.middleware import SessionMiddleware
import raven

# our includes
import database.orm as m
import database.db
from utils import needs_auth

@contextlib.contextmanager
def base_route(app, base):
	""" Utility function for declaring a bunch of subroutes """
	old_route = app.route
	app.route = lambda path, *args, **kwargs: old_route(base + path, *args, **kwargs)
	try:
		yield
	finally:
		app.route = old_route


# create our app
app = Bottle()

# expose get_url to all templates, so that they don't need to hard-code urls
SimpleTemplate.defaults["get_url"] = app.get_url

# install the sqlalchemy plugin, which injects a `db` argument into every route
app.install(SQLAlchemyPlugin(
	engine=database.db.engine,
	metadata=m.Base.metadata,
	keyword='db',
	use_kwargs=True
))


@app.install
def get_authed_user(callback):
	""" A plugin to put the loggedin-user db object at `request.user` """
	def wrapper(*args, **kwargs):
		db = kwargs.get('db')
		if db and 'user' in request.session:
			crsid = request.session['user']
			try:
				request.user = db.query(m.Person).filter_by(crsid=crsid).one()
			except NoResultFound:
				request.user = m.Person(crsid=crsid, name="{} (no records)".format(crsid))
			request.user.last_seen = datetime.now()
		else:
			request.user = None

		try:
			return callback(*args, **kwargs)
		finally:
			request.user = None

	return wrapper


sqlalchemy_log = logging.getLogger('sqlalchemy.engine')
sqlalchemy_log.setLevel(logging.INFO)

@app.install
def log_sql(callback):
	""" A plugin to log all sql statements executed by a route to a file of a matching name` """
	def wrapper(*args, **kwargs):
		import os

		fname = 'logs/{}.log'.format(request.path
			.replace('/', '.')
			.replace('<', '')
			.replace('>', '')
			.lstrip('.')
		)
		try:
			os.remove(fname)
		except:
			pass

		handler = logging.FileHandler(fname)
		sqlalchemy_log.addHandler(handler)
		try:
			return callback(*args, **kwargs)
		finally:
			sqlalchemy_log.removeHandler(handler)

	return wrapper

def get_last_ballot(db):
	"""Get the ballot that was run to allocate the current students"""
	from datetime import date
	now = date.today()
	if now.month <= 8:
		return db.query(m.BallotSeason).get(now.year - 1)
	else:
		return db.query(m.BallotSeason).get(now.year)


def get_ballot(db):
	if request.query.ballot:
		try:
			byear = int(request.query.ballot)
		except ValueError:
			raise HTTPError(400, "Invalid ballot year {!r}".format(request.query.ballot))

		try:
			return db.query(m.BallotSeason).filter(m.BallotSeason.year == byear).one()
		except NoResultFound:
			raise HTTPError(404, "Could not find a ballot for the year {}".format(byear))

	else:
		res = get_last_ballot(db)
		if res:
			return res
		else:
			raise HTTPError(500, "Could not get current ballot")


# declare basic routes - index, static files, and error page
@app.route('/static/<path:path>', name='static', skip=[get_authed_user])
def static(path):
	return static_file(path, root='static')

@app.route('/')
def show_index(db):
	return template('index', db=db)

@app.error(404)
@app.error(403)
@get_authed_user
def error_handler(res):
	return template('messages/error', e=res)


# declare all our application specific routes

@app.route('/login')
def do_login(db):

	if 'authenticating' not in request.session:
		request.session['authenticating'] = True

		r = raven.Request(url=request.url, desc="RoomPicks")
		redirect(str(r))
	else:
		del request.session['authenticating']
		if "WLS-Response" not in request.query:
			raise HTTPError(400, "Authentication failed. Please try again")

		r = raven.Response(request.query["WLS-Response"])

		assert "WLS-Response" in request.url
		base_url = request.url[:request.url.rfind("WLS-Response")-1]

		if r.url != base_url:
			print r.url, base_url
			abort(400, "Login failed: it seems another site tried to log you in")

		issue_delta = (datetime.utcnow() - r.issue).total_seconds()
		if not -15 < issue_delta < 75:
			abort(403, "Login failed: you took too long to log in - please try again")

		if r.success:
			# a no-op here, but important if you set iact or aauth
			if not r.check_iact_aauth(None, None):
				abort(403, "Something went wrong when logging in: check_iact_aauth failed")

			request.session["user"] = r.principal
			print("Successfully logged in as {0}".format(r.principal))
			return redirect(request.query.return_to)
		else:
			abort(403, "Login failed: reason unknown")
			return redirect(request.query.return_to)

@app.route('/logout')
def do_logout(db):
	del request.session['user']
	redirect(request.query.return_to)


with base_route(app, '/rooms'):
	@app.route('')
	def show_rooms(db):
		filters = []
		roomsq = db.query(m.Room)

		if request.query.filter_id:
			try:
				ids = [int(i) for i in request.query.filter_id.split(',')]
			except TypeError:
				raise HTTPError(400, 'malformed room id')

			filters.append(m.Room.id.in_(ids))

		return template('rooms', roomsq=roomsq, ballot=get_ballot(db), filters=filters)

	@app.route('/<room_id>')
	def show_room(room_id, db):
		try:
			room = db.query(m.Room).filter(m.Room.id == room_id).one()
		except NoResultFound:
			raise HTTPError(404, "No matching room")

		return template('room', room=room, ballot=get_ballot(db), version=request.query.v)

	@app.route('/mine')
	@needs_auth('personalized')
	def show_current_room(db):
		room = request.user.current_room
		if room:
			return redirect('/rooms/{}'.format(room.id))
		else:
			return template('messages/no-room')

	@app.route('/random')
	def show_random_room(db):
		rooms = db.query(m.Room)
		redirect('/rooms/{}'.format(rooms[random.randrange(rooms.count())].id))


with base_route(app, '/places'):
	@app.route('', name="place-list")
	def show_places(db):
		from sqlalchemy.orm import joinedload_all

		# load the entire heirarchy in one query
		root = db.query(m.Cluster).options(
			joinedload_all('children.rooms').load_only('adjusted_rating'),
			joinedload_all('children.children.rooms').load_only('adjusted_rating'),
			joinedload_all('children.children.children.rooms').load_only('adjusted_rating'),
			joinedload_all('children.children.children.children.rooms').load_only('adjusted_rating')
		).filter(m.Cluster.parent == None).one()

		return template('places', location=root)

	@app.route('/<place_id>', name="place")
	def show_place(place_id, db):
		try:
			location = db.query(m.Cluster).filter(m.Cluster.id == place_id).one()
		except NoResultFound:
			raise HTTPError(404, "No matching location")

		return template('place', location=location, ballot=get_ballot(db), filters=[])

	@app.route('/<place_id>/photos', name="place-photos")
	def show_place_photos(place_id, db):
		try:
			location = db.query(m.Cluster).filter(m.Cluster.id == place_id).one()
		except NoResultFound:
			raise HTTPError(404, "No matching location")

		return template('place-photos', place=location, filters=[])

	@app.route('/random')
	def show_random_place(db):
		locations = db.query(m.Cluster).filter_by(type='building')
		redirect('/places/{}'.format(locations[random.randrange(locations.count())].id))

	@app.route('/random/photos')
	def show_random_place_photos(db):
		locations = db.query(m.Cluster).filter_by(type='building')
		redirect('/places/{}/photos'.format(locations[random.randrange(locations.count())].id))


with base_route(app, '/reviews'):
	@app.route('/new', name="new-review-choice")
	@needs_auth('ownership')
	def prompt_review_choice(db):
		occupancies = db.query(m.Occupancy).filter(m.Occupancy.resident == request.user).all()

		return template('new-review-choice', occupancies=occupancies)

	@app.route('/new/<occ_id>', name="new-review")
	@needs_auth('ownership')
	def show_new_review_form(occ_id, db):
		try:
			occupancy = db.query(m.Occupancy).filter(m.Occupancy.id == occ_id).one()
		except NoResultFound:
			raise HTTPError(404, "No such occupancy to review")

		if occupancy.resident != request.user:
			raise HTTPError(403, "You must have been a resident of a room to review it")

		review = db.query(m.Review).filter_by(occupancy_id=occ_id).order_by(m.Review.published_at.desc()).first()

		return template('new-review', occupancy=occupancy, review=review)


	@app.post('/new/<occ_id>', name="new-review")
	@needs_auth('ownership')
	def show_new_review_form(occ_id, db):
		try:
			occupancy = db.query(m.Occupancy).filter(m.Occupancy.id == occ_id).one()
		except NoResultFound:
			raise HTTPError(404, "No such occupancy to review")

		if occupancy.resident != request.user:
			raise HTTPError(403, "You must have been a resident of a room to review it")

		review = db.query(m.Review).filter_by(occupancy_id=occ_id).order_by(m.Review.published_at.desc()).first()
		
		# Rating was submitted initially - save that right now
		rating = request.forms.get('rating')
		if not review and rating:
			review = m.Review(
				occupancy=occupancy,
				published_at=datetime.now(),
				rating=rating
			)

		return template('new-review', occupancy=occupancy, review=review)

	@app.post('', name="new-review-post")
	@needs_auth('ownership')
	def save_new_review_form(db):
		occ_id = request.forms.occupancy_id

		if occ_id is None:
			raise HTTPError(400)

		try:
			occupancy = db.query(m.Occupancy).filter(m.Occupancy.id == occ_id).one()
		except NoResultFound:
			raise HTTPError(404, "No such occupancy to review")

		if occupancy.resident != request.user:
			raise HTTPError(403, "You must have been a resident of a room to review it")

		sections = []

		for key, value in request.forms.iteritems():
			print key, value
			match = re.match(r'^section-(\d+)$', key)
			if match:
				print "MATCH"
				heading_id = int(match.group(1))
				try:
					heading = db.query(m.ReviewHeading).filter_by(id=heading_id).one()
				except NoResultFound:
					raise HTTPError(400)

				if value.strip():
					sections += [
						m.ReviewSection(
							heading=heading,
							content=value
						)
					]
				elif heading.is_summary:
					raise HTTPError(400, "{!r} section cannot be left blank".format(heading.name))

		# validate the rating
		try:
			rating = int(request.forms.rating)
		except ValueError:
			raise HTTPError(404, "Rating must be an integer")
		if rating < 0 or rating > 10:
			raise HTTPError(404, "Rating must be between 0 and 10")

		last_review = db.query(m.Review).filter_by(occupancy_id=occ_id).order_by(m.Review.published_at.desc()).first()

		review = m.Review(
			sections=sections,
			occupancy=occupancy,
			published_at=datetime.now(),
			rating=rating
		)
		db.add(review)

		# check we haven't hit a double-post situation
		if last_review and review.contents_eq(last_review):
			raise HTTPError(400, "Same as last review")

			# TODO: fail gracefully
			db.rollback()
			flash_some_message()
			redirect_anyway()

		# look for references in the review
		import find_references
		for ref in find_references.scan_review(review):
			db.add(ref)

		redirect('/rooms/{}#review-{}'.format(occupancy.listing.room_id, review.id))


with base_route(app, '/photos'):
	@app.route('/<photo_id:int>', name='static', skip=[get_authed_user])
	def static_photo(photo_id, db):
		try:
			photo = db.query(m.Photo).filter(m.Photo.id == photo_id).one()
		except NoResultFound:
			raise HTTPError(404, 'Image not found')

		return static_file(photo.storage_path, root='/')

	@app.route('/panoramas')
	def show_panoramas(db):
		photos = db.query(m.Photo).filter(m.Photo.is_panorama).order_by(m.Photo.published_at.desc()).limit(20)

		return template('panoramas', photos=photos)


	@app.route('/new/<occ_id>', name="new-photos")
	@needs_auth('ownership')
	def show_new_photo_form(occ_id, db):
		try:
			occupancy = db.query(m.Occupancy).filter(m.Occupancy.id == occ_id).one()
		except NoResultFound:
			raise HTTPError(404, "No such occupancy to review")

		if occupancy.resident != request.user:
			raise HTTPError(403, "You must have been a resident of a room to review it")

		return template('new-photo', occupancy=occupancy)

	@app.post('', name="new-photo-post")
	@needs_auth('ownership')
	def save_new_photo_form(db):
		occ_id = request.forms.occupancy_id

		if occ_id is None:
			raise HTTPError(400)

		try:
			occupancy = db.query(m.Occupancy).filter(m.Occupancy.id == occ_id).one()
		except NoResultFound:
			raise HTTPError(404, "No such occupancy to review")

		if occupancy.resident != request.user:
			raise HTTPError(403, "You must have been a resident of a room to review it")

		uploads = request.files.getall('photo')
		captions = request.forms.getall('caption')

		for image_upload, caption in reversed(zip(uploads, captions)):
			photo = m.Photo.from_file(image_upload.file)
			photo.caption = caption
			photo.occupancy = occupancy

			db.add(photo)

		return redirect('/rooms/{}#photos'.format(occupancy.listing.room.id))

with base_route(app, '/occupancies'):
	@app.route('/revised')
	def show_occupancies(db):
		occupancies = db.query(m.Occupancy).join(m.Review).filter(~m.Review.is_newest)

		return '<br>'.join(
			'<a href="/occupancies/{0}">#{0} ({1})</a>'.format(o.id, len(o.reviews))
			for o in occupancies
		)

	@app.route('/<occ_id:int>')
	def show_occupancy(occ_id, db):
		try:
			occupancy = db.query(m.Occupancy).filter(m.Occupancy.id == occ_id).one()
		except NoResultFound:
			raise HTTPError(404, 'Occupancy not found')

		return template('occupancy', occupancy=occupancy)


with base_route(app, '/locations'):
	@app.route('/<loc_id>', name="location-list")
	def show_place(loc_id, db):
		try:
			location = db.query(m.Cluster).filter(m.Cluster.id == loc_id).one()
			return template('locations', location=location)
		except NoResultFound:
			raise HTTPError(404, "No matching location")


with base_route(app, '/users'):
	@app.route('')
	@needs_auth
	def show_users(db):
		from sqlalchemy.orm import joinedload

		users = db.query(m.Person).options(
			joinedload(m.Person.occupancies).load_only(),
			joinedload(m.Person.occupancies).subqueryload(m.Occupancy.reviews).load_only(m.Review.id),
			joinedload(m.Person.occupancies).subqueryload(m.Occupancy.photos).load_only(m.Photo.id)
		).order_by(m.Person.last_seen.desc(), m.Person.crsid)
		return template('users', users=users)

	@app.route('/update')
	@needs_auth('admin')
	def update_names(db):
		import utils

		names = {}
		initial_names = {}
		to_query = {}

		users = db.query(m.Person).all()

		data_lookup = utils.lookup_ldap(u.crsid for u in users)

		for u in users:
			d = data_lookup.get(u.crsid)
			if d:
				if d[u'visibleName'] != u.name:
					# name has changed
					names[u] = d[u'visibleName']
					initial_names[u] = d.get(u'registeredName')
			else:
				# crsid doesn't exist!
				names[u] = None

		users = set(names.keys())

		# crsids didn't match
		users_unknown = {u for u in users if names[u] is None}
		users -= users_unknown
		users_unknown

		# names has gone back to initials
		users_reverted = {u for u in users if names[u] == initial_names[u]}
		users -= users_reverted

		return template('users-update',
			users_unknown=users_unknown,
			users=users,
			users_reverted=users_reverted,
			names=names)

	@app.post('/update')
	@needs_auth('admin')
	def do_update(db):
		for k, v in request.forms.items():
			if k.endswith('-name'):
				user = db.query(m.Person).filter(m.Person.crsid == k[:-5]).one()
				user.name = v.decode('utf8')
				db.add(user)

		db.commit()

		return update_names(db)

	@app.route('/<crsid>')
	@needs_auth
	def show_user(crsid, db):
		from sqlalchemy.orm import joinedload

		try:
			user = db.query(m.Person).options(
				joinedload(m.Person.occupancies).load_only(),
				joinedload(m.Person.occupancies).subqueryload(m.Occupancy.reviews).load_only(m.Review.id),
				joinedload(m.Person.occupancies).subqueryload(m.Occupancy.photos).load_only(m.Photo.id)
			).filter(m.Person.crsid == crsid).one()
		except NoResultFound:
			raise HTTPError(404, "No such user")

		return template('user', user=user)

	@app.route('/random')
	@needs_auth
	def show_random_room(db):
		users = db.query(m.Person)
		redirect('/users/{}'.format(users[random.randrange(users.count())].crsid))


with base_route(app, '/ballots'):
	@app.route('')
	@needs_auth
	def show_ballots(db):
		from sqlalchemy.orm import joinedload, subqueryload

		ballots = db.query(m.BallotSeason).options(
			joinedload(m.BallotSeason.events),
			joinedload(m.BallotSeason.room_listings).subqueryload(m.RoomListing.audience_types),
		).order_by(m.BallotSeason.year.desc())
		return template('ballots', ballots=ballots)

	@app.route('/<ballot_id>')
	@needs_auth
	def show_ballot(ballot_id, db):
		from sqlalchemy.orm import joinedload

		ballot = db.query(m.BallotSeason).options(
			joinedload(m.BallotSeason.events),
			joinedload(m.BallotSeason.room_listings).subqueryload(m.RoomListing.audience_types),
		).filter(m.BallotSeason.year == ballot_id).one()
		return template('ballot', ballot_season=ballot, db=db)

	@app.route('/<ballot_id>/edit')
	@needs_auth('admin')
	def show_ballot(ballot_id, db):
		from sqlalchemy.orm import joinedload

		ballot = db.query(m.BallotSeason).options(
			joinedload(m.BallotSeason.events),
			joinedload(m.BallotSeason.room_listings).subqueryload(m.RoomListing.audience_types),
		).filter(m.BallotSeason.year == ballot_id).one()
		return template('ballot-edit', ballot_season=ballot, db=db)

	@app.route('/<ballot_id>/add-event')
	@needs_auth('admin')
	def show_ballot(ballot_id, db):
		from sqlalchemy.orm import joinedload

		ballot = db.query(m.BallotSeason).options(
			joinedload(m.BallotSeason.events)
		).filter(m.BallotSeason.year == ballot_id).one()

		event_types = (db
			.query(m.BallotType, m.BallotType.events.any(m.BallotEvent.season == ballot))
			.outerjoin(m.BallotType.events)
		)

		return template('ballot-add-event', ballot_season=ballot, event_types=event_types)

	@app.post('/<ballot_id>/add-event')
	@needs_auth('admin')
	def show_ballot(ballot_id, db):
		from sqlalchemy.orm import joinedload
		from datetime import datetime

		print int(request.forms.type)

		ballot = db.query(m.BallotSeason).filter(m.BallotSeason.year == ballot_id).one()
		event_type = db.query(m.BallotType).filter(m.BallotType.id == int(request.forms.type)).one()

		e = m.BallotEvent(
			season=ballot,
			type=event_type,
			opens_at=datetime.strptime(request.forms.opens_at, "%Y-%m-%d"),
			closes_at=datetime.strptime(request.forms.closes_at, "%Y-%m-%d")
		)

		db.add(e)
		return redirect(request.url)


	@app.route('/<ballot_id:int>/<ballot_type_name>/edit')
	@needs_auth('admin')
	def edit_ballot_rooms(ballot_id, ballot_type_name, db):
		if ballot_type_name.lower() != ballot_type_name:
			raise redirect(request.url.replace(ballot_type_name, ballot_type_name.lower()))

		from sqlalchemy import func
		from sqlalchemy.orm import joinedload, joinedload_all

		ballot_type = db.query(m.BallotType).filter(func.lower(m.BallotType.name) == ballot_type_name.lower()).one()

		ballot_eventsq = (db
			.query(m.BallotEvent)
			.join(m.BallotSeason)
			.filter(m.BallotEvent.type == ballot_type)
			.filter(m.BallotSeason.year <= ballot_id)
			.order_by(m.BallotSeason.year.desc())
			.limit(2)
		)
		ballot_events = ballot_eventsq.all()

		if ballot_events[0].season.year != ballot_id:
			raise HTTPError(404, "No {} ballot for the {} season {} {}".format(ballot_type.name, ballot_id, ballot_eventsq, ballot_events))
		else:
			ballot = ballot_events[0]

		if len(ballot_events) == 2:
			last_ballot = ballot_events[1]
		else:
			last_ballot = None

		root = db.query(m.Cluster).options(
			joinedload_all('children.rooms.listing_for'),
			joinedload_all('children.children.rooms.listing_for'),
			joinedload_all('children.children.children.rooms.listing_for'),
			joinedload_all('children.children.children.children.rooms.listing_for'),
		).filter(m.Cluster.parent == None).one()

		return template('ballot-event-edit-rooms',
			ballot_event=ballot,
			last_ballot_event=last_ballot,
			root=root)


	@app.post('/<ballot_id:int>/<ballot_type_name>/edit')
	@needs_auth('admin')
	def save_ballot_rooms(ballot_id, ballot_type_name, db):
		from sqlalchemy import func

		ballot_type = db.query(m.BallotType).filter(func.lower(m.BallotType.name) == ballot_type_name.lower()).one()
		ballot_season = db.query(m.BallotSeason).filter(m.BallotSeason.year == ballot_id).one()

		room_ids = set()
		for name, value in request.forms.items():
			match = re.match(r'rooms\[(\d+)\]', name)
			if match and value == 'on':
				room_ids.add(int(match.group(1)))

		for l in ballot_season.room_listings:
			if l.room_id in room_ids:
				l.audience_types |= {ballot_type}
			else:
				l.audience_types -= {ballot_type}

		return redirect(request.url)

	@app.route('/<ballot_id:int>/<ballot_type_name>/edit-slots', method=('GET', 'POST'))
	@needs_auth('admin')
	def edit_ballot_slots(ballot_id, ballot_type_name, db):
		if ballot_type_name.lower() != ballot_type_name:
			raise redirect(request.url.replace(ballot_type_name, ballot_type_name.lower()))

		from sqlalchemy import func

		ballot_type = db.query(m.BallotType).filter(func.lower(m.BallotType.name) == ballot_type_name.lower()).one()

		ballot_event = (db
			.query(m.BallotEvent)
			.join(m.BallotSeason)
			.filter(m.BallotEvent.type == ballot_type)
			.filter(m.BallotSeason.year == ballot_id)
		).one()

		def parse_csv(r):
			from datetime import datetime, timedelta
			import utils

			errors = []
			data = []

			headers = next(r)

			if headers != ["date", "time", "crsid", "name (ignored)"]:
				errors += ['bad-header']
				return None, errors

			last_date = None
			last_time = None
			for l in r:
				if len(l) < 3:
					errors += [('bad row {}'.format(l))]
					continue

				date, time, crsid = l[:3]

				if date:
					try:
						date = datetime.strptime(date, "%Y-%m-%d@")
					except ValueError:
						errors += [('bad-date', date)]
						continue
					last_date = date

				elif last_date:
					date = last_date
				else:
					errors += [('no-date')]
					continue


				if time:
					try:
						time = datetime.strptime(time, "%H:%M:%S")
					except ValueError:
						errors += [('bad-time', time)]
						continue
					last_time = time
				elif last_time:
					time = last_time + timedelta(minutes=3)
					last_time = time
				else:
					errors += [('no-time')]
					continue

				ts = datetime.combine(date.date(), time.time())

				data += [(ts, crsid.rstrip('@'))]


			# get all crsids
			crsids = [crsid for ts, crsid in data]

			# find existing users attached to them
			db_users = [db.query(m.Person).get(c) for c in crsids]
			users = {u.crsid: u for u in db_users if u}

			new_users = set(crsids) - set(users.keys())

			# lookup the rest
			lookup = utils.lookup_ldap(new_users)

			for crsid in new_users:
				d = lookup.get(crsid)
				if d:
					name = d.get('visibleName')
					users[crsid] = m.Person(crsid=crsid, name=name)
				else:
					errors += [('bad-crsid', crsid)]

			data = {
				users[crsid]: ts
				for ts, crsid in data
				if crsid in users
			}

			return data, errors


		if request.method == "POST" and request.files.slot_csv:
			import csv
			r = csv.reader(iter(request.files.slot_csv.file))
			step2 = parse_csv(r)
		else:
			step2 = None


		return template('ballot-event-edit-slots',
			ballot_event=ballot_event,
			step2=step2
		)

	@app.route('/<ballot_id:int>/<ballot_type_name>/slots.csv')
	@needs_auth('admin')
	def csv_ballot_slots(ballot_id, ballot_type_name, db):
		if ballot_type_name.lower() != ballot_type_name:
			raise redirect(request.url.replace(ballot_type_name, ballot_type_name.lower()))

		from sqlalchemy import func

		ballot_type = db.query(m.BallotType).filter(func.lower(m.BallotType.name) == ballot_type_name.lower()).one()

		ballot_event = (db
			.query(m.BallotEvent)
			.join(m.BallotSeason)
			.filter(m.BallotEvent.type == ballot_type)
			.filter(m.BallotSeason.year == ballot_id)
		).one()


		import csv
		import StringIO
		sfile = StringIO.StringIO()
		o = csv.writer(sfile)

		o.writerow(["date", "time", "crsid", "name (ignored)"])
		last_date = None
		for s in sorted(ballot_event.slots, key=lambda s: s.time):
			if s.time.date() != last_date:
				o.writerow([str(s.time.date()) + "@", s.time.time(), s.person.crsid + "@", s.person.name])
				last_date = s.time.date()
			else:
				o.writerow(["", s.time.time(), s.person.crsid + "@", s.person.name])

		if not ballot_event.slots:
			n = datetime.now().replace(second=0, microsecond=0)
			o.writerow([str(n.date()) + "@", n.time(), "crsid123@", 'example student (delete!)'])

		response.content_type = 'text/csv'
		return sfile.getvalue()


with base_route(app, '/tools'):
	@app.route('/assign-room')
	@app.post('/assign-room')
	@needs_auth('admin')
	def assign_room(db):
		user = False
		room = False
		season = False

		if request.query.user:
			user = db.query(m.Person).get(request.query.user)

		if request.query.room:
			room = db.query(m.Room).get(request.query.room)

		if request.query.year:
			season = db.query(m.BallotSeason).get(request.query.year)

		# incomplete form - get
		if request.method == 'GET':
			return template('tools-assign', user=user, room=room, season=season, seasons=db.query(m.BallotSeason).all())

		# form must be complete for post
		elif not all([season, room, user]):
			raise HTTPError(400)

		else:
			from sqlalchemy.orm.session import make_transient
			from datetime import datetime

			listing = room.listing_for.get(season)
			if not listing:
				last_listing = max(room.listings, key=lambda l: l.ballot_season_id)

				# detach it
				db.expunge(last_listing)
				make_transient(last_listing)
				listing = last_listing

				listing.ballot_season = season
				listing.id = None

			occs = listing.occupancies
			assert not any(occ.resident == user for occ in occs)

			new_occ = m.Occupancy(resident=user, listing=listing, chosen_at=datetime.now())
			db.add(new_occ)

			redirect('/rooms/{}'.format(room.id))


@app.route('/sitemap.xml')
def sitemap(db):
	response.content_type = 'application/xml'
	return template('sitemap', db=db)



# and now, setup the session middleware

@app.hook('before_request')
def setup_request():
	request.session = request.environ['beaker.session']

app = SessionMiddleware(app, {
	'session.type': 'file',
	'session.data_dir': './session/',
	'session.auto': True
})


if __name__ == '__main__':
	import socket
	if socket.gethostname() == 'pip':
		bottle.run(app=app, host='efw27.user.srcf.net', port=8098, server='cherrypy')
	else:
		bottle.run(app=app, host='localhost', port=8080, debug=True, reloader=True)
else:
	bottle.debug(True)


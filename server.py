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

# our includes
import database.orm as m
import database.db
from utils import needs_auth
import utils

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
SimpleTemplate.defaults["url_for"] = utils.url_for

# install the sqlalchemy plugin, which injects a `db` argument into every route
app.install(SQLAlchemyPlugin(
	engine=database.db.engine,
	metadata=m.Base.metadata,
	keyword='db',
	use_kwargs=True
))

hide_from_public = needs_auth('publicity') # lambda f: f

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
		if not request.query.do_log:
			return callback(*args, **kwargs)

		import os

		fname = 'logs/{}.html'.format(request.path
			.replace('/', '.')
			.replace('<', '')
			.replace('>', '')
			.lstrip('.')
		)
		try:
			os.remove(fname)
		except:
			pass

		import sqltap

		profiler = sqltap.start()

		try:
			return callback(*args, **kwargs)
		finally:
			try:
				statistics = profiler.collect()
				profiler.stop()
				sqltap.report(statistics, fname)
			except Exception:
				raise

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
	from sqlalchemy import func
	if request.query.ballot:
		if '-' in request.query.ballot:
			parts = request.query.ballot.split('-', 1)
			byear = parts[0]
			btype = parts[1].lower()
		else:
			byear = request.query.ballot
			btype = None

		try:
			byear = int(byear)
		except ValueError:
			raise HTTPError(400, "Invalid ballot year {!r}".format(request.query.ballot))

		if btype:
			try:
				return (db.query(m.BallotEvent)
					.join(m.BallotType).filter(func.lower(m.BallotType.name) == btype.lower())
					.join(m.BallotSeason).filter(m.BallotSeason.year == byear)
					.one()
				)
			except NoResultFound:
				raise HTTPError(404, "Could not find a {!r} ballot for the year {}".format(btype, byear))
		else:
			try:
				return db.query(m.BallotSeason).filter(m.BallotSeason.year == byear).one()
			except NoResultFound:
				raise HTTPError(404, "Could not find a ballot for the year {}".format(byear))

	elif request.user:
		active_events = request.user.active_ballot_events
		active_slots = [s for s in active_events.values() if s]

		if any(active_slots):
			return active_slots[0].event

	res = get_last_ballot(db)
	if res:
		return res
	else:
		raise HTTPError(500, "Could not get current ballot")


# declare basic routes - index, static files, and error page
@app.route('/static/<path:path>', name='static', skip=[get_authed_user])
def static(path):
	return static_file(path, root='static')

@app.route('/logs/<path:path>', name='logs')
@needs_auth('admin')
def static_logs(db, path):
	return static_file(path, root='logs')

@app.route('/')
def show_index(db):
	from sqlalchemy.orm import joinedload
	# load all the group names
	places = db.query(m.Place).options(
		joinedload(m.Place.children)
	).all()
	return template('index', db=db)

@app.error(404)
@app.error(403)
@app.error(400)
@get_authed_user
def error_handler(res):
	return template('messages/error', e=res)


# declare all our application specific routes
try:
	import raven
except ImportError:
	print "Warning: raven not found, using development login page"
	@app.route('/login')
	def do_login(db):
		if request.query.crsid:
			request.session["user"] = request.query.crsid
			utils.update_csrf_token()

			return redirect(request.query.return_to)
		else:
			return '<form method="GET" action="{}">{}{}</form>'.format(
				request.url,
				'<input name="crsid" placeholder="crsid" />',
				'<input type="submit" />'
			)

else:
	@app.route('/login')
	def do_login(db):
		# already logged in - return to the home page
		if request.user:
			return redirect(request.query.return_to)

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

			if not r.success:
				abort(403, "Login failed: reason unknown")
				return redirect(request.query.return_to)

			# a no-op here, but important if you set iact or aauth
			if not r.check_iact_aauth(None, None):
				abort(403, "Something went wrong when logging in: check_iact_aauth failed")

			request.session["user"] = r.principal
			utils.update_csrf_token()

			print "Successfully logged in as {0}".format(r.principal)
			return redirect(request.query.return_to)


@app.route('/login-as')
@needs_auth('admin')
def login_as(db):
	if request.user.is_admin:
		request.session["last_user"] = request.session["user"]
		request.session["user"] = request.params.user
	redirect('/')

@app.route('/logout')
def do_logout(db):
	if "last_user" in request.session:
		request.session["user"] = request.session["last_user"]
		del request.session["last_user"]
	else:
		del request.session['user']
	redirect(request.query.return_to)


@app.route('/help')
def show_help(db):
	return template('help')


with base_route(app, '/rooms'):
	@app.route('')
	@hide_from_public
	def show_rooms(db):
		from sqlalchemy.orm import joinedload, subqueryload

		ballot = get_ballot(db)

		opts = (
			joinedload(m.Room.listing_for)
				.joinedload(m.RoomListing.occupancies)
				.load_only(m.Occupancy.resident_id),
			joinedload(m.Room.listing_for)
				.subqueryload(m.RoomListing.audience_types),
			subqueryload(m.Room.stats)
		)
		if not isinstance(ballot, m.BallotEvent):
			opts = opts + (
				joinedload(m.Room.listing_for)
					.undefer(m.RoomListing.bad_listing)
			,)

		roomsq = db.query(m.Room).options(*opts)
		filters = []

		# load all the group names
		places = db.query(m.Place).options(
			joinedload(m.Place.children)
		).all()

		if request.query.filter_id:
			try:
				ids = [int(i) for i in request.query.filter_id.split(',')]
			except TypeError:
				raise HTTPError(400, 'malformed room id')

			filters.append(m.Room.id.in_(ids))

		return template('rooms', roomsq=roomsq, ballot=get_ballot(db), filters=filters)

	@app.route('/<room_id>')
	@hide_from_public
	def show_room(room_id, db):
		from sqlalchemy.orm.strategy_options import Load

		opts = (
			Load(m.Room)
				.subqueryload(m.Room.listings)
				.joinedload(m.RoomListing.occupancies),

			Load(m.Occupancy)
				.joinedload(m.Occupancy.review)
				.subqueryload(m.Review.sections)
				.joinedload(m.ReviewSection.refers_to),

			Load(m.Occupancy)
				.joinedload(m.Occupancy.photos)
		)
		try:
			room = (db
				.query(m.Room)
				.options(*opts)
				.outerjoin(m.Room.listings)
				.outerjoin(m.Occupancy)
				.filter(m.Room.id == room_id)
			).one()
		except NoResultFound:
			raise HTTPError(404, "No matching room")

		return template('room', room=room, ballot=get_ballot(db), version=request.query.v)

	@app.post('/<room_id>/book')
	@needs_auth('personalized')
	def book_room(room_id, db):
		from sqlalchemy.sql import exists

		token = request.forms.crsf_token
		if not token or token != request.session.get('crsf_token'):
			raise HTTPError(403, "Bad CSRF token")

		try:
			room = db.query(m.Room).filter(m.Room.id == room_id).one()
		except NoResultFound:
			raise HTTPError(404, "No matching room")

		ballot_event = get_ballot(db)

		import roombooking
		try:
			roombooking.check_then_book(db, request.user, room, ballot_event)
		except roombooking.BookingError:
			pass

		# whatever happens, we redirect back to the room page, which
		# reevaluates the check and gives the error message to the user about
		# what went wrong
		return redirect(utils.url_for(room))


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
		from sqlalchemy.orm import joinedload

		# this line preloads all the places into the cache
		places = db.query(m.Place).options(
			joinedload(m.Place.children),
			joinedload(m.Place.rooms)
				.load_only(m.Room.id)
				.subqueryload(m.Room.stats)
				.load_only(m.RoomStats.adjusted_rating),

			joinedload(m.Place.rooms)
				.subqueryload(m.Room.listing_for)
				.joinedload(m.RoomListing.occupancies)
				.load_only(m.Occupancy.cancelled),

			joinedload(m.Place.rooms)
				.subqueryload(m.Room.listing_for)
				.subqueryload(m.RoomListing.audience_types)
		).all()

		# which this line then accesses
		root = db.query(m.Place).get(1)

		return template('places', location=root, ballot=get_ballot(db))

	@app.route('/<place_id>', name="place")
	@hide_from_public
	def show_place(place_id, db):
		try:
			location = db.query(m.Place).filter(m.Place.id == place_id).one()
		except NoResultFound:
			raise HTTPError(404, "No matching location")

		return template('place', location=location, ballot=get_ballot(db), filters=[])

	@app.route('/<place_id>/edit', name="place-edit")
	@needs_auth('admin')
	def show_place_edit(place_id, db):
		try:
			location = db.query(m.Place).filter(m.Place.id == place_id).one()
		except NoResultFound:
			raise HTTPError(404, "No matching location")

		return template('edit-place-summary', place=location)

	@app.route('/<place_id>/revisions', name="place-revisions")
	@hide_from_public
	def show_place_edit(place_id, db):
		try:
			location = db.query(m.Place).filter(m.Place.id == place_id).one()
		except NoResultFound:
			raise HTTPError(404, "No matching location")

		return template('place-history', place=location)



	@app.post('/<place_id>', name="place")
	@needs_auth('admin')
	def save_place_edit(place_id, db):
		try:
			place = db.query(m.Place).filter(m.Place.id == place_id).one()
		except NoResultFound:
			raise HTTPError(404, "No matching location")


		last_summary = place.summary
		summary = m.PlaceSummary(
			place=place,
			published_at=datetime.now(),
			markdown_content=request.forms.content,
			editor=request.user
		)

		if last_summary and summary.markdown_content == last_summary.markdown_content:
			raise HTTPError(400, "Same as last edit")

		db.add(summary)

		redirect(utils.url_for(place))

	@app.route('/<place_id>/photos', name="place-photos")
	@hide_from_public
	def show_place_photos(place_id, db):
		try:
			location = db.query(m.Place).filter(m.Place.id == place_id).one()
		except NoResultFound:
			raise HTTPError(404, "No matching location")

		return template('place-photos', place=location, filters=[])

	@app.route('/random')
	def show_random_place(db):
		locations = db.query(m.Place).filter_by(type='building')
		redirect('/places/{}'.format(locations[random.randrange(locations.count())].id))

	@app.route('/random/photos')
	def show_random_place_photos(db):
		locations = db.query(m.Place).filter_by(type='building')
		redirect('/places/{}/photos'.format(locations[random.randrange(locations.count())].id))


with base_route(app, '/reviews'):
	@app.route('/new', name="new-review-choice")
	@needs_auth('ownership')
	def prompt_review_choice(db):
		occupancies = db.query(m.Occupancy).filter(m.Occupancy.resident == request.user).all()

		return template('new-review-choice', occupancies=occupancies)

	def get_occupancy_to_review(db, occ_id):
		try:
			occupancy = db.query(m.Occupancy).filter(m.Occupancy.id == occ_id).one()
		except NoResultFound:
			raise HTTPError(404, "No such occupancy to review")


		is_own_review = occupancy.resident == request.user
		if not is_own_review and not request.user.is_admin:
			raise HTTPError(403, "You must have been a resident of a room to review it")

		return occupancy

	@app.route('/new/<occ_id>', name="new-review")
	@needs_auth('ownership')
	def show_new_review_form(occ_id, db):
		occupancy = get_occupancy_to_review(db, occ_id)
		if request.query.revision:
			review = next(r for r in occupancy.reviews if r.id == int(request.query.revision))
			if not review:
				raise HTTPError(400, "Revision refers to a different room!")
		else:
			review = occupancy.review
		return template('new-review', occupancy=occupancy, review=review)


	@app.post('/new/<occ_id>', name="new-review")
	@needs_auth('ownership')
	def handle_new_review_form(occ_id, db):
		occupancy = get_occupancy_to_review(db, occ_id)
		review = occupancy.review

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
		occupancy = get_occupancy_to_review(db, occ_id)

		last_review = occupancy.review

		if 'delete' in request.forms:
			review = m.Review(
				occupancy=occupancy,
				published_at=datetime.now(),
				hidden=True
			)
		else:
			sections = []

			for key, value in request.forms.iteritems():
				match = re.match(r'^section-(\d+)$', key)
				if match:
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


			review = m.Review(
				sections=sections,
				occupancy=occupancy,
				published_at=datetime.now(),
				rating=rating
			)

		# if an edit occurred, record the editor
		if occupancy.resident != request.user:
			review.editor = request.user

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
	@hide_from_public
	def show_panoramas(db):
		photos = db.query(m.Photo).filter(m.Photo.is_panorama).order_by(m.Photo.published_at.desc()).limit(20)

		return template('panoramas', photos=photos)

	@app.route('')
	@hide_from_public
	def show_photos(db):
		return template('recent-photos', photos=db
			.query(m.Photo)
			.order_by(m.Photo.published_at.desc())
		)


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
	@needs_auth('privacy')
	def show_occupancy(occ_id, db):
		try:
			occupancy = db.query(m.Occupancy).filter(m.Occupancy.id == occ_id).one()
		except NoResultFound:
			raise HTTPError(404, 'Occupancy not found')

		return template('occupancy', occupancy=occupancy)


with base_route(app, '/locations'):
	@app.route('/<loc_id>', name="location-list")
	def show_location_heirarchy(loc_id, db):
		try:
			location = db.query(m.Place).filter(m.Place.id == loc_id).one()
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
		).order_by(m.Person.last_seen.desc().nullslast(), m.Person.crsid)
		return template('users', users=users)

	@app.route('/update')
	@needs_auth('admin')
	def update_names(db):
		import utils

		names = {}
		initial_names = {}

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
	def show_random_user(db):
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

	@app.route('/explanation')
	def show_explanation(db):
		return template('ballots-explanation')

	@app.route('/<ballot_id:int>', name="show-ballot")
	@needs_auth
	def show_ballot(ballot_id, db):
		from sqlalchemy.orm import joinedload

		ballot = db.query(m.BallotSeason).options(
			joinedload(m.BallotSeason.events),
			joinedload(m.BallotSeason.room_listings).subqueryload(m.RoomListing.audience_types),
		).filter(m.BallotSeason.year == ballot_id).one()
		return template('ballot', ballot_season=ballot, db=db)

	import ballotadmin
	ballotadmin.add_routes(app)

	@app.route('/<ballot_id:int>/<ballot_type_name>', name="ballot-event")
	@needs_auth('admin')
	def show_ballot_event(ballot_id, ballot_type_name, db):
		from sqlalchemy import func
		from sqlalchemy.orm.strategy_options import Load
		if ballot_type_name.lower() != ballot_type_name:
			raise redirect(app.get_url(
				'ballot-event',
				ballot_id=ballot_id, ballot_type_name=ballot_type_name.lower()
			))

		ballot_type = db.query(m.BallotType).filter(func.lower(m.BallotType.name) == ballot_type_name.lower()).one()

		listing_load = (
			Load(m.BallotEvent)
				.joinedload(m.BallotEvent.season)
				.joinedload(m.BallotSeason.room_listings)
		)

		ballot_event = (db
			.query(m.BallotEvent)
			.join(m.BallotSeason)
			.filter(m.BallotEvent.type == ballot_type)
			.filter(m.BallotSeason.year == ballot_id)
			.options(
				listing_load
					.joinedload(m.RoomListing.audience_types),
				listing_load
					.subqueryload(m.RoomListing.room),
				# 	.joinedload(m.Room.parent),
				# listing_load
				# 	.subqueryload(m.RoomListing.occupancies),
				Load(m.BallotEvent)
					.subqueryload(m.BallotEvent.slots)
					.joinedload(m.BallotSlot.person)
					.subqueryload(m.Person.occupancies)
			)
		).one()
		return template('ballot-event', event=ballot_event)



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
			if not user:
				d = utils.lookup_ldap([request.query.user])
				print d
				d = d.get(request.query.user)
				if d:
					name = d.get('visibleName')
					user = m.Person(crsid=request.query.user, name=name)

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
			cancel_src = request.forms.cancel_src == "1"
			cancel_dest = request.forms.cancel_dest == "1"

			from sqlalchemy.orm.session import make_transient
			from datetime import datetime

			import roombooking

			# better lock the table now, just to be sure
			roombooking.lock_occupancies(db)

			listing = room.listing_for.get(season)
			if not listing:
				listing = m.RoomListing(
					room=room,
					ballot_season=season
				)

			occs = listing.occupancies
			assert not any(occ.resident == user for occ in occs)

			if cancel_src:
				for occ in user.occupancies:
					if occ.listing.ballot_season == season:
						occ.cancelled = True

			if cancel_dest:
				for occ in listing.occupancies:
					occ.cancelled = True

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
		bottle.run(app=app, host='efw27.user.srcf.net', port=8898, server='cherrypy')
	else:
		bottle.run(app=app, host='localhost', port=8080, debug=True, reloader=True)
else:
	bottle.debug(True)


# system includes
import random
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
	engine=sqlalchemy.create_engine('sqlite:///database/test.db'),
	metadata=m.Base.metadata,
	keyword='db'
))


@app.install
def get_authed_user(callback):
	""" A plugin to put the loggedin-user db object at `request.user` """
	def wrapper(*args, **kwargs):
		db = kwargs.get('db')
		if db and 'user' in request.session:
			request.user = db.query(m.Person).filter_by(crsid=request.session['user']).one()
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
	return template('error', e=res)


# declare all our application specific routes

@app.route('/login')
def do_login(db):

	if 'authenticating' not in request.session:
		request.session['authenticating'] = True

		r = raven.Request(url=request.url, desc="RoomPicks")
		redirect(str(r))
	else:
		del request.session['authenticating']

		r = raven.Response(request.query["WLS-Response"])

		base_url = request.url[:request.url.rfind("WLS-Response")-1]

		if r.url != base_url:
			print r.url, base_url
			print("Bad url")
			abort(400)

		issue_delta = (datetime.utcnow() - r.issue).total_seconds()
		if not -15 < issue_delta < 75:
			print("Bad issue", issue_delta)
			abort(403)

		if r.success:
			# a no-op here, but important if you set iact or aauth
			if not r.check_iact_aauth(None, None):
				print("check_iact_aauth failed")
				abort(403)

			request.session["user"] = r.principal
			print("Successfully logged in as {0}".format(r.principal))
			return redirect(request.query.return_to)
		else:
			print("Raven authentication failed")
			return redirect(request.query.return_to)

@app.route('/logout')
def do_logout(db):
	del request.session['user']
	redirect(request.query.return_to)


with base_route(app, '/rooms'):
	@app.route('')
	def show_rooms(db):
		filters = []
		if request.query.vacant:
			filters.append(filter_vacant())
		if request.query.place:
			filters.append(filter_place(request.query.place))
		if request.query.group:
			filters.append(filter_group(request.query.group))

		return template('rooms', rooms=db.query(m.Room).all(), filters=filters)

	@app.route('/<room_id>')
	def show_room(room_id, db):
		try:
			room = db.query(m.Room).filter(m.Room.id == room_id).one()
			return template('room', room=room, version=request.query.v)
		except NoResultFound:
			raise HTTPError(404, "No matching room")

	@app.route('/random')
	def show_random_room(db):
		rooms = db.query(m.Room)
		redirect('/rooms/{}'.format(rooms[random.randrange(rooms.count())].id))


with base_route(app, '/places'):
	@app.route('', name="place-list")
	def show_places(db):
		root = db.query(m.Cluster).filter(m.Cluster.parent == None).one()
		return template('locations', location=root)

	@app.route('/<place_id>', name="place")
	def show_place(place_id, db):
		try:
			location = db.query(m.Cluster).filter(m.Cluster.id == place_id).one()
			return template('place', location=location, filters=[])
		except NoResultFound:
			raise HTTPError(404, "No matching location")

	@app.route('/<place_id>/photos', name="place-photos")
	def show_place_photos(place_id, db):
		try:
			location = db.query(m.Cluster).filter(m.Cluster.id == place_id).one()
			return template('place-photos', place=location, filters=[])
		except NoResultFound:
			raise HTTPError(404, "No matching location")

	@app.route('/random')
	def show_random_place(db):
		locations = db.query(m.Cluster).filter_by(type='building')
		redirect('/places/{}'.format(locations[random.randrange(locations.count())].id))

	@app.route('/random/photos')
	def show_random_place_photos(db):
		locations = db.query(m.Cluster).filter_by(type='building')
		redirect('/places/{}/photos'.format(locations[random.randrange(locations.count())].id))


with base_route(app, '/reviews'):
	@app.route('/new', name="new-review")
	def show_new_review_form(db):
		occupancy = db.query(m.Occupancy).filter(m.Occupancy.resident_id == 'efw27').one()
		return template('new-review', occupancy=occupancy)


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
	def show_users(db):
		from sqlalchemy.orm import joinedload, subqueryload

		users = db.query(m.Person).options(
			joinedload(m.Person.occupancies).load_only(),
			joinedload(m.Person.occupancies).subqueryload(m.Occupancy.reviews).load_only(m.Review.id),
			joinedload(m.Person.occupancies).subqueryload(m.Occupancy.photos).load_only(m.Photo.id)
		).order_by(m.Person.crsid)
		return template('users', users=users)

	@app.route('/<crsid>')
	def show_user(crsid, db):
		from sqlalchemy.orm import joinedload, subqueryload

		try:
			user = db.query(m.Person).options(
				joinedload(m.Person.occupancies).load_only(),
				joinedload(m.Person.occupancies).subqueryload(m.Occupancy.reviews).load_only(m.Review.id),
				joinedload(m.Person.occupancies).subqueryload(m.Occupancy.photos).load_only(m.Photo.id)
			).filter(m.Person.crsid == crsid).one()
			return template('user', user=user)
		except NoResultFound:
			raise HTTPError(404, "No such user")


with base_route(app, '/ballots'):
	@app.route('')
	def show_ballots(db):
		from sqlalchemy.orm import joinedload, subqueryload

		ballots = db.query(m.BallotSeason).options(
			joinedload(m.BallotSeason.events),
			joinedload(m.BallotSeason.room_listings).subqueryload(m.RoomListing.audience_types),
		).order_by(m.BallotSeason.year.desc())
		return template('ballots', ballots=ballots)

	@app.route('/<ballot_id>')
	def show_ballot(ballot_id, db):
		from sqlalchemy.orm import joinedload, subqueryload

		ballot = db.query(m.BallotSeason).options(
			joinedload(m.BallotSeason.events),
			joinedload(m.BallotSeason.room_listings).subqueryload(m.RoomListing.audience_types),
		).filter(m.BallotSeason.year == ballot_id).one()
		return template('ballot', ballot_season=ballot, db=db)

	@app.route('/<ballot_id>/edit')
	def show_ballot(ballot_id, db):
		from sqlalchemy.orm import joinedload, subqueryload

		ballot = db.query(m.BallotSeason).options(
			joinedload(m.BallotSeason.events),
			joinedload(m.BallotSeason.room_listings).subqueryload(m.RoomListing.audience_types),
		).filter(m.BallotSeason.year == ballot_id).one()
		return template('ballot-edit', ballot_season=ballot, db=db)


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
		bottle.run(app=app, host='localhost', port=8080, debug=True)
else:
	bottle.debug(True)


import random

import sqlalchemy
from sqlalchemy.orm.exc import NoResultFound, MultipleResultsFound
from bottle import *
from bottle.ext.sqlalchemy import SQLAlchemyPlugin

from data import rooms, places, rooms_by_id, apply_reserved_rooms
import database.orm as m


def filter_graduate():
	def filt(r):
		return not r['place'].get('unlisted')
	filt.description = "Not showing graduate rooms"
	return filt

def filter_vacant():
	def filt(r):
		return r['owner'] is None
	filt.description = "Not showing reserved rooms"
	return filt

def filter_place(p):
	def filt(r):
		return r['place']['name'] == p
	filt.description = "Only rooms in {}".format(p)
	return filt

def filter_group(g):
	def filt(r):
		return r['place']['group'] == g
	filt.description = "Only buildings on {}".format(g)
	return filt

app = Bottle()
SimpleTemplate.defaults["get_url"] = app.get_url

app.install(SQLAlchemyPlugin(
	engine=sqlalchemy.create_engine('sqlite:///database/test.db'),
	metadata=m.Base.metadata,
	keyword='db'
))

import logging

l = logging.getLogger('sqlalchemy.engine')
l.setLevel(logging.INFO)
l.addHandler(logging.FileHandler('sql.log'))

def slug(s):
	return s.lower().replace(' ', '-').replace("'", '')


def place_route_filter(config):
	''' Matches a place name'''
	regexp = r'[a-z0-9-]+'

	def to_python(match):
		for place in places:
			if to_url(place) == match:
				return place

		raise HTTPError(404, "No matching place")

	def to_url(place):
		return slug(place.name)

	return regexp, to_python, to_url

def room_route_filter(config):
	''' Matches a room id'''
	regexp = r'[0-9]+'

	def to_python(match):
		if match in rooms_by_id:
			return rooms_by_id[match]
		raise HTTPError(404, "No matching room")

	def to_url(room):
		return room['id']

	return regexp, to_python, to_url

app.router.add_filter('room', room_route_filter)
app.router.add_filter('place', place_route_filter)

@app.route('/static/<path:path>', name='static')
def static(path):
	return static_file(path, root='static')

@app.route(r'/')
def show_rooms(db):
	return template('index', db=db)

@app.route(r'/rooms')
def show_rooms(db):
	filters = []
	if request.query.vacant:
		filters.append(filter_vacant())
	if request.query.place:
		filters.append(filter_place(request.query.place))
	if request.query.group:
		filters.append(filter_group(request.query.group))

	return template('rooms', rooms=db.query(m.Room).all(), filters=filters)

@app.route(r'/rooms/random')
def show_random_room(db):
	rooms = db.query(m.Room)
	redirect('/rooms/{}'.format(rooms[random.randrange(rooms.count())].id))

@app.route(r'/places/random')
def show_random_room(db):
	locations = db.query(m.Cluster).filter_by(type='building')
	redirect('/places/{}'.format(locations[random.randrange(locations.count())].id))

@app.route(r'/places/random/photos')
def show_random_room(db):
	locations = db.query(m.Cluster).filter_by(type='building')
	redirect('/places/{}/photos'.format(locations[random.randrange(locations.count())].id))

@app.route(r'/rooms/<room_id>')
def show_room(room_id, db):
	try:
		room = db.query(m.Room).filter(m.Room.id == room_id).one()
		return template('room', room=room, version=request.query.v)
	except NoResultFound:
		raise HTTPError(404, "No matching room")


@app.route(r'/reviews', name="reviews")
def show_latest_reviews(db):
	occupancy = db.query(m.Occupancy).filter(m.Occupancy.resident_id == 'efw27').one()
	return template('new-review', occupancy=occupancy)


@app.route(r'/reviews/new', name="new-review")
def show_place(db):
	occupancy = db.query(m.Occupancy).filter(m.Occupancy.resident_id == 'efw27').one()
	return template('new-review', occupancy=occupancy)


@app.route(r'/places', name="location-list")
def show_place(db):
	root = db.query(m.Cluster).filter(m.Cluster.parent == None).one()
	return template('locations', location=root)

@app.route(r'/locations/<loc_id>', name="location-list")
def show_place(loc_id, db):
	try:
		location = db.query(m.Cluster).filter(m.Cluster.id == loc_id).one()
		return template('locations', location=location)
	except NoResultFound:
		raise HTTPError(404, "No matching location")


@app.route(r'/places/<place_id>', name="place")
def show_place(place_id, db):
	try:
		location = db.query(m.Cluster).filter(m.Cluster.id == place_id).one()
		return template('place', location=location, filters=[])
	except NoResultFound:
		raise HTTPError(404, "No matching location")

@app.route(r'/places/<place_id>/photos', name="place-photos")
def show_place(place_id, db):
	try:
		location = db.query(m.Cluster).filter(m.Cluster.id == place_id).one()
		return template('place-photos', place=location, filters=[])
	except NoResultFound:
		raise HTTPError(404, "No matching location")


@app.route(r'/users')
def show_place(db):
	from sqlalchemy.orm import joinedload, subqueryload

	users = db.query(m.Person).options(
		joinedload(m.Person.occupancies).load_only(),
		joinedload(m.Person.occupancies).subqueryload(m.Occupancy.reviews).load_only(m.Review.id),
		joinedload(m.Person.occupancies).subqueryload(m.Occupancy.photos).load_only(m.Photo.id)
	).order_by(m.Person.crsid)
	return template('users', users=users)



@app.route(r'/ballots')
def show_place(db):
	from sqlalchemy.orm import joinedload, subqueryload

	ballots = db.query(m.BallotSeason).options(
		joinedload(m.BallotSeason.events),
		joinedload(m.BallotSeason.room_listings).subqueryload(m.RoomListing.audience_types),
	).order_by(m.BallotSeason.year.desc())
	return template('ballots', ballots=ballots)


@app.route(r'/ballots/<ballot_id>/edit')
def show_place(ballot_id, db):
	from sqlalchemy.orm import joinedload, subqueryload

	ballot = db.query(m.BallotSeason).options(
		joinedload(m.BallotSeason.events),
		joinedload(m.BallotSeason.room_listings).subqueryload(m.RoomListing.audience_types),
	).filter(m.BallotSeason.year == ballot_id).one()
	return template('ballot', ballot_season=ballot, db=db)




def error_handler(res):
	return template('error', e=res)

app.default_error_handler = error_handler

if __name__ == '__main__':
	import socket
	if socket.gethostname() == 'pip':
		app.run(host='efw27.user.srcf.net', port=8098, server='cherrypy')
	else:
		app.run(host='localhost', port=8080, debug=True)
else:
	import bottle
	bottle.debug(True)


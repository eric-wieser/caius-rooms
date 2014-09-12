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
def show_rooms():
	return template('index')

@app.route(r'/rooms')
def show_rooms():
	filters = []
	if not request.query.unlisted:
		filters.append(filter_graduate())
	if request.query.vacant:
		filters.append(filter_vacant())
	if request.query.place:
		filters.append(filter_place(request.query.place))
	if request.query.group:
		filters.append(filter_group(request.query.group))

	return template('rooms', rooms=rooms, filters=filters)

@app.route(r'/rooms/random')
def show_random_room():
	redirect('/rooms/{}'.format(random.choice(rooms)['id']))

@app.route(r'/places/random')
def show_random_room():
	redirect(app.get_url('place', place=random.choice(places)))

@app.route(r'/places/random/photos')
def show_random_room():
	redirect(app.get_url('place-photos', place=random.choice(places)))


@app.route(r'/rooms/<room_id>')
def show_room(room_id, db):
	try:
		room = db.query(m.Room).filter(m.Room.id == room_id).one()
		return template('room', room=room, version=request.query.v)
	except NoResultFound:
		raise HTTPError(404, "No matching room")


@app.route(r'/reviews/new', name="new-review")
def show_place(db):
	occupancy = db.query(m.Occupancy).filter(m.Occupancy.resident_id == 'efw27').one()
	return template('new-review', occupancy=occupancy)


@app.route(r'/places', name="place-list")
def show_place():
	apply_reserved_rooms()
	return template('places', places=places)

@app.route(r'/locations', name="location-list")
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

@app.route(r'/places/<place:place>/photos', name="place-photos")
def show_place_photos(place):
	return template('place-photos', place=place, rooms=rooms, filters=[])


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


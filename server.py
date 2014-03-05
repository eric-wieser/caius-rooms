import json
import random

from bottle import *

with open('all.json') as f:
	rooms_by_id = json.load(f)

with open('places.json') as f:
	places = json.load(f)

rooms = []

for i, room in rooms_by_id.iteritems():
	room['place'] = places[room['place']]
	rooms.append(room)

for room in rooms:
	reviews = [r for r in room['reviews'] if r['rating'] is not None]
	room['mean_score'] = sum(r['rating'] for r in reviews) * 1.0 / len(reviews) if reviews else None
	n = len(reviews)
	room['bayesian_rank'] = (3 + n * room['mean_score'] ) / (1 + n) if reviews else None


def apply_reserved_rooms():
	self = apply_reserved_rooms

	fname = 'reservations.json'
	t = os.stat(fname).st_mtime
	if t > self.cache_time:
		for room in rooms:
			room['owner'] = None

		with open(fname) as f:
			for line in f:
				name, room_name = json.loads(line)
				try:
					room = next(r for r in rooms if r['name'] == room_name)
				except StopIteration:
					raise ValueError("No such room %r" % room_name)
				room['owner'] = name

		self.cache_time = t

apply_reserved_rooms.cache_time = 0

apply_reserved_rooms()


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

@app.route('/static/<path:path>', name='static')
def static(path):
	return static_file(path, root='static')

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
	redirect(app.get_url('place', place=random.choice(places.values())))

@app.route(r'/rooms/<room>')
def show_room(room):
	apply_reserved_rooms()
	if room in rooms_by_id:
		room = rooms_by_id[room]
		return template('room', room=room)
	else:
		raise HTTPError(404)

def slug(s):
	return s.lower().replace(' ', '-').replace("'", '')


def place_route_filter(config):
	''' Matches a place name'''
	regexp = r'[a-z0-9-]+'

	def to_python(match):
		for place in places.values():
			if to_url(place) == match:
				return place

	def to_url(place):
		return place['name'].lower().replace(' ', '-').replace("'", '')

	return regexp, to_python, to_url

app.router.add_filter('place', place_route_filter)

@app.route(r'/places/<place:place>', name="place")
def show_place(place):
	apply_reserved_rooms()
	return template('place', place=place, rooms=rooms, filters=[])

@app.route(r'/places/<place:place>/photos', name="place-photos")
def show_place_photos(place):
	return template('place-photos', place=place, rooms=rooms, filters=[])

import socket
if socket.gethostname() == 'pip':
	app.run(host='efw27.user.srcf.net', port=8098, server='cherrypy')
else:
	app.run(host='efw27.cai.private.cam.ac.uk', port=8080, debug=True)

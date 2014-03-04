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


@route('/static/<path:path>', name='static')
def static(path):
    return static_file(path, root='static')

@route(r'/rooms')
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

@route(r'/rooms/random')
def show_random_room():
	redirect('/rooms/{}'.format(random.choice(rooms)['id']))

@route(r'/rooms/<room>')
def show_room(room):
	apply_reserved_rooms()
	if room in rooms_by_id:
		room = rooms_by_id[room]
		return template('room', room=room)
	else:
		raise HTTPError(404)

import socket
if socket.gethostname() == 'pip':
	run(host='efw27.user.srcf.net', port=8098, server='cherrypy')
else:
	run(host='localhost', port=8080, debug=True)

import json
import random

from bottle import *

with open('all.json') as f:
	data = json.load(f)

with open('places.json') as f:
	places = json.load(f)



for i, room in data.iteritems():
	room['place'] = places[room['place']]


@route('/static/<path:path>', name='static')
def static(path):
    return static_file(path, root='static')

@route(r'/rooms')
def show_rooms():
	if request.query.place:
		return template('rooms', rooms={
			k: v for k, v in data.iteritems()
			if v['place'] == request.query.place
		})
	else:
		return template('rooms', rooms=data)

@route(r'/rooms/random')
def show_random_room():
	redirect('/rooms/{}'.format(random.choice(data.keys())))

@route(r'/rooms/<room>')
def show_room(room):
	if room in data:
		room = data[room]
		return template('room', room=room)
	else:
		raise HTTPError(404)

import socket
if socket.gethostname() == 'pip':
	run(host='efw27.user.srcf.net', port=8098, server='cherrypy')
else:
	run(host='localhost', port=8080, debug=True)

import json
import random

from bottle import *

with open('all.json') as f:
	data = json.load(f)

for i, room in data.iteritems():
	room['id'] = int(i)

@route(r'/rooms')
def show_rooms():
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

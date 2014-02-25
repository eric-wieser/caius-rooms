import json

from bottle import *

with open('all2.json') as f:
	data = json.load(f)

@route(r'/rooms')
def show_rooms():
	return template('rooms', rooms=data)

@route(r'/rooms/<room>')
def show_room(room):
	if room in data:
		room = data[room]
		return template('room', room=room)
	else:
		raise HTTPError(404)

import socket
if socket.gethostname() == 'pip':
	run(host='efw27.user.srcf.net', port=8098)
else:
	run(host='localhost', port=8080, debug=True)

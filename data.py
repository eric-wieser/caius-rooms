import json
import os
import re

with open('all.json') as f:
	rooms_by_id = json.load(f)

with open('places.json') as f:
	places_by_id = json.load(f)

rooms = []

for i, room in rooms_by_id.iteritems():
	room['place'] = places_by_id[room['place']]
	rooms.append(room)

places = places_by_id.values()
for place in places:
	place['rooms'] = [rooms_by_id[str(i)] for i in place['roomIds']]

for room in rooms:
	reviews = [r for r in room['reviews'] if r['rating'] not in (None, 1)]
	room['mean_score'] = sum(r['rating'] for r in reviews) * 1.0 / len(reviews) if reviews else None
	n = len(reviews)
	room['bayesian_rank'] = (3 + n * room['mean_score'] ) / (1 + n) if reviews else None
	room['references'] = []

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

def process_links(item):
	from bottle import html_escape

	room = item['review']['room']
	nearby_rooms = room['place']['rooms']

	scanner = re.Scanner([
		('gyp room', lambda scanner, token: ('TEXT', token)),
	] + [
		(
			r'\b' + re.escape(nearby_room['number']) + r'\b',
			lambda scanner, token, nearby_room=nearby_room: ('ROOM', (token, nearby_room))
		)
		for nearby_room in nearby_rooms
	] + [
		('.+?\b', lambda scanner, token: ('TEXT', token)),
		('.', lambda scanner, token: ('TEXT', token))
	], flags=re.IGNORECASE | re.DOTALL)

	results, remainder = scanner.scan(item['value'])
	assert not remainder

	item['value'] = ''.join(
		html_escape(value) if t == 'TEXT' else
		'<a href="/rooms/{}">{}</a>'.format(value[1]['id'], html_escape(value[0]))
		for t, value in results
	)

	for t, value in results:
		if t == 'ROOM':
			refered = value[1]
			if not any(x is item for x in refered['references']) and refered is not room:
				refered['references'].append(item)

def find_references():
	for room in rooms:
		for review in room['reviews']:
			review['room'] = room
			for item in review.get('sections', []):
				item['review'] = review
				if item['value']:
					process_links(item)

from threading import Thread
# Thread(target=find_references).run()
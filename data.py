import json
import os

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

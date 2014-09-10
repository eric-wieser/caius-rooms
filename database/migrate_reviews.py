import db
import orm
import olddb
import datetime
import re
from sqlalchemy.orm.exc import NoResultFound

import migrate_utils

db.init('dev')

new_session = db.Session()
old_session = olddb.Session()

count = 0

new_locs = set()

def try_recover_location(review):
	staircase = review.staircase
	loc_name = review.location

	# fix K stair / K block confusion / random A staircase
	if staircase == 'K' and loc_name == 'Harvey Court':
		staircase = None
		loc_name = 'K Block'
	elif loc_name == '4 Rose Crescent':
		staircase = None

	try:
		location = migrate_utils.get_location(new_session, review.location)
	except migrate_utils.NewLocation as e:
		location = e.args[1]
		new_locs.add(location)

	if staircase != 'None' and staircase:
		try:
			location = new_session.query(orm.Cluster).filter(
				(orm.Cluster.parent == location) &
				(orm.Cluster.name == staircase)
			).one()
		except NoResultFound:
			print "New staircase {} in {}".format(staircase, location)
			location = orm.Cluster(name=staircase, type="staircase", parent=location)
			new_locs.add(location)

	return location

def try_recover_room(review):
	location = try_recover_location(review)

	rooms = (new_session
		.query(orm.Room)
		.filter(orm.Room.parent == location)
	)

	# look for an existing room
	try:
		return rooms.filter(orm.Room.name == review.room).one()
	except NoResultFound:
		pass

	# look for joint rooms that share a number
	numeric_room = review.room.rstrip('*')
	for r in rooms:
		s = re.split('\D+', r.name)
		if numeric_room in s:
			return r

	# we have a new room
	name = review.room
	if name.endswith('**'):
		print "Truncated starred room {} {}".format(name, location)
		name = name.rstrip('*') + '*'

	return orm.Room(
		name=name,
		parent=location,
		living_room_view=migrate_utils.sanitize_view(review.livingroom_position),
		bedroom_view=migrate_utils.sanitize_view(review.position)
	)

seen_ts = set()
duplicates = 0

for old_review in old_session.query(olddb.orm.accom_guide_input):
	ts = datetime.datetime.fromtimestamp(old_review.submitted_ts)
	if ts in seen_ts:
		duplicates += 1
		continue
	seen_ts.add(ts)

	if old_review.roomID == 0:
		room = try_recover_room(old_review)
		if not room:
			continue
	else:
		try:
			room = new_session.query(orm.Room).filter(orm.Room.id == old_review.roomID).one()
			old_room = old_session.query(olddb.orm.accom_guide_rooms).filter(olddb.orm.accom_guide_rooms.id == old_review.roomID).one()
		except NoResultFound:
			print "Unknown room", old_review.location, old_review.room
			continue

		# We've found a room - check it actually matches the review
		def problem(old, new):
			if old == 'None' or not old:
				old = None
			if new == 'None' or not new:
				new = None
			return old and old != new

		if problem(old_review.location, old_room.location):
			print "Review location:", old_review.location
			print "Room   location:", old_room.location

		if old_review.location != 'K Block' and problem(old_review.staircase, old_room.staircase):
			print "Review stair:", old_review.staircase
			print "Room   stair:", old_room.staircase
			print "Room   location:", old_room.location

		if problem(old_review.room, old_room.room):
			print "Review room:", old_review.room
			print "Room   room:", old_room.room
			print "Room   location:", old_room.location


print duplicates

# new_session.commit()

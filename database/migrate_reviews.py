import db
import orm
import olddb
import datetime
from sqlalchemy.orm.exc import NoResultFound, MultipleResultsFound

import migrate_utils

db.init('dev')

new_session = db.Session()
old_session = olddb.Session()

count = 0

new_locs = set()

seen_ts = set()
duplicates = 0
success = 0

def problem(old, new):
	if old == 'None' or not old:
		old = None
	if new == 'None' or not new:
		new = None
	return old and old != new

for old_review in old_session.query(olddb.orm.accom_guide_input).order_by(olddb.orm.accom_guide_input.submitted_ts.desc()):
	ts = datetime.datetime.fromtimestamp(old_review.submitted_ts)
	if ts in seen_ts:
		duplicates += 1
		continue
	seen_ts.add(ts)

	if old_review.roomID == 0:
		location = migrate_utils.get_location_with_stair(
			new_session, old_review.location, old_review.staircase
		)
		room = migrate_utils.try_recover_room(
			new_session, location, old_review.room
		)
	else:
		try:
			room = new_session.query(orm.Room).filter(orm.Room.id == old_review.roomID).one()
			old_room = old_session.query(olddb.orm.accom_guide_rooms).filter(olddb.orm.accom_guide_rooms.id == old_review.roomID).one()
		except NoResultFound:
			print "Unknown room", old_review.location, old_review.room
			continue

		# We've found a room - check it actually matches the review

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


	# add any new view data (skip conflicts)
	living_room_view = migrate_utils.sanitize_view(old_review.livingroom_position)
	bedroom_view = migrate_utils.sanitize_view(old_review.position)

	if living_room_view and not room.living_room_view:
		room.living_room_view = living_room_view
	if bedroom_view and not room.bedroom_view:
		room.bedroom_view = bedroom_view


	listing = migrate_utils.try_recover_listing(new_session, room, ts)
	if listing.occupancies:
		occupancy = listing.occupancies[0]
	else:
		occupancy = orm.Occupancy(
			listing=listing
		)

	def heading_to_colname(h):
		lower = heading.name.lower()
		expected = ['noise', 'lighting', 'heating', 'kitchen', 'bathroom', 'furniture', 'worst', 'best', 'general']
		return next(e for e in expected if e in lower)

	review = orm.Review(
		published_at=ts,
		rating=old_review.marks,
		sections=[
			orm.ReviewSection(
				content=getattr(old_review, heading_to_colname(heading)),
				heading=heading
			)
			for heading in new_session.query(orm.ReviewHeading)
		],
		occupancy=occupancy,
	)

	new_session.add(review)

new_session.commit()

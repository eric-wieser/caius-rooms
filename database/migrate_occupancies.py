import db
import orm
import olddb
from sqlalchemy.orm.exc import NoResultFound

db.init('dev')

new_session = db.Session()
old_session = olddb.Session()

for reservation in old_session.query(olddb.orm.accom_guide_reservation):
	try:
		# get the listing we already have for this entry
		listing = (new_session
			.query(orm.RoomListing)
			.filter(orm.RoomListing.room_id == reservation.room)
			.filter(orm.RoomListing.ballot_id == reservation.ballot)
			.one()
		)
	except NoResultFound:
		# we found a listing that wasn't in the most recent ballot
		room = new_session.query(orm.Room).filter(orm.Room.id == reservation.room).one()
		ballot = new_session.query(orm.Ballot).filter(orm.Ballot.id == reservation.ballot).one()

		listing = orm.RoomListing(
			room=room,
			ballot=ballot
		)
		new_session.add(listing)

	crsid = reservation.person.lower()
	if 'reserved' in crsid or 'music' in crsid:
		continue

	person = new_session.query(orm.Person).filter(orm.Person.crsid == crsid).one()

	occupancy = orm.Occupancy(
		listing=listing,
		resident=person,
		chosen_at=reservation.ts_chosen
	)
	new_session.add(occupancy)

new_session.commit()

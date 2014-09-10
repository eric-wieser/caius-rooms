import db
import orm
import olddb

db.init('dev')

new_session = db.Session()
old_session = olddb.Session()

print new_session.query(orm.Ballot).filter(orm.Ballot.rental_year==2014)

ballots = new_session.query(orm.Ballot).filter(orm.Ballot.rental_year==2014)
b4 = ballots.filter(orm.Ballot.type == '4th').one()
bu = ballots.filter(orm.Ballot.type == 'ugrad').one()

for old_room in old_session.query(olddb.orm.accom_guide_rooms):
	new_room = new_session.query(orm.Room).filter(orm.Room.id == old_room.id).one()

	if old_room.ballot_type == 1:
		ballot = bu
	elif old_room.rent:
		ballot = b4
	else:
		print "skipping", new_room
		continue

	def parse_bool(x):
		if x is None or x == '':
			return None

		if x.lower() in ('y', 'yes', '1'):
			return True
		elif x.lower() in ('n', 'no', '0'):
			return False

	listing = orm.RoomListing(
		room=new_room,
		ballot=ballot,

		rent=old_room.rent,

		has_piano     = parse_bool(old_room.piano),
		has_washbasin = parse_bool(old_room.washbasin),
		has_eduroam   = parse_bool(old_room.eduroam),
		has_ethernet  = parse_bool(old_room.network)
	)
	new_session.add(listing)
new_session.commit()

for r in bu.room_listings:
	print r.room
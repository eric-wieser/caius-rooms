import db
import orm
import olddb

db.init('dev')

new_session = db.Session()
old_session = olddb.Session()

this_season = (new_session
	.query(orm.BallotSeason)
	.filter(orm.BallotSeason.year == 2014)
).one()

bt_ugrad = (new_session
	.query(orm.BallotType)
	.filter(orm.BallotType.name == 'Undergraduate')
).one()

bt_fourth = (new_session
	.query(orm.BallotType)
	.filter(orm.BallotType.name == '4th year')
).one()

bt_grad = (new_session
	.query(orm.BallotType)
	.filter(orm.BallotType.name == 'Graduate')
).one()

for old_room in old_session.query(olddb.orm.accom_guide_rooms):
	new_room = new_session.query(orm.Room).filter(orm.Room.id == old_room.id).one()

	rent = old_room.rent or None

	if old_room.ballot_type == 1:
		audiences = [
			bt_ugrad,
			bt_fourth
		]
	elif rent:
		audiences = [
			bt_fourth
		]
	else:
		audiences = [
			bt_grad
		]

	def parse_bool(x):
		if x is None or x == '':
			return None

		if x.lower() in ('y', 'yes', '1'):
			return True
		elif x.lower() in ('n', 'no', '0'):
			return False

	listing = orm.RoomListing(
		room=new_room,
		ballot_season=this_season,
		audience_types=audiences,

		rent=rent,

		has_piano     = parse_bool(old_room.piano),
		has_washbasin = parse_bool(old_room.washbasin),
		has_eduroam   = parse_bool(old_room.eduroam),
		has_ethernet  = parse_bool(old_room.network)
	)
	new_session.add(listing)
new_session.commit()

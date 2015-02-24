from database import olddb, db
import database.orm as m
import time

OldReservation = olddb.orm.accom_guide_reservation

old_ballot_id = 12
new_ballot_id = 2015


def update():
	os = olddb.Session()
	ns = db.Session()

	ballot = ns.query(m.BallotSeason).get(new_ballot_id)

	reserves = os.query(OldReservation).filter(OldReservation.ballot == old_ballot_id)

	for r in reserves:
		room = ns.query(m.Room).get(r.room)
		if not room:
			print "ER: room {} does not exist".format(r.room)
			continue

		user = ns.query(m.Person).get(r.person)
		if not user:
			print "EU: user {} does not exist".format(r.person)
			continue

		listing = room.listing_for.get(ballot)
		if not listing:
			print "EL: no listing for room {} ({})".format(r.room, room.pretty_name())
			continue

		if not any(user == o.resident for o in listing.occupancies):
			listing.occupancies.append(m.Occupancy(
				resident=user,
				chosen_at=r.ts_chosen
			))
			print "B: {:6s} -> {:3d} ({})".format(user.crsid, room.id, room.pretty_name())

	ns.commit()
	ns.close()
	os.close()

while True:
	try:
		update()
	except Exception as e:
		print "EE: {}".format(e)
	time.sleep(1)

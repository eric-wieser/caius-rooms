from sqlalchemy.orm import sessionmaker
import orm as m

def copy(old_engine, new_engine):
	NewSession = sessionmaker(new_engine)
	OldSession = sessionmaker(old_engine)

	print "dropping..."
	# m.Base.metadata.drop_all(new_engine)
	print "creating..."
	m.Base.metadata.create_all(new_engine)

	class Temp(m.Base):
		__table__ = m.room_listing_audiences_assoc

	classes = [
		m.Person,
		m.Cluster,
		m.BallotSeason,
		m.Room,
		m.BallotType,
		m.BallotEvent,
		m.BallotSlot,
		m.RoomListing,
		m.Occupancy,
		m.Review,
		m.ReviewHeading,
		m.ReviewSection,
		m.ReviewRoomReference,
		m.Photo,
		Temp
	]

	os = OldSession()
	ns = NewSession()

	for c in classes:
		print "Processing {} objects".format(c.__name__)
		n = os.query(c).count()
		for i, x in enumerate(os.query(c), 1):
			ns.merge(x)
			f = i * 1.0 / n
			print '\r[{:20s}] {: 3d}/{: 3d}'.format('='*int(f*20), i, n),
		print


	ns.commit()

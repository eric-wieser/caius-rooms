import sys

sys.path.append('..')


import migrate_constants
import migrate_users
import migrate_ballots
import migrate_slots
import migrate_rooms
import migrate_room_listings
import migrate_occupancies
import migrate_reviews
import migrate_photos



migrations = [
	migrate_constants,
	migrate_users,
	migrate_ballots,
	migrate_slots,
	migrate_rooms,
	migrate_room_listings,
	migrate_occupancies,
	migrate_reviews,
	migrate_photos
]

import db, olddb, orm

orm.Base.metadata.drop_all(db.engine)
orm.Base.metadata.create_all(db.engine)

new_session = db.Session()
old_session = olddb.Session()

for m in migrations:
	m.migrate(old_session, new_session)
	new_session.commit()
	print "{}: Done".format(m.__name__)

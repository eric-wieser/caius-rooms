import os

import datetime
from sqlalchemy.orm.exc import NoResultFound, MultipleResultsFound

import migrate_utils

def migrate(old_session, new_session):
	import orm
	import olddb

	new_session.query(orm.Photo).delete()

	for old_photo in old_session.query(olddb.orm.accom_guide_photos).order_by(olddb.orm.accom_guide_photos.submitted.desc()):
		ts = datetime.datetime.fromtimestamp(old_photo.submitted)

		location = migrate_utils.get_location_with_stair(
			new_session, old_photo.location, old_photo.staircase
		)
		room = migrate_utils.try_recover_room(
			new_session, location, old_photo.room
		)

		listing = migrate_utils.try_recover_listing(new_session, room, ts)
		if listing.occupancies:
			occupancy = listing.occupancies[0]
		else:
			occupancy = orm.Occupancy(
				listing=listing
			)

		photo = orm.Photo(
			id=old_photo.id,

			published_at=ts,
			caption=old_photo.comment,

			width=old_photo.width,
			height=old_photo.height,
			mime_type=old_photo.type,

			occupancy=occupancy
		)

		if hasattr(old_photo, 'photo'):
			base = os.path.dirname(photo.storage_path)

			try:
				os.makedirs(base)
			except OSError:
				if not os.path.isdir(base):
					raise

			with open(photo.storage_path, 'w') as f:
				f.write(old_photo.photo)
		else:
			# exported db has no blobs
			pass

		new_session.add(photo)

if __name__ == '__main__':
	migrate_utils.run(migrate)
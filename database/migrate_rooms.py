import db
import orm
import olddb

import re
from sqlalchemy.orm import aliased
from sqlalchemy.orm.exc import NoResultFound

import migrate_utils

db.init('dev')

new_session = db.Session()
old_session = olddb.Session()

for old_room in old_session.query(olddb.orm.accom_guide_rooms):
	location = migrate_utils.get_location(new_session, old_room.location)

	if old_room.staircase != 'None':
		try:
			location = new_session.query(orm.Cluster).filter(
				(orm.Cluster.parent == location) &
				(orm.Cluster.name == old_room.staircase)
			).one()
		except NoResultFound:
			location = orm.Cluster(name=old_room.staircase, type="staircase", parent=location)

	if old_room.comment:
		name = re.search(r'\d+/\d+', old_room.comment).group(0)
	else:
		name = old_room.room

	new_room = orm.Room(
		id=old_room.id,
		name=name,
		parent=location,
	 	is_suite=old_room.type == 'Suite',

	 	bedroom_x=int(old_room.bed_x or 0) or None,
	 	bedroom_y=int(old_room.bed_y or 0) or None,
	 	bedroom_view=migrate_utils.sanitize_view(old_room.position),

	 	living_room_x=int(old_room.living_x or 0) or None,
	 	living_room_y=int(old_room.living_y or 0) or None,
	 	living_room_view=migrate_utils.sanitize_view(old_room.livingroom_position)
	)
	print new_room
	new_session.add(new_room)

new_session.commit()
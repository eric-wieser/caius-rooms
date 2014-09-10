import db
import orm
from sqlalchemy.orm import aliased
from sqlalchemy.orm.exc import NoResultFound
import olddb
import re

db.init('dev')

new_session = db.Session()
old_session = olddb.Session()

def get_location(old_room):
	loc_name = old_room.location.replace("Rd", "Road")
	try:
		return new_session.query(orm.Cluster).filter(orm.Cluster.name == loc_name).one()
	except NoResultFound:
		pass

	number, place = loc_name.split(" ", 1)
	try:
		clusteralias = aliased(orm.Cluster)
		return (
			new_session.query(orm.Cluster)
				.filter(orm.Cluster.name == number)
				.join(clusteralias, orm.Cluster.parent)
				.filter(clusteralias.name == place).one()
		)
	except NoResultFound:
		print number, place
		raise

def sanitize_view(v):
	if not v:
		return None
	elif v in ("Unspecified", "N/A", "[unknown]"):
		return None
	else:
		return v

for old_room in old_session.query(olddb.orm.accom_guide_rooms):
	location = get_location(old_room)

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
	 	bedroom_view=sanitize_view(old_room.position),

	 	living_room_x=int(old_room.living_x or 0) or None,
	 	living_room_y=int(old_room.living_y or 0) or None,
	 	living_room_view=sanitize_view(old_room.livingroom_position)
	)
	new_session.add(new_room)

new_session.commit()
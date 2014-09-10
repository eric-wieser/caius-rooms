import db
import orm

from sqlalchemy.orm import aliased
from sqlalchemy.orm.exc import NoResultFound

class NewLocation(Exception):
	pass

def get_location(new_session, loc_name):
	loc_name = loc_name.replace("Rd", "Road")
	loc_name = loc_name.replace("35/37", "35-37")
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
		root = new_session.query(orm.Cluster).filter(orm.Cluster.parent == None).one()

		raise NewLocation("New location #{}, {}.format(number, place)", orm.Cluster(
			name=number,
			parent=orm.Cluster(
				name=place,
				parent=root
			)
		))

def sanitize_view(v):
	if not v:
		return None
	elif v in ("Unspecified", "N/A", "[unknown]"):
		return None
	else:
		return v


import re

from sqlalchemy.orm import aliased
from sqlalchemy.orm.exc import NoResultFound

import db
import orm

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

def get_location_with_stair(new_session, loc_name, staircase):
	# fix K stair / K block confusion / random A staircase
	if staircase == 'K' and loc_name == 'Harvey Court':
		staircase = None
		loc_name = 'K Block'
	elif loc_name == '4 Rose Crescent':
		staircase = None

	try:
		location = get_location(new_session, loc_name)
	except NewLocation as e:
		location = e.args[1]
		new_locs.add(location)

	if staircase != 'None' and staircase:
		try:
			location = new_session.query(orm.Cluster).filter(
				(orm.Cluster.parent == location) &
				(orm.Cluster.name == staircase)
			).one()
		except NoResultFound:
			print "New staircase {} in {}".format(staircase, location)
			location = orm.Cluster(name=staircase, type="staircase", parent=location)
			new_locs.add(location)

	return location


def try_recover_room(new_session, location, name):
	rooms = (new_session
		.query(orm.Room)
		.filter(orm.Room.parent == location)
	)

	# look for an existing room
	try:
		return rooms.filter(orm.Room.name == name).one()
	except NoResultFound:
		pass

	# look for joint rooms that share a number
	numeric_room = name.rstrip('*')
	for r in rooms:
		s = re.split('\D+', r.name)
		if numeric_room in s:
			return r

	# we have a new room
	name = name
	if name.endswith('**'):
		print "Truncated starred room {} {}".format(name, location)
		name = name.rstrip('*') + '*'

	return orm.Room(
		name=name,
		parent=location
	)

def try_recover_ballot(new_session, year):
	# get all ballots for the year
	ballots = (new_session
		.query(orm.Ballot)
		.filter(orm.Ballot.rental_year == year)
		.order_by(orm.Ballot.opens_at.desc())
	)

	# assume undergrad?
	try:
		return ballots.filter(orm.Ballot.type == 'ugrad').first()
	except NoResultFound:
		pass

	# or not
	try:
		return ballots.first()
	except NoResultFound:
		pass

	# or roll a new one
	return orm.Ballot(
		is_reconstructed=True,

		type='ugrad',
		opens_at=datetime.date(year + 1, 1, 1)
	)


def try_recover_listing(new_session, room, ts):
	if ts.month > 9:
		guessed_ballot_year = ts.year
	else:
		guessed_ballot_year = ts.year - 1

	# see if we have a listing already
	try:
		return (new_session
			.query(orm.RoomListing)
			.join(orm.Ballot)
			.filter(orm.RoomListing.room == room)
			.filter(orm.Ballot.rental_year == guessed_ballot_year)
		).one()
	except NoResultFound:
		pass

	# get all ballots for the year
	ballot = try_recover_ballot(new_session, guessed_ballot_year)

	return orm.RoomListing(
		room=room,
		ballot=ballot
	)

def sanitize_view(v):
	if not v:
		return None
	elif v in ("Unspecified", "N/A", "[unknown]"):
		return None
	else:
		return v


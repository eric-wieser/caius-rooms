import re
import datetime

from sqlalchemy.orm import aliased
from sqlalchemy.orm.exc import NoResultFound, MultipleResultsFound

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
		raise NewLocation("New location #{}, {}.format(number, place)", orm.Cluster(
			name=number,
			type="building",
			parent=orm.Cluster(
				name=place,
				type="road",
				parent=None
			)
		))

def get_location_with_stair(new_session, loc_name, staircase):
	# fix K stair / K block confusion / random A staircase
	if staircase == 'K' and loc_name == 'Harvey Court' or loc_name == 'K Block':
		staircase = None
		loc_name = 'K Block'
	elif loc_name == '4 Rose Crescent':
		staircase = None

	try:
		location = get_location(new_session, loc_name)
	except NewLocation as e:
		location = e.args[1]

	if staircase != 'None' and staircase:
		try:
			location = new_session.query(orm.Cluster).filter(
				(orm.Cluster.parent == location) &
				(orm.Cluster.name == staircase)
			).one()
		except NoResultFound:
			print "New staircase {} in {}".format(staircase, location)
			location = orm.Cluster(name=staircase, type="staircase", parent=location)


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
	ballot = ballots.filter(orm.Ballot.type == 'ugrad').first()
	if ballot:
		return ballot

	# or not
	ballot = ballots.first()
	if ballot:
		return ballot

	# or roll a new one
	ballot = orm.Ballot(
		is_reconstructed=True,
		type='ugrad',
		opens_at=datetime.date(year + 1, 1, 1)
	)
	new_session.add(ballot)

	print "New ballot for", repr(ballot.rental_year), repr(year)

def get_year(ts, from_start=True):
	threshold = 9 if from_start else 7

	if ts.month >= threshold:
		return ts.year
	else:
		return ts.year - 1

def try_recover_listing(new_session, room, ts):
	guessed_ballot_year = get_year(ts)

	# see if we have a listing already
	query = (new_session
		.query(orm.RoomListing)
		.join(orm.BallotSeason)
		.filter(orm.RoomListing.room == room)
		.filter(orm.BallotSeason.year == guessed_ballot_year)
	)
	try:
		return query.one()
	except MultipleResultsFound:
		return query.filter(orm.Ballot.type == 'ugrad').one()
	except NoResultFound:
		pass

	# get all ballots for the year
	ballot_season = get_ballot_season(new_session, guessed_ballot_year)

	return orm.RoomListing(
		room=room,
		ballot_season=ballot_season
	)

def get_ballot_season(new_session, year):
	try:
		return (new_session
			.query(orm.BallotSeason)
			.filter(orm.BallotSeason.year == year)
		).one()
	except NoResultFound:
		return orm.BallotSeason(year=year)

def sanitize_view(v):
	if not v:
		return None
	elif v in ("Unspecified", "N/A", "[unknown]"):
		return None
	else:
		return v


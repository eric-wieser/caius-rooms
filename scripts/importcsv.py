# -*- coding: utf-8 *-*

import sys
sys.path.append('..')

import csv
from decimal import Decimal
import regex as re
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy import func 

from database.db import Session
import database.orm as m

with open('room caius list 2014-15.csv') as f:
	d = csv.DictReader(f)
	data = list(d)

rent_keys = {
	2011: 'Rent/Term 2011',
	2012: 'Rent 2012',
	2013: 'Rent 2013',
	2014: 'Rent 2014'
}

print data[0]

s = Session()

bt_ugrad = (s
	.query(m.BallotType)
	.filter(m.BallotType.name == 'Undergraduate')
).one()

def get_room_by_name(name):
	""" Convert whatever name the spreadsheet uses into a room object """
	name = name.replace('Ct', 'Court')
	name = name.replace('Rd', 'Road')
	name = name.replace('Green St', 'Green Street')
	name = name.replace('Marys', 'Mary\'s')
	name = name.replace('Michaels', 'Michael\'s')
	name = name.replace('Cres', 'Crescent')

	parts = name.split(' ')
	for i in [-1, -2, -3]:
		try:
			base = s.query(m.Cluster).filter(
				func.lower(m.Cluster.name) == ' '.join(parts[i:]).lower()
			).one()
			parts = parts[:i]
			break 
		except NoResultFound:
			pass
	else:
		raise ValueError

	# look for named staircases
	if len(parts) == 1:
		mat = re.match(r'''(?x)
			^
			(?P<stair>[A-Z])?
			(?P<num>
				\d+
				(?:/\d+)?
				\*?
				a?
			)
			\*?
			$
		''', parts[0])

		if not mat:
			raise ValueError('Shit')

		g = mat.groupdict()
		if g['stair']:
			stair = next((c for c in base.children if c.name == g['stair']), None)

			# deal with k block
			if not stair:
				if g['stair'] == 'K' and base.name == 'Harvey Court':
					stair = s.query(m.Cluster).filter(m.Cluster.name == 'K Block').one()
				else:
					raise ValueError
			base = stair

		room = next((c for c in base.rooms if c.name == g['num']), None)

		if not room:
			raise ValueError
		
		return room

	else:
		assert len(parts) == 2
		parts = [p.replace(',', '') for p in parts]

		building = next((c for c in base.children if c.name == parts[1]), None)
		room = next((c for c in building.rooms if c.name == parts[0]), None)

		if not room:
			raise ValueError
		
		return room



found = 0
total = 0

seen = set()
def get_rooms():
	for line in data:
		rents = {
			k: Decimal(
				line[v].replace(',', '')
				       .replace(u'£'.encode('latin-1'), '')
			)
			for k, v in rent_keys.items()
			if line[v]
		}
		
		room = get_room_by_name(line['Room'])

		if room in seen:
			continue

		seen.add(room)

		yield room, rents, line


b2014 = set(
	l.room for l in
	s
	.query(m.RoomListing)
	.join(m.BallotSeason).filter(m.BallotSeason.year == 2014)
	.join(m.RoomListing.audience_types).filter(m.BallotType.name == 'Undergraduate')
)

for room, rents, ext in get_rooms():
	b2014.remove(room)
	for year, rent in rents.items():
		ballot_season = s.query(m.BallotSeason).filter(m.BallotSeason.year == year).one()

		listing = room.listing_for.get(ballot_season)
		if listing:
			found += 1
			if listing.rent and listing.rent != rent:
				if abs(listing.rent - rent) > 1:
					print room, rent, listing.rent
			listing.rent = rent
		else:
			listing = m.RoomListing(
				room=room,
				ballot_season=ballot_season,
				rent=rent
			)
			s.add(listing)

		if ext['Occ'] == 'U':
			listing.audience_types.add(bt_ugrad)
		total += 1

print b2014

s.commit()

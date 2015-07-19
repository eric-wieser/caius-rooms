from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, joinedload_all
import database.orm as m
import regex as re

import reference_helper



PartRoom = object()
MultiRoom = object()

def find_room(room, path_str):
	# deal with old naming of K block
	if len(path_str) > 1 and path_str[-2] == u'K' and room.parent.path[-1].name.lower() == u'k block':
		path_str[-2:-1] = []

	# find the common base of the room and path
	base = room.parent.path[-len(path_str)]

	# iterate down clusters:
	for item in path_str[:-1]:
		for child in base.children:
			if child.name == item:
				base = child
				break
		else:
			return None

	# look in rooms
	item = path_str[-1]
	for child in base.rooms:
		if child.name.replace('*', '') == item:
			return child
		elif item in child.name.split('/'):
			return PartRoom
		elif child.name in item.split('/'):
			return MultiRoom
	else:
		return None

def scan(room, section):
	for path, (start_idx, end_idx) in reference_helper.references_in(section.content):
		ref_room = find_room(room, path)
		if ref_room is PartRoom:
			print room, path, '=>', 'PartRoom'
			print section.content[max(0, start_idx-10):end_idx + 10]
			continue

		if ref_room is MultiRoom:
			print room, path, '=>', 'MultiRoom'
			print section.content[max(0, start_idx-10):end_idx + 10]
			continue

		if ref_room is None:
			print room, path, '=>', ref_room
			print section.content[max(0, start_idx-10):end_idx + 10]
			continue

		ref = m.ReviewRoomReference(
			review_section=section,
			start_idx=start_idx,
			end_idx=end_idx,
			room=ref_room
		)

		yield ref


def scan_review(review):
	room = review.occupancy.listing.room
	for section in review.sections:
		for ref in scan(room, section):
			yield ref


if __name__ == '__main__':
	# setup db stuff
	import database.db

	s = database.db.Session()

	s.query(m.ReviewRoomReference).delete()

	def get_all_reviews():
		for room in s.query(m.Room):
			for listing in room.listings:
				for occupancy in listing.occupancies:
					for review in occupancy.reviews:
						yield review

	for section in get_all_reviews():
		for ref in scan_review(section):
			s.add(ref)

	s.commit()

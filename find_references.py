from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, joinedload_all
import database.orm as m
import regex as re

import reference_helper

# setup db stuff
Session = sessionmaker()
engine = create_engine('sqlite:///database/test.db')
m.Base.metadata.create_all(engine)
Session.configure(bind=engine)
s = Session()

def get_all_sections_by_room():
	for room in s.query(m.Room):
		def gen():
			for listing in room.listings:
				for occupancy in listing.occupancies:
					for review in occupancy.reviews:
						for section in review.sections:
							yield section

		yield room, gen()

s.query(m.ReviewRoomReference).delete()

DummyRoom = object()

def find_room(room, path_str):
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
			return DummyRoom
		elif child.name in item.split('/'):
			return DummyRoom
	else:
		return None


for room, sections in get_all_sections_by_room():
	for section in sections:
		for path, span in reference_helper.references_in(section.content):

			ref_room = find_room(room, path)
			if ref_room is DummyRoom:
				continue

			if ref_room is None:
				print room, path, '=>', ref_room
				continue

			start_idx, end_idx = span
			ref = m.ReviewRoomReference(
				review_section=section,
				start_idx=start_idx,
				end_idx=end_idx,
				room=ref_room
			)

			s.add(ref)

s.commit()
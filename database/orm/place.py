from sqlalchemy import Column, ForeignKey, UniqueConstraint
from sqlalchemy.types import (
	Enum,
	Float,
	Integer,
	Unicode,
)
from sqlalchemy.orm.session import object_session
from sqlalchemy.orm import relationship

from . import Base


class Place(Base):
	""" (nestable) Groups of nearby physical rooms """
	__tablename__ = 'clusters'

	id         = Column(Integer,                         primary_key=True)
	name       = Column(Unicode(255),                    nullable=False)
	parent_id  = Column(Integer, ForeignKey(id))
	type       = Column(Enum("staircase", "building", "road", name='cluster_type'))

	latitude  = Column(Float)
	longitude = Column(Float)

	parent = relationship(lambda: Place,
		backref="children",
		remote_side=[id])

	__table_args__ = (UniqueConstraint(parent_id, name, name='_child_name_uc'),)

	@property
	def path(self):
		if self.parent is None:
			# don't list the root node
			return []
		else:
			return self.parent.path + [self]

	def __repr__(self):
		return "<Place {}>".format(' / '.join(c.name for c in self.path))

	def pretty_name(self, relative_to=None):
		"""
		Produce a pretty name relative to a Place. Traversing down the tree
		of Clusters, changing `relative_to` as we go gives:

			1 Mortimer road
			House 1

		or

			Tree court, Staircase S
			Staircase S
		"""
		def get_parent(x):
			if x.parent == relative_to:
				return None
			return x.parent


		if self.type == 'staircase':
			parent = get_parent(self)
			if parent:
				return '{}, {} Staircase'.format(
					parent.pretty_name(relative_to),
					self.name
				)
			else:
				return '{} Staircase'.format(self.name)


		if self.type == 'building':
			road = self.parent

			if road and road.type == 'road':

				# add the road name
				if road != relative_to:
					return "{} {}".format(self.name, road.name)
				else:
					return "House {}".format(self.name)


		return self.name


	@property
	def geocoords(self):
		current = self
		while current:
			if current.latitude and current.longitude:
				return current.latitude, current.longitude
			current = current.parent

	@property
	def all_rooms_q(self):
		from sqlalchemy.orm import joinedload
		from sqlalchemy.orm.strategy_options import Load

		# circular import is guarded by function
		from . import Room, RoomListing, Occupancy

		# this should autoload all the subplaces of this place
		descendant_places = (object_session(self)
			.query(Place)
			.filter(Place.id == self.id)
			.cte(name='descendant_places', recursive=True)
		)
		descendant_places = descendant_places.union_all(
			object_session(self).query(Place).filter(Place.parent_id == descendant_places.c.id)
		)

		# make this not ridiculously slow
		opts = (
			Load(Room)
				.joinedload(Room.listing_for)
				.joinedload(RoomListing.occupancies)
				.load_only(Occupancy.resident_id),
			Load(Room)
				.joinedload(Room.listing_for)
				.subqueryload(RoomListing.audience_types),
			Load(Room)
				.joinedload(Room.listing_for)
				.undefer(RoomListing.bad_listing),
			Load(Room)
				.subqueryload(Room.stats)
		)

		return object_session(self).query(Room).join(descendant_places).options(*opts)

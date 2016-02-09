from sqlalchemy import Column, ForeignKey
from sqlalchemy.types import (
	Boolean,
	Enum,
	Integer,
	Unicode
)
from sqlalchemy.orm import relationship

from . import Base, Cluster

RoomView = Enum(
	"Overlooking a street",
	"Overlooking a court or garden",
	name='room_view_type'
)

class Room(Base):
	""" A physical room, with time-invariant properties """
	__tablename__ = 'rooms'

	id        = Column(Integer,                         primary_key=True)
	name      = Column(Unicode(255),                    nullable=False)
	parent_id = Column(Integer, ForeignKey(Cluster.id), nullable=False)

	is_set     = Column(Boolean)
	is_ensuite = Column(Boolean)

	bedroom_x = Column(Integer)
	bedroom_y = Column(Integer)
	bedroom_view = Column(RoomView)

	living_room_x = Column(Integer)
	living_room_y = Column(Integer)
	living_room_view = Column(RoomView)

	size_imported = Column(Boolean)

	has_piano     = Column(Boolean)
	has_washbasin = Column(Boolean)
	has_eduroam   = Column(Boolean)
	has_uniofcam  = Column(Boolean)
	has_ethernet  = Column(Boolean)

	parent   = relationship(lambda: Cluster, backref="rooms", lazy='joined')

	@property
	def geocoords(self):
		current = self.parent
		while current:
			if current.latitude and current.longitude:
				return current.latitude, current.longitude
			current = current.parent

	def pretty_name(self, relative_to=None):
		"""
		Produce a pretty name relative to a Cluster. Traversing down the tree
		of Clusters, changing `relative_to` as we go gives:

			1 Mortimer road, Room 5
			House 1, Room 5
			Room 5

		or

			Tree court, S5
			S5
			Room 5
		"""
		def get_parent(x):
			if x.parent == relative_to:
				return None
			return x.parent

		name = self.name
		parent = get_parent(self)

		if parent and parent.type == 'staircase':
			name = parent.name + name
			parent = get_parent(parent)
		else:
			name = "Room {}".format(name)

		if parent:
			return "{}, {}".format(parent.pretty_name(relative_to), name)
		else:
			return name

	def __repr__(self):
		return "<Room: {}>".format(self.pretty_name())
"""
Notation:

 * `><` - Many to many
 * `>-` - Many to one
 * `-<` - One to many
 * `--` - One to one

Relationships:

  RoomListing -- (Room >< Ballot)

  RoomListing -< Occupancy...

  Occupancy >- User
  Occupancy -< Review...
  Occupancy -< Photo...

  Review -< ReviewSection...
  ReviewSection >- ReviewHeading

  Room >- Cluster

  Cluster >- Cluster
"""
import datetime

from sqlalchemy import Column, ForeignKey, UniqueConstraint
from sqlalchemy import (
	Boolean,
	Date,
	DateTime,
	Enum,
	Float,
	Integer,
	Numeric,
	SmallInteger,
	String,
	Text,
)
from sqlalchemy.orm import relationship, backref, column_property, composite
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql.expression import select, extract, case

# we share a DB with the gcsu, so use a unique prefix
prefix = '_room_picks_'

Base = declarative_base()

CRSID = String(10)

class Person(Base):
	__tablename__ = prefix + 'people'

	crsid   = Column(CRSID,  primary_key=True)
	name    = Column(String(255))

class Cluster(Base):
	""" (nestable) Groups of nearby physical rooms """
	__tablename__ = prefix + 'clusters'

	id         = Column(Integer,                         primary_key=True)
	name       = Column(String(255),                     nullable=False)
	parent_id  = Column(Integer, ForeignKey(id))
	type       = Column(Enum("staircase", "building", "road"))

	latitude  = Column(Float)
	longitude = Column(Float)

	parent = relationship(lambda: Cluster, backref="children", remote_side=[id])

	__table_args__ = (UniqueConstraint(parent_id, name, name='_child_name_uc'),)

	@property
	def path(self):
		if self.parent is None:
			return [self]
		else:
			return self.parent.path + [self]

	def __repr__(self):
		return "<Cluster {}>".format(' / '.join(c.name for c in self.path))

	def pretty_name(self, relative_to=None):
		"""
		Produce a pretty name relative to a Cluster. Traversing down the tree
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


RoomView = Enum(
	"Overlooking a street",
	"Overlooking a court or garden"
)

class Room(Base):
	""" A physical room, with time-invariant properties """
	__tablename__ = prefix + 'rooms'

	id        = Column(Integer,                         primary_key=True)
	name      = Column(String(255),                     nullable=False)
	parent_id = Column(Integer, ForeignKey(Cluster.id), nullable=False)

	is_suite  = Column(Boolean)

	bedroom_x = Column(Integer)
	bedroom_y = Column(Integer)
	bedroom_view = Column(RoomView)

	living_room_x = Column(Integer)
	living_room_y = Column(Integer)
	living_room_view = Column(RoomView)

	listings = relationship(lambda: RoomListing, backref="room")
	parent   = relationship(lambda: Cluster,     backref="rooms")

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


class Ballot(Base):
	""" A ballot event """
	__tablename__ = prefix + 'ballots'

	id               = Column(Integer, primary_key=True)
	opens_at         = Column(Date)
	closes_at        = Column(Date)
	type             = Column(Enum('ugrad', '4th', 'grad'), nullable=False)
	is_reconstructed = Column(Boolean, default=False, nullable=False)

	room_listings = relationship(lambda: RoomListing, backref="ballot")

	rental_year = column_property(
		extract('year', opens_at) + case(whens=[
			(extract('month', opens_at) > 8, 1)
		], else_=0)
	)

	def __repr__(self):
		return "<Ballot for {} ({})>".format(self.rental_year, self.type)


class RoomListing(Base):
	""" A listing of a room within a ballot, with time-variant properties """
	__tablename__ = prefix + 'ballot_room'

	id        = Column(Integer, primary_key=True)
	ballot_id = Column(Integer, ForeignKey(Ballot.id))
	room_id   = Column(Integer, ForeignKey(Room.id))

	rent          = Column(Numeric(6, 2))
	has_piano     = Column(Boolean)
	has_washbasin = Column(Boolean)
	has_eduroam   = Column(Boolean)
	has_uniofcam  = Column(Boolean)
	has_ethernet  = Column(Boolean)

	__table_args__ = (UniqueConstraint(ballot_id, room_id, name='_ballot_room_uc'),)


class Occupancy(Base):
	__tablename__ = prefix + 'occupancies'

	id          = Column(Integer,                             primary_key=True)
	resident_id = Column(CRSID,   ForeignKey(Person.crsid))
	listing_id  = Column(Integer, ForeignKey(RoomListing.id), nullable=False)
	chosen_at   = Column(DateTime)

	listing     = relationship(lambda: RoomListing, backref="occupancies")
	resident    = relationship(lambda: Person, backref="occupancies")
	reviews     = relationship(lambda: Review,   backref="occupancy", order_by=lambda: Review.published_at)

	__table_args__ = (UniqueConstraint(resident_id, listing_id, name='_resident_listing_uc'),)

class Review(Base):
	__tablename__ = prefix + 'reviews'

	id           = Column(Integer, primary_key=True)
	published_at = Column(DateTime)
	rating       = Column(SmallInteger)
	occupancy_id = Column(Integer, ForeignKey(Occupancy.id), nullable=False)

	sections     = relationship(lambda: ReviewSection, backref='review', order_by=lambda: ReviewSection._order)


	def __repr__(self):
		return "<Review(published_at={}, title={})>".format(self.published_at, self.title)


class ReviewHeading(Base):
	""" A heading within a review """
	__tablename__ = prefix + 'review_headings'

	id       = Column(Integer,     primary_key=True)
	name     = Column(String(255), nullable=False)
	position = Column(Integer,     nullable=False)
	prompt   = Column(Text)


class ReviewSection(Base):
	""" A heading within a review """
	__tablename__ = prefix + 'review_sections'

	review_id  = Column(Integer, ForeignKey(Review.id),        primary_key=True, nullable=False)
	heading_id = Column(Integer, ForeignKey(ReviewHeading.id), primary_key=True, nullable=False)
	content    = Column(Text)

	heading = relationship(lambda: ReviewHeading)

	_order = column_property(
		select([ReviewHeading.position]).where(ReviewHeading.id == heading_id)
	)

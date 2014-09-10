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

  Room >- Group

  Group >- Group
"""
from sqlalchemy import Column, ForeignKey, UniqueConstraint
from sqlalchemy import (
	Boolean,
	Date,
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
from sqlalchemy.sql.expression import select

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

	id        = Column(Integer,                         primary_key=True)
	name      = Column(String(255),                     nullable=False)
	parent_id = Column(Integer, ForeignKey(id))

	type      = Column(Enum("Corridor", "Staircase", "House", "Other"))

	latitude  = Column(Float)
	longitude = Column(Float)

	parent = relationship(lambda: Cluster, backref="children")



class Room(Base):
	""" A physical room, with time-invariant properties """
	__tablename__ = prefix + 'rooms'

	id        = Column(Integer,                         primary_key=True)
	name      = Column(String(255),                     nullable=False)
	parent_id = Column(Integer, ForeignKey(Cluster.id), nullable=False)

	is_suite  = Column(Boolean)

	listings = relationship(lambda: RoomListing, backref="room")
	parent   = relationship(lambda: Cluster,     backref="rooms")


class Ballot(Base):
	""" A ballot event """
	__tablename__ = prefix + 'ballots'

	id        = Column(Integer, primary_key=True)
	name      = Column(String(255))
	opens_at  = Column(Date)
	closes_at = Column(Date)

	room_listings = relationship(lambda: RoomListing, backref="ballot")


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

	id          = Column(Integer,                           primary_key=True)
	resident_id = Column(CRSID, ForeignKey(Person.crsid),   nullable=False)
	listing_id  = Column(CRSID, ForeignKey(RoomListing.id), nullable=False)

	listing     = relationship(lambda: RoomListing, backref="occupancies")
	resident    = relationship(lambda: Resident, backref="occupancies")
	reviews     = relationship(lambda: Review,   backref="occupancy", order_by=lambda: Review.published_at)

	__table_args__ = (UniqueConstraint(resident_id, listing_id, name='_resident_listing_uc'),)

class Review(Base):
	__tablename__ = prefix + 'reviews'

	id           = Column(Integer, primary_key=True)
	published_at = Column(Date)
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
	prompt   = Column(Text,        nullable=False)


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

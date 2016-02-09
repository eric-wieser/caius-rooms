import datetime
import os

from sqlalchemy import Table, Column, ForeignKey, UniqueConstraint, ForeignKeyConstraint
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
	Unicode,
	UnicodeText,
)
from sqlalchemy import func
from sqlalchemy.orm import relationship, backref, column_property, aliased, join, outerjoin
from sqlalchemy.orm.session import object_session
from sqlalchemy.orm.collections import attribute_mapped_collection
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.sql.expression import select, extract, case, exists

from . import Base, Person, CRSID

class Cluster(Base):
	""" (nestable) Groups of nearby physical rooms """
	__tablename__ = 'clusters'

	id         = Column(Integer,                         primary_key=True)
	name       = Column(Unicode(255),                    nullable=False)
	parent_id  = Column(Integer, ForeignKey(id))
	type       = Column(Enum("staircase", "building", "road", name='cluster_type'))

	latitude  = Column(Float)
	longitude = Column(Float)

	parent = relationship(lambda: Cluster,
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

		# this should autoload all the subclusters of this cluster
		descendant_clusters = (object_session(self)
			.query(Cluster)
			.filter(Cluster.id == self.id)
			.cte(name='descendant_clusters', recursive=True)
		)
		descendant_clusters = descendant_clusters.union_all(
			object_session(self).query(Cluster).filter(Cluster.parent_id == descendant_clusters.c.id)
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

		return object_session(self).query(Room).join(descendant_clusters).options(*opts)

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

	listing_for = relationship(
		lambda: RoomListing,
		collection_class=attribute_mapped_collection('ballot_season')
	)

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

from .ballot import BallotEvent, BallotSeason, BallotType, BallotSlot


class RoomListing(Base):
	""" A listing of a room within a ballot, with time-variant properties """
	__tablename__ = 'room_listings'

	id               = Column(Integer, primary_key=True)
	ballot_season_id = Column(Integer, ForeignKey(BallotSeason.year), nullable=False, index=True)
	room_id          = Column(Integer, ForeignKey(Room.id, onupdate="cascade"), nullable=False, index=True)

	rent          = Column(Numeric(6, 2))

	room           = relationship(lambda: Room, backref=backref("listings", lazy='subquery', order_by=ballot_season_id.desc()))
	ballot_season  = relationship(
		lambda: BallotSeason,
		backref=backref(
			"room_listings",
			cascade='all, delete-orphan'),
		lazy="joined")
	audience_types = relationship(lambda: BallotType,
		secondary=lambda: room_listing_audiences_assoc,
		backref="all_time_listings",
		collection_class=set)

	def __repr__(self):
		return "<RoomListing(ballot_season_id={!r}, room={!r})>".format(
			self.ballot_season_id, self.room
		)

	__table_args__ = (UniqueConstraint(ballot_season_id, room_id, name='_ballot_room_uc'),)

room_listing_audiences_assoc = Table('room_listing_audiences',	Base.metadata,
	Column('id',              Integer, primary_key=True),
	Column('room_listing_id', Integer, ForeignKey(RoomListing.id), nullable=False),
	Column('ballot_type_id',  Integer, ForeignKey(BallotType.id), nullable=False),
	UniqueConstraint('room_listing_id', 'ballot_type_id', name='_listing_type_uc')
)

class Occupancy(Base):
	__tablename__ = 'occupancies'

	id          = Column(Integer,                             primary_key=True)
	resident_id = Column(CRSID,   ForeignKey(Person.crsid))
	listing_id  = Column(Integer, ForeignKey(RoomListing.id), nullable=False, index=True)
	chosen_at   = Column(DateTime)

	cancelled   = Column(Boolean, nullable=False, default=False)

	listing     = relationship(
		lambda: RoomListing,
		backref=backref("occupancies", cascade="all, delete-orphan", lazy='subquery', order_by=chosen_at.desc())
	)
	resident    = relationship(lambda: Person, backref="occupancies", lazy='joined')
	reviews     = relationship(lambda: Review, cascade='all, delete-orphan', backref="occupancy", order_by=lambda: Review.published_at.desc())
	photos      = relationship(lambda: Photo,  backref="occupancy", order_by=lambda: Photo.published_at.desc())

	__table_args__ = (UniqueConstraint(resident_id, listing_id, name='_resident_listing_uc'),)

	def __repr__(self):
		return "<Occupancy(resident_id={!r}, listing={!r})>".format(
			self.resident_id, self.listing
		)

class Review(Base):
	__tablename__ = 'reviews'

	id           = Column(Integer,  primary_key=True)
	published_at = Column(DateTime, nullable=False)
	rating       = Column(SmallInteger)
	occupancy_id = Column(Integer, ForeignKey(Occupancy.id), nullable=False, index=True)
	editor_id    = Column(CRSID, ForeignKey(Person.crsid), nullable=True)
	hidden       = Column(Boolean, nullable=False, default=False)

	sections     = relationship(lambda: ReviewSection, cascade='all, delete-orphan', backref='review', order_by=lambda: ReviewSection._order)
	editor       = relationship(lambda: Person, backref="edited_reviews")

	def contents_eq(self, other):
		"""
		Returns true if the textual contents of two reviews are the same. Does
		not care about reviewer, date, or room
		"""
		if self.rating != other.rating:
			return False

		if len(self.sections) != len(other.sections):
			return False

		self_sections = sorted(self.sections, key=lambda s: s.heading.position)
		other_sections = sorted(other.sections, key=lambda s: s.heading.position)

		for ss, so in zip(self_sections, other_sections):
			if ss.heading != so.heading:
				return False
			if ss.content != so.content:
				return False

		return True

# a mapping of (Person, BallotSeason) -> datetime, used to detect balloted slots
resident_year_to_first_occ_ts_s = select([
	Person.crsid.label('person'),
	BallotSeason.year.label('season'),
	func.min(Occupancy.chosen_at).label('ts')
]).select_from(
	join(Occupancy, RoomListing).join(BallotSeason).join(Person)
).group_by(BallotSeason.year, Person.crsid).correlate(None).alias()

# this occupancy was the first one
Occupancy.is_first = column_property(
	select([
		Occupancy.chosen_at == resident_year_to_first_occ_ts_s.c.ts
	])
	.where(
		(resident_year_to_first_occ_ts_s.c.person == Occupancy.resident_id) &
		(resident_year_to_first_occ_ts_s.c.season == RoomListing.ballot_season_id) &
		(Occupancy.listing_id == RoomListing.id)
	)
)


# a mapping of Occupancy to BallotSlot in which it was booked
occ_to_slot_s = select([
	Occupancy.id.label('occupancy_id'),
	BallotSlot.id.label('ballotslot_id')
]).select_from(
	join(Occupancy, RoomListing).join(BallotSeason).join(BallotEvent).join(BallotSlot)
).where(
	(Occupancy.resident_id == BallotSlot.person_id) &
	Occupancy.is_first
).correlate(None).alias()


Occupancy.ballot_slot = relationship(
	BallotSlot,
	viewonly=True,
	backref=backref('choice', uselist=False),
	uselist=False,

	secondary=occ_to_slot_s,
	primaryjoin=Occupancy.id == occ_to_slot_s.c.occupancy_id,
	secondaryjoin=BallotSlot.id == occ_to_slot_s.c.ballotslot_id
)


# These must be imported for the various lambda functions above
# However, these files also make use of the above delcarations, so to allow
# circular imports, must appear last
from reviewcontent import ReviewSection
from photo import Photo

# Furthermore, all of the below declarations appear to invoke the mapper. This
# causes all the lambdas above to be invoked
# So everything has to be imported first!

r = aliased(Review)
Review.is_newest = column_property(
	select([
		Review.published_at == func.max(r.published_at)
	])
	.select_from(r)
	.where(r.occupancy_id == Review.occupancy_id)
)

bs = aliased(BallotSlot)
BallotSlot.ranking = column_property(
	select([func.count()])
		.select_from(bs)
		.where(bs.event_id == BallotSlot.event_id)
		.where(bs.time <= BallotSlot.time)
)

RoomListing.bad_listing = column_property(
	~RoomListing.audience_types.any() & ~RoomListing.occupancies.any(), deferred=True
)

Occupancy.review = relationship(
	lambda: Review,
	viewonly=True,
	uselist=False,
	primaryjoin=(Review.occupancy_id == Occupancy.id) & Review.is_newest
)



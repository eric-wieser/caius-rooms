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

from . import Base, Person, CRSID, Cluster, Room, BallotEvent, BallotSeason, BallotType, BallotSlot, RoomListing

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



from sqlalchemy import Column, ForeignKey, UniqueConstraint
from sqlalchemy.types import (
	Boolean,
	DateTime,
	Integer
)
from sqlalchemy import func
from sqlalchemy.orm import relationship, backref, column_property, join
from sqlalchemy.sql.expression import select

from . import Base, Person, CRSID, BallotEvent, BallotSeason, BallotSlot, RoomListing

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

	__table_args__ = (UniqueConstraint(resident_id, listing_id, name='_resident_listing_uc'),)

	def __repr__(self):
		return "<Occupancy(resident_id={!r}, listing={!r})>".format(
			self.resident_id, self.listing
		)

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


RoomListing.bad_listing = column_property(
	~RoomListing.audience_types.any() & ~RoomListing.occupancies.any(), deferred=True
)

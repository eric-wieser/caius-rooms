from sqlalchemy import Table, Column, ForeignKey, UniqueConstraint
from sqlalchemy.types import (
    Integer,
    Numeric
)
from sqlalchemy.orm import relationship, backref
from sqlalchemy.orm.collections import attribute_mapped_collection

from . import Base, Room, BallotSeason, BallotType, RoomBand, RoomBandModifier, RoomBandPrice, RoomBandModifierPrice

class RoomListing(Base):
    """ A listing of a room within a ballot, with time-variant properties """
    __tablename__ = 'room_listings'

    id               = Column(Integer, primary_key=True)
    ballot_season_id = Column(Integer, ForeignKey(BallotSeason.year), nullable=False, index=True)
    room_id          = Column(Integer, ForeignKey(Room.id, onupdate="cascade"), nullable=False, index=True)
    band_id          = Column(Integer, ForeignKey(RoomBand.id), nullable=True)

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

    band = relationship(lambda: RoomBand, lazy='subquery', backref=backref("listings", lazy='subquery', order_by=ballot_season_id.desc()))
    modifiers = relationship(lambda: RoomBandModifier,
        secondary=lambda: room_listing_modifiers_assoc,
        backref="all_time_listings",
        lazy='subquery',
        collection_class=set)

    # this property is only used for the side effects
    _room = relationship(lambda: Room,
        backref=backref(
            "listing_for",
            collection_class=attribute_mapped_collection('ballot_season')
        )
    )

    def __repr__(self):
        return "<RoomListing(ballot_season_id={!r}, room={!r})>".format(
            self.ballot_season_id, self.room
        )

    __table_args__ = (UniqueConstraint(ballot_season_id, room_id, name='_ballot_room_uc'),)


room_listing_audiences_assoc = Table('room_listing_audiences',  Base.metadata,
    Column('id',              Integer, primary_key=True),
    Column('room_listing_id', Integer, ForeignKey(RoomListing.id), nullable=False),
    Column('ballot_type_id',  Integer, ForeignKey(BallotType.id), nullable=False),
    UniqueConstraint('room_listing_id', 'ballot_type_id', name='_listing_type_uc')
)

room_listing_modifiers_assoc = Table('room_listing_modifiers',  Base.metadata,
    Column('id',               Integer, primary_key=True),
    Column('room_listing_id',  Integer, ForeignKey(RoomListing.id), nullable=False),
    Column('band_modifier_id', Integer, ForeignKey(RoomBandModifier.id), nullable=False),
    UniqueConstraint('room_listing_id', 'band_modifier_id', name='_listing_modifier_uc')
)

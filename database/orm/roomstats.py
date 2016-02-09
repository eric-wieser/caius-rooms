from sqlalchemy import Table, Column, ForeignKey, UniqueConstraint, ForeignKeyConstraint
from sqlalchemy import func
from sqlalchemy.orm import relationship, column_property, aliased, join, outerjoin
from sqlalchemy.sql.expression import select

from . import Base, Occupancy, Photo, RoomListing, Review, ReviewRoomReference, Room, ReviewSection

class RoomStats(Base):
    # http://fulmicoton.com/posts/bayesian_rating/
    C = 0.5 # closeness function
    M = 5.5 # mean rating

    __table__ = select([
        Room.id
            .label('room_id'),
        func.count(func.distinct(Occupancy.resident_id))
            .label('resident_count'),
        func.count(Review.id)
            .label('review_count'),
        func.count(Review.rating)
            .label('rating_count'),
        ((M*C + func.sum(Review.rating)) / (C + func.count(Review.rating))
            ).label('adjusted_rating')
    ]).select_from(
        outerjoin(Room, RoomListing).outerjoin(Occupancy)
            .outerjoin(Review)
    ).where(
        (Review.id == None) | (Review.is_newest & ~Review.hidden)
    ).group_by(Room.id).alias(name='room_stats')

Room.stats = relationship(
    RoomStats,
    uselist=False,
    primaryjoin=RoomStats.room_id == Room.id,
    foreign_keys=RoomStats.room_id
)

RoomStats.photo_count = column_property(
    select([func.count(Photo.id)])
    .select_from(
        join(Photo, Occupancy)
            .join(RoomListing)
            .join(Room)
    )
    .where(RoomStats.room_id == Room.id)
)
RoomStats.reference_count = column_property(
    select([func.count(ReviewRoomReference.id)])
    .select_from(
        join(ReviewRoomReference, ReviewSection)
            .join(Review)
            .join(Occupancy)
            .join(RoomListing)
    )
    .where(RoomStats.room_id == ReviewRoomReference.room_id)
    .where(Review.is_newest & ~Review.hidden)
    .where(RoomStats.room_id != RoomListing.room_id)  # filter self-references
)

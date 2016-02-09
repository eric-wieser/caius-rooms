from sqlalchemy import Table, Column, ForeignKey, UniqueConstraint, ForeignKeyConstraint
from sqlalchemy.types import (
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
from sqlalchemy.orm import relationship, column_property

from .base import Base

class BallotType(Base):
	""" A type of ballot """
	__tablename__ = 'ballot_types'

	id   = Column(Integer, primary_key=True)
	name = Column(Unicode(255))

	def __repr__(self):
		return "BallotType(name={})".format(self.name)


class BallotSeason(Base):
	""" A year in which a ballot occurs """
	__tablename__ = 'ballot_seasons'

	year          = Column(Integer, primary_key=True)

	def __repr__(self):
		return "BallotSeason(year={})".format(self.year)

	def __str__(self):
		return u"{} \u2012 {}".format(self.year, self.year+1)


class BallotEvent(Base):
	__tablename__ = 'ballot_events'

	id        = Column(Integer, primary_key=True)
	type_id   = Column(Integer, ForeignKey(BallotType.id),     nullable=False)
	season_id = Column(Integer, ForeignKey(BallotSeason.year), nullable=False)
	opens_at  = Column(Date)
	closes_at = Column(Date)

	is_active = column_property((opens_at < func.now()) & (func.now() < closes_at))

	type      = relationship(lambda: BallotType,   backref="events", lazy="joined")
	season    = relationship(lambda: BallotSeason, backref="events", lazy="joined")

	__table_args__ = (UniqueConstraint(type_id, season_id, name='_season_type_uc'),)

	def __repr__(self):
		return "<BallotEvent(year={!r}, type={!r}, ...)>".format(self.season.year, self.type.name)

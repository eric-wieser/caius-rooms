from sqlalchemy import Column, ForeignKey, UniqueConstraint
from sqlalchemy.types import (
	Date,
	DateTime,
	Integer,
	Unicode,
	String,
	UnicodeText,
	Numeric
)
from sqlalchemy import func
from sqlalchemy.orm import relationship, backref, column_property, aliased
from sqlalchemy.orm.collections import attribute_mapped_collection
from sqlalchemy.sql.expression import select

from . import Base, BallotSeason


class RoomBand(Base):
	""" A band which rent price is chosen according to """
	__tablename__ = 'room_bands'

	id   = Column(Integer, primary_key=True)
	name = Column(Unicode(255), nullable=False)
	color = Column(String(6), nullable=False)
	description = Column(UnicodeText, nullable=False)

	def __repr__(self):
		return "RoomBand(name={!r})".format(self.name)


class RoomBandModifier(Base):
	""" A band which rent price is chosen according to """
	__tablename__ = 'room_band_modifiers'

	id   = Column(Integer, primary_key=True)
	name = Column(Unicode(255), nullable=False)
	description = Column(UnicodeText, nullable=False)

	def __repr__(self):
		return "RoomBand(name={!r})".format(self.name)


class RoomBandPrice(Base):
	""" Band prices for a given year """
	__tablename__ = 'room_band_prices'


	band_id   = Column(Integer, ForeignKey(RoomBand.id),     primary_key=True, nullable=False)
	season_id = Column(Integer, ForeignKey(BallotSeason.year), primary_key=True, nullable=False)

	season    = relationship(lambda: BallotSeason, backref="band_prices")
	band      = relationship(lambda: RoomBand, backref="prices")

	rent = Column(Numeric(6,2), nullable=False)

	def __repr__(self):
		return "RoomBandPrice({!r}, rent={})".format(self.band.name, self.rent)

class RoomBandModifierPrice(Base):
	""" Band prices for a given year """
	__tablename__ = 'room_band_modifier_prices'


	modifier_id = Column(Integer, ForeignKey(RoomBandModifier.id),     primary_key=True, nullable=False)
	season_id   = Column(Integer, ForeignKey(BallotSeason.year), primary_key=True, nullable=False)

	season    = relationship(lambda: BallotSeason, backref="modifier_prices")
	modifier  = relationship(lambda: RoomBandModifier, backref="prices")

	discount = Column(Numeric(6,2), nullable=False)

	def __repr__(self):
		return "RoomBandModifierPrice({!r}, discount={})".format(self.modifier.name, self.discount)



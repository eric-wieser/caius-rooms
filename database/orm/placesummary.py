from sqlalchemy import Column, ForeignKey
from sqlalchemy.types import (
	Boolean,
	DateTime,
	Integer,
	SmallInteger,
	UnicodeText
)
from sqlalchemy import func
from sqlalchemy.orm import relationship, backref, column_property, aliased
from sqlalchemy.sql.expression import select

from . import Base, Person, CRSID, Place

class PlaceSummary(Base):
	__tablename__ = 'place_summaries'

	id           = Column(Integer,  primary_key=True)
	published_at = Column(DateTime, nullable=False)
	place_id     = Column(Integer, ForeignKey(Place.id), nullable=False, index=True)
	editor_id    = Column(CRSID, ForeignKey(Person.crsid), nullable=True)
	hidden       = Column(Boolean, nullable=False, default=False)

	editor       = relationship(lambda: Person, backref="edited_summaries")

	place        = relationship(lambda: Place, backref=backref(
		"summaries",
		cascade='all, delete-orphan',
		order_by=lambda: PlaceSummary.published_at.desc()
	))

	markdown_content = Column(UnicodeText, nullable=False)

ps = aliased(PlaceSummary)
PlaceSummary.is_newest = column_property(
	select([
		PlaceSummary.published_at == func.max(ps.published_at)
	])
	.select_from(ps)
	.where(ps.place_id == PlaceSummary.place_id)
)


Place.summary = relationship(
	lambda: PlaceSummary,
	viewonly=True,
	uselist=False,
	primaryjoin=(PlaceSummary.place_id == Place.id) & PlaceSummary.is_newest
)



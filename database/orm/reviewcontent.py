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

from . import Base
from .others import Review, Room  # circular import

class ReviewHeading(Base):
	""" A heading within a review """
	__tablename__ = 'review_headings'

	id         = Column(Integer,      primary_key=True)
	name       = Column(Unicode(255), nullable=False)
	is_summary = Column(Boolean,      nullable=False, default=False)
	position   = Column(Integer,      nullable=False)
	prompt     = Column(UnicodeText)


class ReviewSection(Base):
	""" A section of content within a review """
	__tablename__ = 'review_sections'

	review_id  = Column(Integer, ForeignKey(Review.id),        primary_key=True, nullable=False)
	heading_id = Column(Integer, ForeignKey(ReviewHeading.id), primary_key=True, nullable=False)
	content    = Column(UnicodeText)

	heading = relationship(lambda: ReviewHeading, lazy='joined')

	_order = column_property(
		select([ReviewHeading.position]).where(ReviewHeading.id == heading_id)
	)

	@property
	def tokens(self):
		""" Tokenize the text into refs and non-refs """
		from itertools import groupby

		last_idx = 0

		for start_idx, refs in groupby(self.refers_to, lambda r: r.start_idx):
			if start_idx < last_idx:
				raise ValueError

			refs = list(refs)
			end_idx = max(r.end_idx for r in refs)

			yield self.content[last_idx:start_idx], []

			yield self.content[start_idx:end_idx], refs

			last_idx = end_idx

		yield self.content[last_idx:], []

	def html_content(self, current_room=None):
		from bottle import html_escape
		from utils import url_for

		html = ""

		for text, refs in self.tokens:
			text = html_escape(text)
			# highlight matching reference in bold
			if any(ref.room_id == current_room.id for ref in refs):
				text = '<b>{text}</b>'.format(text=text)

			# link non-self single refs
			if len(refs) == 1 and refs[0].room_id != current_room.id:
				text = '<a href="{url}">{text}</a>'.format(
					url=url_for(refs[0].room),
					text=text
				)

			# link all multirefs
			elif len(refs) > 1:
				text = '<a href="{url}">{text}</a>'.format(
					url=url_for('/rooms', qs={
						'filter_id': ','.join(str(ref.room_id) for ref in refs)
					}),
					text=text
				)

			html += text

		return ''.join('<p>' + line.replace('\n', '<br />') + '</p>' for line in html.split('\n\n'))


class ReviewRoomReference(Base):
	"""
	A reference to a room within the text of a review. One piece of text can
	refer to multiple rooms. Location of the reference is stored to enable
	linking
	"""
	__tablename__ = 'review_room_reference'

	id = Column(Integer, primary_key=True)

	review_id = Column(Integer, nullable=False)
	review_heading_id = Column(Integer, nullable=False)
	room_id = Column(Integer, ForeignKey(Room.id, onupdate="cascade"), nullable=False)

	start_idx = Column(Integer)
	end_idx = Column(Integer)

	__table_args__ = (
		ForeignKeyConstraint([review_id,               review_heading_id],
                             [ReviewSection.review_id, ReviewSection.heading_id]),
    )

	review_section = relationship(
		lambda: ReviewSection,
		backref=backref(
			'refers_to',
			lazy="joined",
			order_by=start_idx,
			cascade='all, delete-orphan'
		),
	)
	room = relationship(lambda: Room, backref='references')

"""
Notation:

 * `><` - Many to many
 * `>-` - Many to one
 * `-<` - One to many
 * `--` - One to one

Relationships:

  BallotSeason -< BallotEvent

  BallotEvent >- BallotType

  RoomListing -< BallotType

  RoomListing -< Occupancy...

  RoomListing -- (Room >< BallotSeason)

  Occupancy >- User
  Occupancy -< Review...
  Occupancy -< Photo...

  Review -< ReviewSection...
  ReviewSection >- ReviewHeading

  Room >- Cluster

  Cluster >- Cluster
"""
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
from sqlalchemy.sql.expression import select, extract, case
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

CRSID = String(10)

class Person(Base):
	__tablename__ = 'people'

	crsid     = Column(CRSID,  primary_key=True)
	name      = Column(Unicode(255))
	last_seen = Column(DateTime)
	is_admin  = Column(Boolean, default=False, nullable=False)

	def __repr__(self):
		return "<Person(crsid={!r}, name={!r})>".format(self.crsid, self.name)

	@property
	def email(self):
		return '{}@cam.ac.uk'.format(self.crsid.lower())

	def gravatar(self, size=None):
		from hashlib import md5
		return 'http://www.gravatar.com/avatar/{}?d=identicon{}'.format(
			md5(self.email).hexdigest(),
			'&s={}'.format(size) if size else ''
		)

	@property
	def active_ballot_events(self):
		if not object_session(self):
			return {}

		all_events = object_session(self).query(BallotEvent).filter(BallotEvent.is_active).all()

		return { e: self.slot_for.get(e) for e in all_events }

	@property
	def current_room(self):
		# get the ballot year where current rooms were assigned
		from datetime import datetime
		now = datetime.now()
		if now.month >= 10:
			year = now.year
		else:
			year = now.year - 1

		# find all rooms owned in the current year
		occs = [occ for occ in self.occupancies if occ.listing.ballot_season.year == year]

		if not occs:
			return

		return max(occs, key=lambda o: o.chosen_at).listing.room

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
		remote_side=[id],
		lazy="joined",
		join_depth=4)

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
		from sqlalchemy.orm.strategy_options import Load
		l1 = aliased(Cluster)
		l2 = aliased(Cluster)
		l3 = aliased(Cluster)
		l4 = aliased(Cluster)

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

		rooms = object_session(self).query(Room).options(*opts)

		j1 = rooms.join(l1)
		j2 = j1.join(l2, l1.parent_id == l2.id)
		j3 = j2.join(l3, l2.parent_id == l3.id)
		j4 = j3.join(l4, l3.parent_id == l4.id)

		return (
			j1.filter(l1.id == self.id)
		).union(
			j2.filter(l2.id == self.id),
			j3.filter(l3.id == self.id),
			j4.filter(l4.id == self.id)
		)

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

	type      = relationship(lambda: BallotType,   backref="events")
	season    = relationship(lambda: BallotSeason, backref="events", lazy="joined")

	__table_args__ = (UniqueConstraint(type_id, season_id, name='_season_type_uc'),)

	def __repr__(self):
		return "<BallotEvent(year={!r}, type={!r}, ...)>".format(self.season.year, self.type.name)


class BallotSlot(Base):
	__tablename__ = 'ballot_slots'

	id        = Column(Integer, primary_key=True)
	time      = Column(DateTime)
	person_id = Column(CRSID, ForeignKey(Person.crsid), nullable=False)
	event_id  = Column(Integer, ForeignKey(BallotEvent.id), nullable=False)

	person = relationship(
		lambda: Person,
		backref=backref(
			"slot_for",
			collection_class=attribute_mapped_collection('event'),
			cascade='all, delete-orphan'
		),
		lazy='joined')
	event = relationship(
		lambda: BallotEvent,
		backref=backref("slots", cascade='all, delete-orphan'),
		lazy='joined')

	def __repr__(self):
		return "<BallotSlot(person_id={!r}, event={!r}, time={!r})>".format(
			self.person_id, self.event, self.time
		)


class RoomListing(Base):
	""" A listing of a room within a ballot, with time-variant properties """
	__tablename__ = 'room_listings'

	id               = Column(Integer, primary_key=True)
	ballot_season_id = Column(Integer, ForeignKey(BallotSeason.year), nullable=False, index=True)
	room_id          = Column(Integer, ForeignKey(Room.id, onupdate="cascade"), nullable=False, index=True)

	rent          = Column(Numeric(6, 2))

	room           = relationship(lambda: Room, backref=backref("listings", lazy='subquery', order_by=ballot_season_id.desc()))
	ballot_season  = relationship(lambda: BallotSeason, backref="room_listings", lazy="joined")
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

	listing     = relationship(lambda: RoomListing, backref=backref("occupancies", lazy='subquery', order_by=chosen_at.desc()))
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

	sections     = relationship(lambda: ReviewSection, cascade='all, delete-orphan', backref='review', order_by=lambda: ReviewSection._order)


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

		html = ""

		for text, refs in self.tokens:
			text = html_escape(text)
			# highlight matching reference in bold
			if any(ref.room_id == current_room.id for ref in refs):
				text = '<b>{text}</b>'.format(text=text)

			# link non-self single refs
			if len(refs) == 1 and refs[0].room_id != current_room.id:
				text = '<a href="/rooms/{id}">{text}</a>'.format(
					id=refs[0].room_id,
					text=text
				)

			# link all multirefs
			elif len(refs) > 1:
				text = '<a href="/rooms?filter_id={id}">{text}</a>'.format(
					id=','.join(str(ref.room_id) for ref in refs),
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
		backref=backref('refers_to', order_by=start_idx, cascade='all, delete-orphan'),
	)
	room = relationship(lambda: Room, backref='references')

uploaded_files_path = os.path.abspath(
	os.path.join(
		os.path.dirname(__file__),
		'..',
		'uploaded_files'
	)
)

print uploaded_files_path

#Read: https://research.microsoft.com/pubs/64525/tr-2006-45.pdf
class Photo(Base):
	__tablename__ = 'photos'

	id           = Column(Integer,    primary_key=True)
	published_at = Column(DateTime,   nullable=False)
	caption      = Column(UnicodeText)
	width        = Column(Integer,    nullable=False)
	height       = Column(Integer,    nullable=False)
	mime_type    = Column(String(32), nullable=False)
	# TODO: store image somewhere
	occupancy_id = Column(Integer, ForeignKey(Occupancy.id), nullable=False, index=True)

	@hybrid_property
	def is_panorama(self):
		return self.width > 2.5*self.height

	raw_im = None

	@property
	def href(self):
		return '/photos/{}'.format(self.id)

	@property
	def _extension(self):
		import mimetypes

		# http://bugs.python.org/issue1043134
		common = {
			'text/plain': '.txt',
			'image/jpeg': '.jpg',
			'image/png': '.png'
		}

		return common.get(self.mime_type) or mimetypes.guess_extension(self.mime_type) or ''

	@property
	def storage_path(self):
		filename = '{}{}'.format(self.id, self._extension)

		return os.path.join(uploaded_files_path, self.__tablename__, filename)

	@classmethod
	def from_file(cls, f):
		from PIL import Image
		from datetime import datetime

		im = Image.open(f)
		mime_type = 'image/' + im.format.lower()
		im = im.convert('RGBA')

		# allow wide images for panoramas
		bounds = (1280, 600)
		im_exif = im.info.get('exif')
		im.thumbnail(bounds)
		if im_exif:
			im.info['exif'] = im_exif

		w, h = im.size
		p = cls(
			published_at=datetime.now(),
			mime_type=mime_type,
			width=w,
			height=h
		)

		p.raw_im = im

		return p

	@classmethod
	def _inserted(cls, mapper, connection, target):
		if target.raw_im:
			if target.mime_type == 'image/jpeg' and 'exif' in target.raw_im.info:
				target.raw_im.save(target.storage_path, exif=target.raw_im.info['exif'])
			else:
				target.raw_im.save(target.storage_path)


import sqlalchemy.event
sqlalchemy.event.listen(Photo, 'after_insert', Photo._inserted)


RoomListing.bad_listing = column_property(
	~RoomListing.audience_types.any() & ~RoomListing.occupancies.any(), deferred=True
)
r = aliased(Review)
Review.is_newest = column_property(
	select([
		Review.published_at == func.max(r.published_at)
	])
	.select_from(r)
	.where(r.occupancy_id == Review.occupancy_id)
)

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
	).where((Review.id == None) | Review.is_newest).group_by(Room.id).alias(name='room_stats')

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
	.where(Review.is_newest)
	.where(RoomStats.room_id != RoomListing.room_id)  # filter self-references
)

bs = aliased(BallotSlot)
BallotSlot.ranking = column_property(
	select([func.count()])
		.select_from(bs)
		.where(bs.event_id == BallotSlot.event_id)
		.where(bs.time <= BallotSlot.time)
)


Occupancy.review = relationship(
	lambda: Review,
	viewonly=True,
	uselist=False,
	primaryjoin=(Review.occupancy_id == Occupancy.id) & Review.is_newest
)

o = aliased(Occupancy)
Occupancy.is_first = column_property(
	select([
		Occupancy.chosen_at == func.min(o.chosen_at)
	])
	.select_from(o)
	.where(o.listing_id == Occupancy.listing_id)
)

_se = aliased(BallotSeason)
_oc = aliased(Occupancy)
_sl = aliased(BallotSlot)
Occupancy.ballot_slot = relationship(
	BallotSlot,
	viewonly=True,
	backref=backref('choice', uselist=False),
	uselist=False,

	secondary=join(_oc, RoomListing).join(BallotSeason).outerjoin(BallotEvent).outerjoin(_sl),
	# if we're not the first occupant of this room, then we didn't ballot
	# TODO: add a flag for edited balloters
	primaryjoin=(Occupancy.id == _oc.id) & _oc.is_first,
	secondaryjoin=(BallotSlot.id == _sl.id) & (_sl.person_id == _oc.resident_id)
)

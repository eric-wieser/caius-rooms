import os

from sqlalchemy import Column, ForeignKey
from sqlalchemy.types import (
	DateTime,
	Integer,
	String,
	UnicodeText,
)
from sqlalchemy.orm import relationship, backref
from sqlalchemy.ext.hybrid import hybrid_property

from . import Base, Occupancy

uploaded_files_path = os.path.abspath(
	os.path.join(
		os.path.dirname(__file__),
		'..',
		'..',
		'uploaded_files'
	)
)

#Read: https://research.microsoft.com/pubs/64525/tr-2006-45.pdf
class Photo(Base):
	__tablename__ = 'photos'

	id           = Column(Integer,    primary_key=True)
	published_at = Column(DateTime,   nullable=False)
	caption      = Column(UnicodeText)
	width        = Column(Integer,    nullable=False)
	height       = Column(Integer,    nullable=False)
	mime_type    = Column(String(32), nullable=False)

	occupancy_id = Column(Integer, ForeignKey(Occupancy.id), nullable=False, index=True)

	occupancy    = relationship(lambda: Occupancy, backref=backref("photos", order_by=lambda: Photo.published_at.desc()))

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
				print "Preserved exif!"
				target.raw_im.save(target.storage_path, exif=target.raw_im.info['exif'])
			else:
				target.raw_im.save(target.storage_path)


import sqlalchemy.event
sqlalchemy.event.listen(Photo, 'after_insert', Photo._inserted)

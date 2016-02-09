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

from .base import Base, CRSID

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
        # this needs to be guarded in the function, as it's circular
        from . import BallotEvent

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

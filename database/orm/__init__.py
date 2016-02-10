"""
This module contains the SQLAlchemy mapping definitions, which builds python
classes out of database rows

When adding relationships, care should be taken that it is still possible to
find a non-circular import order - this can be done by flipping which class
declares the relationship using `backref`. In general, the class defining the
foreign key should also declare the relationship.

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

  Room >- Place

  Place >- Place
"""

# these files rely on each other sequentially at import time
from .base import Base, CRSID
from .person import Person
from .ballot import BallotSeason, BallotEvent, BallotType, BallotSlot
from .place import Place
from .room import Room
from .roomlisting import RoomListing
from .occupancy import Occupancy
from .review import Review
from .reviewcontent import ReviewHeading, ReviewSection, ReviewRoomReference
from .photo import Photo
from .roomstats import RoomStats
from .placesummary import PlaceSummary
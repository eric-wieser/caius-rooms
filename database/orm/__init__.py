"""
This module contains the SQLAlchemy mapping definitions, which builds python
classes out of database rows

Due to the heavy interlinking of the different objects, the import order here
is complex and fragile. SQLAlchemy tries to help this by using lambda functions
in some places to delay name evaluations, ie `lambda: ClassName`.

Unfortunately, this makes the behaviour even more complex, as one wrong
function call can invoke all the lambdas before all the modules are declined

Objects left in the `others` module were found to be too entangled to separate


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

# these files rely on each other sequentially
from .base import Base, CRSID
from .person import Person
from .ballot import BallotSeason, BallotEvent, BallotType, BallotSlot
from .cluster import Cluster
from .room import Room
from .roomlisting import RoomListing

# These files interact circularly
from .others import RoomListing, Occupancy, Review
from .reviewcontent import ReviewHeading, ReviewSection, ReviewRoomReference

# sequential again
from .photo import Photo
from .roomstats import RoomStats

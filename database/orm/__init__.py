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

from .base import Base, CRSID
from .person import Person
from .ballot import BallotSeason, BallotEvent, BallotType
from .all import (
	Person, Cluster, Room, BallotSlot,
	RoomListing, Occupancy,
	Review
)
from .reviewcontent import ReviewHeading, ReviewSection, ReviewRoomReference
from .photo import Photo
from .roomstats import RoomStats
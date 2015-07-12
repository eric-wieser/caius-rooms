from datetime import datetime
import database.orm as m

class BookingError(Exception): pass

# failure conditions for booking a room
class NoBallotEvent(BookingError): pass
class NoUser(BookingError): pass

class ListingError(BookingError): pass
class NotListed(ListingError): pass
class ListedForOthers(ListingError):
	def __init__(self, others):
		ListingError.__init__(self)
		self.others = others

class SlotError(BookingError): pass
class NoSlot(SlotError): pass
class SlotUnopened(SlotError): pass
class SlotClosed(SlotError): pass

class OccupancyError(BookingError):
	def __init__(self, occupancy):
		BookingError.__init__(self)
		self.occupancy = occupancy
class RoomAlreadyBooked(OccupancyError): pass
class UserAlreadyBooked(OccupancyError): pass

def check_listing_adequate(user, room, ballot_event):
	if not user:
		raise NoUser
	if not isinstance(ballot_event, m.BallotEvent):
		raise NoBallotEvent

	listing = room.listing_for.get(ballot_event.season)
	if not (listing and listing.audience_types):
		raise NotListed

	if ballot_event.type not in listing.audience_types:
		raise ListedForOthers(set(listing.audience_types))  # copy to prevent modification

	return listing

def check_slot(user, ballot_event, at=None):
	""" Check that user has an open slot for ballot_event """
	at = at or datetime.now()

	slot = user.slot_for.get(ballot_event)
	if not slot:
		raise NoSlot

	if at < slot.time:
		raise SlotUnopened

	if ballot_event.closes_at < at.date():
		raise SlotClosed

def check_occupant_unique(user, listing):
	"""
	Given a user and a listing, this checks whether joining them would break
	the one-to-one mapping

	The Occupancy table should be locked before invoking this
	"""
	user_booked = [
		occ
		for occ in user.occupancies
		if occ.listing.ballot_season == listing.ballot_season
		if not occ.cancelled
	]
	if any(user_booked):
		raise UserAlreadyBooked(max(user_booked, key=lambda o: o.chosen_at))

	room_bookings = [
		occ
		for occ in listing.occupancies
		if not occ.cancelled
	]
	if any(room_bookings):
		raise RoomAlreadyBooked(max(room_bookings, key=lambda o: o.chosen_at))

def check_all(user, room, ballot_event):
	listing = check_listing_adequate(user, room, ballot_event)
	check_occupant_unique(user, listing)
	check_slot(user, ballot_event)

def check_then_book(db, user, room, ballot_event):
	listing = check_listing_adequate(user, room, ballot_event)

	# start locking, to prevent concurrency errors. We need to reload our data to match the lock
	lock_occupancies(db)
	at = datetime.now() # locking time is choice time
	db.refresh(user)
	db.refresh(listing)
	check_occupant_unique(user, listing)

	# don't need the lock for this, but we need to check this afterwards as we
	# want to trigger occupancy errors first, then slot errors
	check_slot(user, ballot_event, at)

	# finally, book the room. We intentionally hold the lock until the transaction is committed
	listing.occupancies.append(
		m.Occupancy(
			resident=user,
			chosen_at=at,
		)
	)

def lock_occupancies(db):
	db.execute('LOCK TABLE {} IN EXCLUSIVE MODE'.format(m.Occupancy.__table__.name))

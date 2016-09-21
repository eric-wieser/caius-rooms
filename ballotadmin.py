from datetime import datetime, timedelta
import csv
import StringIO
import json
import re
import decimal

from bottle import *
from sqlalchemy import func
from sqlalchemy.orm import joinedload, joinedload_all, load_only
from sqlalchemy.orm.strategy_options import Load

from utils import needs_auth, lookup_ldap, add_structure, url_for
import database.orm as m

def add_routes(app):
	@app.route('/<ballot_id:int>/edit-prices', method=['POST', 'GET'])
	@needs_auth('admin')
	def show_ballot_price_edit(ballot_id, db):
		ballot = db.query(m.BallotSeason).filter(m.BallotSeason.year == ballot_id).one()
		# db.make_transient(ballot)
		bands = db.query(m.RoomBand).all()
		modifiers = db.query(m.RoomBandModifier).all()

		if request.method == 'POST':
			postdata = add_structure(request.forms)

			band_prices = ballot.band_prices
			modifier_prices = ballot.modifier_prices

			def do_update():
				for id, obj in postdata['bands'].items():
					try:
						rent = decimal.Decimal(obj['rent'])
					except decimal.DecimalException:
						rent = None
					band = db.query(m.RoomBand).get(id)

					if band:
						price = next((p for p in band_prices if p.band == band), None)
						if rent is not None:
							if price:
								price.rent = rent
							else:
								m.RoomBandPrice(band=band, season=ballot, rent=rent)
						elif price:
							band_prices.remove(price)

				for id, obj in postdata['modifiers'].items():
					try:
						rent = decimal.Decimal(obj['discount'])
					except (decimal.DecimalException, TypeError) as e:
						rent = None
					modifier = db.query(m.RoomBandModifier).get(id)

					if modifier:
						price = next((p for p in modifier_prices if p.modifier == modifier), None)
						if rent is not None:
							if price:
								price.rent = rent
							else:
								m.RoomBandModifierPrice(modifier=modifier, season=ballot, discount=rent)
						elif price:
							modifier_prices.remove(price)

			do_update()
			return redirect(url_for(ballot))
		else:
			return template('ballot-edit-prices', ballot_season=ballot, bands=bands, modifiers=modifiers)

	@app.route('/<ballot_id:int>/band-assignments/edit')
	@needs_auth('admin')
	def show_ballot_band_edit(ballot_id, db):
		ballot = db.query(m.BallotSeason).options(
			joinedload(m.BallotSeason.room_listings)
				.joinedload(m.RoomListing.room)
				.load_only(m.Room.id, m.Room.name, m.Room.parent_id),
			joinedload(m.BallotSeason.room_listings)
				.joinedload(m.RoomListing.room)
				.joinedload(m.Room.parent)
		).filter(m.BallotSeason.year == ballot_id).one()

		db.query(m.Place).all()
		bands = db.query(m.RoomBand).all()
		modifiers = db.query(m.RoomBandModifier).all()

		return template('ballot-band-assignments-edit', ballot_season=ballot, bands=bands, modifiers=modifiers)

	@app.post('/<ballot_id:int>/band-assignments/edit')
	@needs_auth('admin')
	def save_ballot_band_edit(ballot_id, db):
		ballot = db.query(m.BallotSeason).filter(m.BallotSeason.year == ballot_id).one()

		postdata = add_structure(request.forms)
		if postdata['reset'] == '':
			last_ballot = ballot.previous
			if not last_ballot:
				raise HTTPError(400, 'No previous ballot to reset to')

			rooms = db.query(m.Room).options(
				load_only(m.Room.id),
				joinedload(m.Room.listing_for)
			)
			n = 0
			for r in rooms:
				list_new = r.listing_for.get(ballot)
				list_old = r.listing_for.get(last_ballot)

				if list_new and list_old:
					n += 1
					list_new.band = list_old.band
					list_new.modifiers = list_old.modifiers
		else:
			listings = ballot.room_listings

			for id, obj in postdata['listings'].items():
				listing = db.query(m.RoomListing).get(id)
				if not listing or listing.ballot_season != ballot:
					raise HTTPError(400, 'Invalid listing id')

				if obj['band'] != '':
					band_id = int(obj['band'])
					band = db.query(m.RoomBand).get(band_id)
					if not band:
						raise HTTPError(400, 'Invalid band id')

					listing.band = band
				else:
					listing.band = None

				modifier_ids = map(int, obj['modifiers'])
				modifiers = {db.query(m.RoomBandModifier).get(m_id) for m_id in modifier_ids}
				if not all(modifiers):
					raise HTTPError(400, 'Invalid modifier id')

				listing.modifiers = modifiers

		db.commit()
		redirect(url_for(ballot))


	@app.route('/<ballot_id:int>/add-event')
	@needs_auth('admin')
	def show_ballot_event_add(ballot_id, db):
		ballot = db.query(m.BallotSeason).options(
			joinedload(m.BallotSeason.events)
		).filter(m.BallotSeason.year == ballot_id).one()

		event_types = (db
			.query(m.BallotType, m.BallotType.events.any(m.BallotEvent.season == ballot))
			.outerjoin(m.BallotType.events)
		)

		return template('ballot-add-event', ballot_season=ballot, event_types=event_types)

	@app.post('/<ballot_id:int>/add-event')
	@needs_auth('admin')
	def process_ballot_event_add(ballot_id, db):
		ballot = db.query(m.BallotSeason).filter(m.BallotSeason.year == ballot_id).one()
		event_type = db.query(m.BallotType).filter(m.BallotType.id == int(request.forms.type)).one()

		e = m.BallotEvent(
			season=ballot,
			type=event_type,
			opens_at=datetime.strptime(request.forms.opens_at, "%Y-%m-%d").date(),
			closes_at=datetime.strptime(request.forms.closes_at, "%Y-%m-%d").date()
		)

		db.add(e)
		return redirect(app.get_url('show-ballot', ballot_id=ballot_id))



	@app.route('/<ballot_id:int>/<ballot_type_name>/edit', name="edit-ballot-event")
	@needs_auth('admin')
	def show_ballot_control_panel(ballot_id, ballot_type_name, db):
		if ballot_type_name.lower() != ballot_type_name:
			raise redirect(app.get_url(
				'edit-ballot-event',
				ballot_id=ballot_id, ballot_type_name=ballot_type_name.lower()
			))

		ballot_type = db.query(m.BallotType).filter(func.lower(m.BallotType.name) == ballot_type_name.lower()).one()

		ballot_event = (db
			.query(m.BallotEvent)
			.join(m.BallotSeason)
			.filter(m.BallotEvent.type == ballot_type)
			.filter(m.BallotSeason.year == ballot_id)
			.options(
				Load(m.BallotEvent)
					.joinedload(m.BallotEvent.season)
					.joinedload(m.BallotSeason.room_listings)
					.joinedload(m.RoomListing.audience_types)
			)
		).one()

		return template('ballot-event-edit', ballot_event=ballot_event)

	@app.post('/<ballot_id:int>/<ballot_type_name>/edit', name="edit-ballot-event")
	@needs_auth('admin')
	def save_ballot_times(ballot_id, ballot_type_name, db):
		ballot_type = db.query(m.BallotType).filter(func.lower(m.BallotType.name) == ballot_type_name.lower()).one()

		ballot_event = (db
			.query(m.BallotEvent)
			.join(m.BallotSeason)
			.filter(m.BallotEvent.type == ballot_type)
			.filter(m.BallotSeason.year == ballot_id)
		).one()


		ballot_event.opens_at = datetime.strptime(request.forms.opens_at, "%Y-%m-%d").date()
		ballot_event.closes_at = datetime.strptime(request.forms.closes_at, "%Y-%m-%d").date()

		return template('ballot-event-edit', ballot_event=ballot_event)

	@app.route('/<ballot_id:int>/<ballot_type_name>/edit-rooms')
	@needs_auth('admin')
	def show_ballot_room_editor(ballot_id, ballot_type_name, db):
		ballot_type = db.query(m.BallotType).filter(func.lower(m.BallotType.name) == ballot_type_name.lower()).one()

		ballot_eventsq = (db
			.query(m.BallotEvent)
			.join(m.BallotSeason)
			.filter(m.BallotEvent.type == ballot_type)
			.filter(m.BallotSeason.year <= ballot_id)
			.order_by(m.BallotSeason.year.desc())
			.limit(2)
		)
		ballot_events = ballot_eventsq.all()

		if ballot_events[0].season.year != ballot_id:
			raise HTTPError(404, "No {} ballot for the {} season {} {}".format(ballot_type.name, ballot_id, ballot_eventsq, ballot_events))
		else:
			ballot = ballot_events[0]

		if len(ballot_events) == 2:
			last_ballot = ballot_events[1]
		else:
			last_ballot = None

		root = db.query(m.Place).options(
			joinedload_all('children.rooms.listing_for'),
			joinedload_all('children.children.rooms.listing_for'),
			joinedload_all('children.children.children.rooms.listing_for'),
			joinedload_all('children.children.children.children.rooms.listing_for'),
		).filter(m.Place.parent == None).one()

		return template('ballot-event-edit-rooms',
			ballot_event=ballot,
			last_ballot_event=last_ballot,
			root=root)

	@app.post('/<ballot_id:int>/<ballot_type_name>/edit-rooms')
	@needs_auth('admin')
	def save_ballot_rooms(ballot_id, ballot_type_name, db):
		ballot_type = db.query(m.BallotType).filter(func.lower(m.BallotType.name) == ballot_type_name.lower()).one()
		ballot_season = db.query(m.BallotSeason).filter(m.BallotSeason.year == ballot_id).one()

		# collect all the checked rooms from the form
		room_ids = set()
		for name, value in request.forms.items():
			match = re.match(r'rooms\[(\d+)\]', name)
			if match and value == 'on':
				room_ids.add(int(match.group(1)))

		# for existing listings, update the audiences
		not_visible = set()
		for l in ballot_season.room_listings:
			if l.room_id in room_ids:
				l.audience_types |= {ballot_type}
				room_ids.remove(l.room_id)
			else:
				l.audience_types -= {ballot_type}
				if not l.audience_types and not l.occupancies:
					not_visible.add(l)

		# now find rooms with no listing
		for i in room_ids:
			r = db.query(m.Room).get(i)
			if r:
				r.listing_for[ballot_season] = m.RoomListing(
					room=r,
					ballot_season=ballot_season,
					audience_types={ballot_type}
				)

		return redirect(request.url)

	@app.route('/<ballot_id:int>/<ballot_type_name>/edit-slots', method=('GET', 'POST'))
	@needs_auth('admin')
	def edit_ballot_slots(ballot_id, ballot_type_name, db):
		ballot_type = db.query(m.BallotType).filter(func.lower(m.BallotType.name) == ballot_type_name.lower()).one()

		ballot_event = (db
			.query(m.BallotEvent)
			.join(m.BallotSeason)
			.filter(m.BallotEvent.type == ballot_type)
			.filter(m.BallotSeason.year == ballot_id)
		).one()


		step2 = None
		if request.method == "POST" and request.files.slot_csv:
			raw_data, parse_errors = parse_csv(iter(request.files.slot_csv.file))

			data, data_errors = process_slot_tuples(db, raw_data)

			# check for times which changed
			for u, ts in data.items():
				s = u.slot_for.get(ballot_event)
				if s and s.choice and s.time != ts:
					data[u] = s.time
					data_errors += [('slot-used-move', s, ts)]

			# check for deleted items
			for s in ballot_event.slots:
				if s.choice and s.person not in data:
					data[s.person] = s.time
					data_errors += [('slot-used-delete', s)]

			step2 = data, data_errors + parse_errors

		elif request.method == "POST" and request.forms.slot_json:
			raw_data = parse_json(request.forms.slot_json)
			data, data_errors = process_slot_tuples(db, raw_data)
			if data_errors:
				step2 = data, data_errors
			else:
				ballot_event.slots[:] = [
					m.BallotSlot(person=person, time=ts, event=ballot_event)
					for person, ts in data.items()
				]

				db.commit()

				raise redirect(app.get_url('show-ballot', ballot_id=ballot_id))


		return template('ballot-event-edit-slots',
			ballot_event=ballot_event,
			step2=step2
		)

	@app.route('/<ballot_id:int>/<ballot_type_name>/slots.csv')
	@needs_auth('admin')
	def csv_ballot_slots(ballot_id, ballot_type_name, db):
		ballot_type = db.query(m.BallotType).filter(func.lower(m.BallotType.name) == ballot_type_name.lower()).one()

		ballot_event = (db
			.query(m.BallotEvent)
			.join(m.BallotSeason)
			.filter(m.BallotEvent.type == ballot_type)
			.filter(m.BallotSeason.year == ballot_id)
		).one()


		sfile = StringIO.StringIO()
		o = csv.writer(sfile)

		o.writerow(["date", "time", "crsid", "name (ignored)"])
		last_date = None
		for s in sorted(ballot_event.slots, key=lambda s: s.time):
			if s.time.date() != last_date:
				o.writerow([str(s.time.date()) + "@", s.time.time(), s.person.crsid + "@", s.person.name])
				last_date = s.time.date()
			else:
				o.writerow(["", s.time.time(), s.person.crsid + "@", s.person.name])

		if not ballot_event.slots:
			n = datetime.now().replace(second=0, microsecond=0)
			o.writerow([str(n.date()) + "@", n.time(), "crsid123@", 'example student (delete!)'])

		response.content_type = 'text/csv'
		response.headers['Content-Disposition'] = 'attachment; filename="slots-{}-{}.csv"'.format(ballot_id, ballot_type.name)
		return sfile.getvalue()


def parse_json(j):
	return [
		(datetime.strptime(date, "%Y-%m-%dT%H:%M:%S"), crsid)
		for date, crsid in json.loads(j)
	]

def parse_csv(f):
	"""
	Read in a sparse CSV, and produce tuples of (datetime ts, str crsid)
	Also returns a list of parse errors
	"""
	reader = csv.reader(f)
	errors = []
	data = []

	headers = next(reader)

	if headers[:3] != ["date", "time", "crsid"]:
		errors += [('bad-header',)]
		return [], errors

	last_date = None
	last_time = None
	for l in reader:
		if len(l) < 3:
			errors += [('bad row {}'.format(l))]
			continue

		date, time, crsid = l[:3]

		# either parse the date, or reuse the last one
		if date:
			try:
				date = datetime.strptime(date, "%Y-%m-%d@")
			except ValueError:
				errors += [('bad-date', date)]
				continue
			last_date = date
		elif last_date:
			date = last_date
		else:
			errors += [('no-date',)]
			continue

		# either parse the time, or reuse the last one + 3 minutes
		if time:
			try:
				time = datetime.strptime(time, "%H:%M:%S")
			except ValueError:
				errors += [('bad-time', time)]
				continue
			last_time = time
		elif last_time:
			time = last_time + timedelta(minutes=3)
			last_time = time
		else:
			errors += [('no-time',)]
			continue

		# save the (ts, crsid) tuple
		data += [(
			datetime.combine(date.date(), time.time()),
			crsid.rstrip('@')
		)]

	return data, errors

def process_slot_tuples(db, data):
	errors = []

	# get all crsids
	crsids = [crsid for _, crsid in data]

	# find existing users attached to them
	db_users = [db.query(m.Person).get(c) for c in crsids]
	users = {u.crsid: u for u in db_users if u}

	new_users = set(crsids) - set(users.keys())

	# lookup the rest
	lookup = lookup_ldap(new_users)

	for crsid in new_users:
		d = lookup.get(crsid)
		if d:
			name = d.get('visibleName')
			users[crsid] = m.Person(crsid=crsid, name=name)
		else:
			errors += [('bad-crsid', crsid)]

	data = {
		users[crsid]: ts
		for ts, crsid in data
		if crsid in users
	}

	return data, errors


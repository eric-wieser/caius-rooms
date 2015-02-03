from datetime import datetime, timedelta
import csv
import StringIO

from bottle import *
from sqlalchemy import func
from sqlalchemy.orm import joinedload, joinedload_all

from utils import needs_auth, lookup_ldap
import database.orm as m

def add_routes(app):
	@app.route('/<ballot_id>/edit')
	@needs_auth('admin')
	def show_ballot(ballot_id, db):
		ballot = db.query(m.BallotSeason).options(
			joinedload(m.BallotSeason.events),
			joinedload(m.BallotSeason.room_listings).subqueryload(m.RoomListing.audience_types),
		).filter(m.BallotSeason.year == ballot_id).one()
		return template('ballot-edit', ballot_season=ballot, db=db)

	@app.route('/<ballot_id>/add-event')
	@needs_auth('admin')
	def show_ballot(ballot_id, db):
		ballot = db.query(m.BallotSeason).options(
			joinedload(m.BallotSeason.events)
		).filter(m.BallotSeason.year == ballot_id).one()

		event_types = (db
			.query(m.BallotType, m.BallotType.events.any(m.BallotEvent.season == ballot))
			.outerjoin(m.BallotType.events)
		)

		return template('ballot-add-event', ballot_season=ballot, event_types=event_types)

	@app.post('/<ballot_id>/add-event')
	@needs_auth('admin')
	def show_ballot(ballot_id, db):
		ballot = db.query(m.BallotSeason).filter(m.BallotSeason.year == ballot_id).one()
		event_type = db.query(m.BallotType).filter(m.BallotType.id == int(request.forms.type)).one()

		e = m.BallotEvent(
			season=ballot,
			type=event_type,
			opens_at=datetime.strptime(request.forms.opens_at, "%Y-%m-%d"),
			closes_at=datetime.strptime(request.forms.closes_at, "%Y-%m-%d")
		)

		db.add(e)
		return redirect(request.url)

	@app.route('/<ballot_id:int>/<ballot_type_name>/edit-rooms')
	@needs_auth('admin')
	def edit_ballot_rooms(ballot_id, ballot_type_name, db):
		if ballot_type_name.lower() != ballot_type_name:
			raise redirect(request.url.replace(ballot_type_name, ballot_type_name.lower()))


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

		root = db.query(m.Cluster).options(
			joinedload_all('children.rooms.listing_for'),
			joinedload_all('children.children.rooms.listing_for'),
			joinedload_all('children.children.children.rooms.listing_for'),
			joinedload_all('children.children.children.children.rooms.listing_for'),
		).filter(m.Cluster.parent == None).one()

		return template('ballot-event-edit-rooms',
			ballot_event=ballot,
			last_ballot_event=last_ballot,
			root=root)

	@app.post('/<ballot_id:int>/<ballot_type_name>/edit-rooms')
	@needs_auth('admin')
	def save_ballot_rooms(ballot_id, ballot_type_name, db):
		ballot_type = db.query(m.BallotType).filter(func.lower(m.BallotType.name) == ballot_type_name.lower()).one()
		ballot_season = db.query(m.BallotSeason).filter(m.BallotSeason.year == ballot_id).one()

		room_ids = set()
		for name, value in request.forms.items():
			match = re.match(r'rooms\[(\d+)\]', name)
			if match and value == 'on':
				room_ids.add(int(match.group(1)))

		for l in ballot_season.room_listings:
			if l.room_id in room_ids:
				l.audience_types |= {ballot_type}
			else:
				l.audience_types -= {ballot_type}

		return redirect(request.url)

	@app.route('/<ballot_id:int>/<ballot_type_name>/edit-slots', method=('GET', 'POST'))
	@needs_auth('admin')
	def edit_ballot_slots(ballot_id, ballot_type_name, db):
		if ballot_type_name.lower() != ballot_type_name:
			raise redirect(request.url.replace(ballot_type_name, ballot_type_name.lower()))

		ballot_type = db.query(m.BallotType).filter(func.lower(m.BallotType.name) == ballot_type_name.lower()).one()

		ballot_event = (db
			.query(m.BallotEvent)
			.join(m.BallotSeason)
			.filter(m.BallotEvent.type == ballot_type)
			.filter(m.BallotSeason.year == ballot_id)
		).one()

		def parse_csv(r):

			errors = []
			data = []

			headers = next(r)

			if headers != ["date", "time", "crsid", "name (ignored)"]:
				errors += ['bad-header']
				return None, errors

			last_date = None
			last_time = None
			for l in r:
				if len(l) < 3:
					errors += [('bad row {}'.format(l))]
					continue

				date, time, crsid = l[:3]

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
					errors += [('no-date')]
					continue


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
					errors += [('no-time')]
					continue

				ts = datetime.combine(date.date(), time.time())

				data += [(ts, crsid.rstrip('@'))]


			# get all crsids
			crsids = [crsid for ts, crsid in data]

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


		if request.method == "POST" and request.files.slot_csv:
			r = csv.reader(iter(request.files.slot_csv.file))
			step2 = parse_csv(r)
		else:
			step2 = None


		return template('ballot-event-edit-slots',
			ballot_event=ballot_event,
			step2=step2
		)

	@app.route('/<ballot_id:int>/<ballot_type_name>/slots.csv')
	@needs_auth('admin')
	def csv_ballot_slots(ballot_id, ballot_type_name, db):
		if ballot_type_name.lower() != ballot_type_name:
			raise redirect(request.url.replace(ballot_type_name, ballot_type_name.lower()))

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
		return sfile.getvalue()
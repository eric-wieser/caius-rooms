% import database.orm as m

% rebase('layout')

<div class="container">
	<h1>Ballot for {{ ballot_season }}</h1>
	<div class="row">
		<div class="col-lg-6">
			<h2>Events</h2>
			<table class="table">
				<thead>
					<tr>
						<th>Type</th>
						<th>Opens</th>
						<th>Closes</th>
					</tr>
				</thead>
				<tbody>
					% for event in ballot_season.events:
						<tr>
							<td>
								{{ event.type.name }}
							</td>
							<td>
								<input type="date" class="form-control" value="{{ event.opens_at }}" />
							</td>
							<td>
								<input type="date" class="form-control" value="{{ event.closes_at }}" />
							</td>
						</tr>
					% end
				</tbody>
			</table>
		</div>
		<div class="col-lg-6">
			<h2>Rooms</h2>
			<table class="table table-condensed table-striped">
				<thead>
					<tr>
						<th>Room</th>
						<th class="rule-right">Rent</th>
						% for event in ballot_season.events:
							<th>{{ event.type.name }}</th>
						% end
					</tr>
				</thead>
				<tbody>
					<%
					from sqlalchemy.orm import aliased 
					listings = aliased(m.RoomListing, db
						.query(m.RoomListing)
						.join(m.BallotSeason)
						.filter(m.BallotSeason.year == ballot_season.year)
						.subquery()
					)

					rooms_and_listings = (db
						.query(m.Room, listings)
						.outerjoin(listings)
					)


					%>
					% for room, listing in rooms_and_listings:
						<tr>
							<td>
								<a href="{{ url_for(room) }}">{{ room.pretty_name() }}</a>
							</td>
							<td class="rule-right shrink">
								% if listing:
									<input type="text" style="padding: 0; height: auto; min-width: 8ex" class="form-control input-sm" value="{{ listing.rent or '' }}" />
								% end
							</td>
							% for event in ballot_season.events:
								<td class="shrink">
									<input type="checkbox"
									       name="rooms[{{ room.id }}][{{ event.type.name }}]"
									       {{ 'checked' if listing and event.type in listing.audience_types else '' }} />

								</td>
							% end
						</tr>
					% end
				</tbody>
			</table>
		</div>
	</div>
</div>

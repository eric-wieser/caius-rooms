% import database.orm as m

% def extra_nav():
	<li><a href='/places'><span class="glyphicon glyphicon-map-marker"></span> Places</a></li>
	<li><a href='/rooms'><span class="glyphicon glyphicon-home"></span> Rooms</a></li>
% end

% rebase layout.tpl extra_nav=extra_nav
<a class="hidden-xs" href="https://github.com/eric-wieser/caius-rooms">
	<img style="position: absolute; top: 0px; right: 0; border: 0; z-index: 10000;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_orange_ff7600.png" alt="Fork me on GitHub">
</a>
<div class="container">
	<div class="jumbotron">
		<h1>RoomPicks</h1>
		<p>For when you don't yet have the Caius</p>
	</div>
	<!-- <div class="row">
		<div class="col-md-4">
			<h2>Browse</h2>
		</div>
		<div class="col-md-4">
			<h2>Sort</h2>
		</div>
		<div class="col-md-4">
			<h2>Choose</h2>
		</div>
	</div> -->
	<div class="row">
		<div class="col-md-6">
			<h2>Recent reviews</h2>
			<table class="table">
				% for review in db.query(m.Review).order_by(m.Review.published_at.desc()).limit(10):
					% room = review.occupancy.listing.room
					% author = review.occupancy.resident
					<tr>
						<td class="text-right">
							<a href="/rooms/{{room.id}}#review-{{review.id}}">{{ room.pretty_name() }}</a>
						</td>
						<td>
							% if author:
								<a href="/people/{{author.crsid}}">{{ author.name }}</a>
							% else:
								<span class="text-muted">unknown</span>
							% end
						</td>
						<td>
							{{ review.published_at }}
						</td>
					</tr>
				%end
			</table>
		</div>
		<div class="col-md-6">
			% ballot_event = db.query(m.BallotEvent).order_by(m.BallotEvent.closes_at.desc()).first()
			<h2>Recent bookings <small> for {{ballot_event.season.year}}-{{ballot_event.season.year+1}}</small></h2>
			<table class="table">
				% ballot_occupancies = (db
					% .query(m.Occupancy)
					% .join(m.RoomListing)
					% .join(m.BallotSeason)
					% .filter(m.BallotSeason.year == ballot_event.season.year)
				% )
				% for occupancy in ballot_occupancies.order_by(m.Occupancy.chosen_at.desc()).limit(10):
					% room = occupancy.listing.room
					% author = occupancy.resident
					<tr>
						<td class="text-right">
							<a href="/rooms/{{room.id}}">{{ room.pretty_name() }}</a>
						</td>
						<td>
							% if author:
								<a href="/people/{{author.crsid}}">{{ author.name }}</a>
							% else:
								<span class="text-muted">unknown</span>
							% end
						</td>
						<td>
							{{ occupancy.chosen_at }}
						</td>
					</tr>
				%end
			</table>
		</div>
	</div>
</div>

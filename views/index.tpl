% import database.orm as m
% from utils import format_ts_html
% from sqlalchemy.sql import func

% rebase layout.tpl
<a class="hidden-xs" href="https://github.com/eric-wieser/caius-rooms">
	<img style="position: absolute; top: 50px; right: 0; border: 0;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_orange_ff7600.png" alt="Fork me on GitHub">
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
				% reviews = (db
					% .query(m.Review)
					% .order_by(m.Review.published_at.desc())
					% .group_by(m.Review.occupancy_id)
					% .having(func.max(m.Review.published_at))
				% )
				% for review in reviews.limit(10):
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
							{{! format_ts_html(review.published_at) }}
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
							{{! format_ts_html(occupancy.chosen_at) }}
						</td>
					</tr>
				%end
			</table>
		</div>
	</div>
</div>

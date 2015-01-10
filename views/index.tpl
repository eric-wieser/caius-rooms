<%
import database.orm as m
from utils import format_ts_html
from sqlalchemy.sql import func
from bottle import request

rebase('layout')
%>
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
							<a href="/rooms/{{room.id}}#occupancy-{{review.occupancy.id}}">{{ room.pretty_name() }}</a>
						</td>
						% if request.user:
							<td>
								% if author:
									<a href="/users/{{author.crsid}}">{{ author.name }}</a>
								% else:
									<span class="text-muted">unknown</span>
								% end
							</td>
						% end
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
				<%
				ballot_occupancies = (db
					.query(m.Occupancy)
					.join(m.RoomListing)
					.join(m.BallotSeason)
					.filter(m.BallotSeason.year == ballot_event.season.year)
					.order_by(m.Occupancy.chosen_at.desc())
				)

				ballot_occupancies = (b for b in ballot_occupancies if b.ballot_slot)

				import itertools
				%>
				% for occupancy in itertools.islice(ballot_occupancies, 10):
					% room = occupancy.listing.room
					% author = occupancy.resident
					<tr>
						<td class="text-right">
							<a href="/rooms/{{room.id}}">{{ room.pretty_name() }}</a>
						</td>
						% if request.user:
							<td>
								% if author:
									<a href="/users/{{author.crsid}}">{{ author.name }}</a>
								% else:
									<span class="text-muted">unknown</span>
								% end
							</td>
						% end
						<td>
							{{! format_ts_html(occupancy.chosen_at) }}
						</td>
					</tr>
				%end
			</table>
		</div>
	</div>
	<div class="row">
		<div class="col-xs-12">
			<h2>Recent photos</h2>
		</div>
		<%
		photos = (db
			.query(m.Photo)
			.order_by(m.Photo.published_at.desc())
		)

		def ordered_photos(cols=6, rows=2):
			x = 0
			y = 0
			it = iter(photos)
			queued = []

			def fits(p):
				return x + 1 + p.is_panorama <= cols
			end
			while y < rows:
				if queued and fits(queued[0]):
					x += 1 + queued[0].is_panorama
					p, queued = queued[0], queued[1:]
					yield p
				else:
					p = next(it)
					if fits(p):
						x += 1 + p.is_panorama
						yield p
					else:
						queued.append(p)
					end
				end

				if x >= cols:
					x = 0
					y += 1
				end
			end
		end


		%>
		% i = 0
		% for photo in ordered_photos():
			% room = photo.occupancy.listing.room
			<div class="{{ 'col-md-4 col-sm-6 col-xs-12' if photo.is_panorama else 'col-md-2 col-sm-3 col-xs-6' }} ">
				<a href="/rooms/{{room.id}}" title="{{ photo.caption }}&NewLine;{{ photo.published_at }}" class="thumbnail cropped-photo" style="display: block; height: 150px; background-image: url({{ photo.href }}); margin: 15px 0px; position: relative; overflow: hidden" target="_blank"><span class="label label-default" style="display: block; position: absolute; top: 0; left: 0;">{{room.pretty_name()}}</span></a>
			</div>
		% end

	</div>
</div>

<%
import database.orm as m
from utils import format_ts_html
from sqlalchemy.sql import func
from sqlalchemy.orm import joinedload, subqueryload
from bottle import request
from datetime import date

rebase('layout')
%>
<div class="splash" style="position: relative;">
	<a class="hidden-xs" href="https://github.com/eric-wieser/caius-rooms">
		<img style="position: absolute; top: 0px; left: 0; border: 0; z-index: 10;" src="https://s3.amazonaws.com/github/ribbons/forkme_left_orange_ff7600.png" alt="Fork me on GitHub">
	</a>
	<div class="container">
		<div class="row">
			<div class="splash-left">
				<h1>RoomPicks</h1>
				<p class="tagline">For when you don't yet have the Caius</p>
			</div>
			<div class="splash-right">
				<hr class="hidden-md hidden-lg" />
				<p class="lead">
					A room encyclopaedia for the housing ballot at Gonville &amp; Caius College.
				</p>
				<p>
					Combining information from the college with student-submitted photos and reviews, to help students make an informed choice in their housing ballots. During the ballot period, you'll use this site to select your room, hopefully. More information will be sent out closer to the time.
				</p>
			</div>
		</div>
	</div>
</div>
<div class="container">
	% if request.urlparts.netloc != 'roompicks.caiusjcr.co.uk':
		<div class="alert alert-info" role="alert">
			<strong>Hey!</strong>
			We're moving over to <a href="http://roompicks.caiusjcr.co.uk">the Caius JCR website</a>, so you might want to update your bookmarks to point there before this disappears!
		</div>
	% end
	<div class="row">
		<div class="col-md-6 col-md-push-6">
			% ballot_season = db.query(m.BallotSeason).order_by(m.BallotSeason.year.desc()).first()
			% if request.user:
				<%
				slots = (db
					.query(m.BallotSlot)
					.join(m.BallotEvent)
					.filter(m.BallotEvent.season == ballot_season)
					.filter(date.today() <= m.BallotEvent.closes_at)
					.filter(m.BallotSlot.time <= func.now())
					.filter(m.BallotSlot.choice == None)
					.order_by(m.BallotSlot.time)
				).all()
				%>
				% if slots:
					<h2>Currently balloting</h2>
					<table class="table">
						% for slot in slots:
							<tr>
								<td>
									<a href="{{ url_for(slot.person) }}" style="display: block; padding-left: 25px;">
										<img src="{{ slot.person.gravatar(size=20) }}" width="20" height="20" style="margin-left: -25px; float: left" />
										{{ slot.person.name }}
									</a>
								</td>
								<td>
									{{! format_ts_html(slot.time) }}
								</td>
							</tr>
						% end
					</table>
				% end
			% end
			<h2>Recent bookings <small> for {{ballot_season}}</small></h2>
			<table class="table">
				<%
				ballot_occupancies = (db
					.query(m.Occupancy)
					.options(
						joinedload(m.Occupancy.listing)
							.joinedload(m.RoomListing.room)
					)
					.join(m.RoomListing)
					.join(m.BallotSeason)
					.filter(m.BallotSeason.year == ballot_season.year)
					.filter(m.Occupancy.ballot_slot != None)
					.order_by(m.Occupancy.chosen_at.desc())
				)

				import itertools
				%>
				% for occupancy in itertools.islice(ballot_occupancies, 10):
					% room = occupancy.listing.room
					% author = occupancy.resident
					<tr>
						<td class="text-right">
							<a href="{{ url_for(room) }}">{{ room.pretty_name() }}</a>
						</td>
						% if request.user:
							<td>
								% if author:
									<a href="{{ url_for(author) }}" style="display: block; padding-left: 25px;">
										<img src="{{ author.gravatar(size=20) }}" width="20" height="20" style="margin-left: -25px; float: left" />
										{{ author.name }}
									</a>
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
		<div class="col-md-6 col-md-pull-6">
			<h2>Recent reviews</h2>
			<table class="table">
				<% reviews = (db
					.query(m.Review)
					.options(
						joinedload(m.Review.occupancy)
							.joinedload(m.Occupancy.listing)
							.joinedload(m.RoomListing.room)
					)
					.order_by(m.Review.published_at.desc())
					.filter(m.Review.is_newest & (m.Review.editor == None))
				) %>
				% for review in reviews.limit(10):
					% room = review.occupancy.listing.room
					% author = review.occupancy.resident
					<tr>
						<td class="text-right">
							<a href="{{ url_for(room) }}#occupancy-{{review.occupancy.id}}">{{ room.pretty_name() }}</a>
						</td>
						% if request.user:
							<td>
								% if author:
									<a href="{{ url_for(author) }}" style="display: block; padding-left: 25px;">
										<img src="{{ author.gravatar(size=20) }}" width="20" height="20" style="margin-left: -25px; float: left" />
										{{ author.name }}
									</a>
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
	</div>
	<div class="row">
		<div class="col-xs-12">
			<h2>Recent photos <small><a href="/photos">more</a></small></h2>
		</div>
		<%
		include('parts/photo-grid', cols=6, rows=2, photos=(db
			.query(m.Photo)
			.order_by(m.Photo.published_at.desc())
		))
		%>

	</div>
</div>

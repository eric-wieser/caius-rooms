<%
import database.orm as m
from utils import format_ts_html
from sqlalchemy.sql import func
from sqlalchemy.orm import joinedload, subqueryload
from bottle import request
from datetime import date

rebase('layout')
%>
<a class="hidden-xs" href="https://github.com/eric-wieser/caius-rooms">
	<img style="position: absolute; top: 50px; left: 0; border: 0; z-index: 10;" src="https://s3.amazonaws.com/github/ribbons/forkme_left_orange_ff7600.png" alt="Fork me on GitHub">
</a>
<div class="splash">
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
	<div class="alert alert-info" role="alert">
		<a href="/places/48">R staircase Tree Court</a> will be the subject of the next phase of the Tree Court refurbishment, expected to run from July through November 2015. When the work is complete the Tutors will determine the amount of an appropriate compensatory payment to residents. However, students who expect to spend a significant amount of time in their rooms during the working day should think carefully before choosing a room on this staircase.
	</div>
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
				<a href="{{ url_for(room) }}" title="{{ photo.caption }}&NewLine;{{ photo.published_at }}" class="thumbnail cropped-photo" style="display: block; height: 150px; background-image: url({{ photo.href }}); margin: 15px 0px; position: relative; overflow: hidden" target="_blank"><span class="label label-default" style="display: block; position: absolute; top: 0; left: 0;">{{room.pretty_name()}}</span></a>
			</div>
		% end

	</div>
</div>

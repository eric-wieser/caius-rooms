% from bottle import request
% from utils import format_ts_html

% rebase layout.tpl
% layout_random = "/users/random"
% def layout_breadcrumb():
	% yield ('#', user.name)
% end

<div class="container">
	% occs = sorted(user.occupancies, key=lambda o: o.listing.ballot_season.year)
	<div class="jumbotron">
		<div class="row">
			<div class="col-md-3">
				<img src="{{ user.gravatar(size=400) }}" class="img-responsive" />
			</div>
			<div class="col-md-9">
				<h1>{{ user.name }} <small>{{ user.crsid }}</small></h1>

				<table class="table">
					% for o in occs:
						<tr>
							<th>
								{{ o.listing.ballot_season.year }} - {{ o.listing.ballot_season.year + 1 }}
							</th>
							<td>
								<a href="/rooms/{{ o.listing.room.id }}">
									{{ o.listing.room.pretty_name() }}
								</a>
							</td>
							<td>
								% sl = o.ballot_slot
								<a href="/ballots/{{ o.listing.ballot_season.year }}#slot-{{ sl.id }}">
									#{{ sl.ranking }}</a>
								in the {{ sl.event.type.name.lower() }} ballot
							</td>
							<td class="text-muted">
								{{! format_ts_html(o.chosen_at) }}
							</td>
							% if user == request.user:
								<td>
									<a href="/reviews/new/{{ o.id }}">Review</a>
								</td>
							% end
						</tr>
					% end
				</table>
			</div>
		</div>
	</div>
	<div class="row">
		<div class="col-md-12">
			<h2>Reviews</h2>
			% for occupancy in occs:
				% for review in occupancy.reviews:
					<hr />
					% include review.tpl review=review, show_room=True
				% end
			% end
		</div>
	</div>
</div>

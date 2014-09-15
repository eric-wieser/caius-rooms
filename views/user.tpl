% def extra_nav():
	<li class="active"><a href='/users'><span class="glyphicon glyphicon-user"></span> Users</a></li>
	<li><a href='/places'><span class="glyphicon glyphicon-map-marker"></span> Places</a></li>
	<li><a href='/rooms'><span class="glyphicon glyphicon-home"></span> Rooms</a></li>
% end

% rebase layout.tpl extra_nav=extra_nav, random="/people/random"

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
								{{ o.chosen_at }}
							</td>
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

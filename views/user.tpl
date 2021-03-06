<%
from bottle import request
from utils import format_ts_html
rebase('layout')
layout_random = "/users/random"
def layout_breadcrumb():
	yield ('#', user.name)
end
def layout_extra_nav():
	if request.user and request.user.is_admin: %>
		<li class="dropdown">
			<a href="#" class="dropdown-toggle" data-toggle="dropdown">
				<span class="glyphicon glyphicon-flag text-danger"></span> Admin <span class="caret"></span>
			</a>
			<ul class="dropdown-menu" role="menu">
				<li><a href="/tools/assign-room?user={{ user.crsid }}">Assign room manually</a></li>
			</ul>
		</li>
		<% 
	end
end
%>

<div class="container">
	% occs = sorted(user.occupancies, key=lambda o: o.listing.ballot_season.year)
	<div class="jumbotron">
		<div class="row">
			<div class="col-md-3">
				<img src="{{ user.gravatar(size=400) }}" class="img-responsive" />
				% if user == request.user:
					<div class="text-muted text-center small">
						Want to change your avatar?
						You'll need to <a href="https://en.gravatar.com/">create a gravatar</a> for <code>{{ user.crsid }}@cam.ac.uk</code>
					</div>
				% end
			</div>
			<div class="col-md-9">
				<h1>
					{{ user.name }}
					% if user.is_admin:
						<span title="administrator">&diams;</span>
					% end
					<small>{{ user.crsid }}</small>
				</h1>

				<table class="table">
					% for o in occs:
						<%
						if o.cancelled:
							s = ' style="text-decoration: line-through"'
						else:
							s = ''
						end
						%>
						<tr{{!s}}>
							<th>
								{{ o.listing.ballot_season }}
							</th>
							<td>
								<a href="{{ url_for(o.listing.room) }}">
									{{ o.listing.room.pretty_name() }}
								</a>
							</td>
							<td>
								% sl = o.ballot_slot
								% if sl:
									<a href="{{ url_for(o.listing.ballot_season) }}#slot-{{ sl.id }}">
										#{{ sl.ranking }}</a>
									in the {{ sl.event.type.name.lower() }} ballot
								% else:
									not balloted for
								% end
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
				<hr />
				% include('parts/review', occupancy=occupancy, show_room=True)
			% end
		</div>
	</div>
</div>

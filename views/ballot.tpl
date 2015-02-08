% import database.orm as m
% from bottle import request
% rebase('layout')

<%
def layout_breadcrumb():
	yield ('#', '{} season'.format(ballot_season))
end

show_edit = request.user and request.user.is_admin
%>
<div class="container">
	% if show_edit:
		<a href="{{ url_for(ballot_season) }}/edit" class="btn btn-primary pull-right">
			<span class="glyphicon glyphicon-plus"></span> Add new ballot event
		</a>
	% end

	<h1>Ballots for {{ ballot_season }}</h1>

	<div class="row">
		% for event in ballot_season.events:
			<div class="col-md-4">
				<h2>
					{{ event.type.name }}
					<small>
						{{ '{:%d %b}'.format(event.opens_at) }}
						&#x2012;
						{{ '{:%d %b}'.format(event.closes_at) }}

						<a href="{{ url_for(ballot_season) }}/{{ event.type.name }}/edit">
							<span class="glyphicon glyphicon-pencil"></span>
						</a>
					</small>
				</h2>

				<table class="table table-condensed">
					<tbody>
						<%
						include('parts/slot-list-rows', slot_tuples=(
							(s.id, s.person, s.time)
							for s in event.slots
						))
						%>
					</tbody>
				</table>
			</div>
		% end
	</div>
</div>

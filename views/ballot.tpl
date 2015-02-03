% import database.orm as m
% from bottle import request
% rebase('layout')

<%
def layout_breadcrumb():
	yield ('#', '{} - {} season'.format(ballot_season.year, ballot_season.year + 1))
end

show_edit = request.user and request.user.is_admin
%>
<div class="container">
	% if show_edit:
		<a href="/ballots/{{ ballot_season.year }}/edit" class="btn btn-primary btn-lg pull-right">
			<span class="glyphicon glyphicon-pencil"></span> Edit
		</a>
	% end

	<h1>Ballots for {{ ballot_season.year }} - {{ ballot_season.year + 1 }}</h1>


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
						{{ event.opens_at }}
					</td>
					<td>
						{{ event.closes_at }}
					</td>
				</tr>
			% end
		</tbody>
	</table>
	% if show_edit:
		<div class="text-right">
			<a href="/ballots/{{ ballot_season.year }}/add-event" class="btn btn-sm btn-primary">
				<span class="glyphicon glyphicon-plus"></span> Add new ballot event
			</a>
		</div>
	% end

	<h2>Slots</h2>
	<div class="row">
		% for event in ballot_season.events:
			<div class="col-md-4">
				<h3>{{ event.type.name }}</h3>
				<table class="table table-condensed">
					<tbody>
						<%
						include('parts/slot-list-rows', slot_tuples=(
							(s.person, s.time)
							for s in event.slots
						))
						%>
					</tbody>
				</table>
			</div>
		% end
	</div>
</div>

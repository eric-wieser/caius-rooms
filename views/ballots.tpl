% rebase('layout')

<div class="container">
	<table class="table">
		<thead>
			<tr>
				<th>Year</th>
				<th>Type</th>
				<th>Opens</th>
				<th>Closes</th>
				<th>Rooms allocated</th>
				<th></th>
			</tr>
		</thead>
		<tbody>
			% for ballot_season in ballots:
				% events = ballot_season.events
				% for i, event in enumerate(events):
					<tr>
						% if i == 0:
							<th rowspan="{{ len(events) }}" class="vert-align">
								{{ ballot_season.year }} - {{ ballot_season.year + 1 }}
							</th>
						% end
						<td>
							{{ event.type.name }}
						</td>
						<td>
							{{ event.opens_at }}
						</td>
						<td>
							{{ event.closes_at }}
						</td>
						<td>
							{{ sum(1 for listing in ballot_season.room_listings if event.type in listing.audience_types)}}
						</td>
						% if i == 0:
							<td rowspan="{{ len(events) }}" class="shrink" style="vertical-align: middle">
								<a href="ballots/{{ ballot_season.year }}/edit" class="btn btn-default btn-block {{ 'btn-xs' if len(events) == 1 else '' }}">
									<span class="glyphicon glyphicon-pencil"></span> Edit
								</a>
							</td>
						% end
					</tr>
				% end
			% end
		</tbody>
	</table>
</div>

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
			</tr>
		</thead>
		<tbody>
			% for ballot_season in ballots:
				% events = ballot_season.events
				% for i, event in enumerate(events):
					<tr>
						% if i == 0:
							<th rowspan="{{ len(events) }}" class="vert-align">
								<a href="{{ url_for(ballot_season) }}">
									{{ ballot_season }}
								</a>
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
					</tr>
				% end
				% if not events:
					<tr>
						<th class="vert-align">
							<a href="{{ url_for(ballot_season) }}">
								{{ ballot_season }}
							</a>
						</th>
						<td colspan="4" class="text-muted">No events</td>
					</tr>
				% end
			% end
		</tbody>
	</table>
</div>

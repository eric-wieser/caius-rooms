% import database.orm as m
% rebase layout.tpl

<div class="container">
	<h1>Ballot for {{ ballot_season.year }} - {{ ballot_season.year + 1 }}</h1>

	<div class="row">
		% for event in ballot_season.events:
			<div class="col-md-4">
				<h2>{{ event.type.name }}</h2>
				<table class="table table-condensed">
					<tbody>
						% last_day = None
						% for i, slot in enumerate(sorted(event.slots, key=lambda s: s.time), 1):
							<tr>
								<th>
									<div class="anchor" id="slot-{{ slot.id }}"></div>
									{{ i }}
								</th>
								<td>
									<a href="/users/{{ slot.person.crsid }}">{{slot.person.name}}</a>
								</td>
								% day = '{:%d %b}'.format(slot.time)
								<td >
									{{ day if day != last_day else ''}}
								</td>
								% last_day = day
								<td>
									{{ '{:%H:%M}'.format(slot.time) }}
								</td>
							</tr>
						% end
					</tbody>
				</table>
			</div>
		% end
	</div>
</div>

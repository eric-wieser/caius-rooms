% last_day = None
% slot_tuples = sorted(slot_tuples, key=lambda (id, p, t): t)
% for i, (id, person, ts) in enumerate(slot_tuples, 1):
	<tr>
		<th>
			% if id:
				<div class="anchor" id="slot-{{ id }}"></div>
			% end
			{{ i }}
		</th>
		<td>
			% include('parts/user-link', user=person)
		</td>
		% day = '{:%d %b}'.format(ts)
		<td style="white-space: nowrap">
			{{ day if day != last_day else ''}}
		</td>
		% last_day = day
		<td>
			{{ '{:%H:%M}'.format(ts) }}
		</td>
	</tr>
% end

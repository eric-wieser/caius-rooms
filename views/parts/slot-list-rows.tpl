% last_day = None
% slot_tuples = sorted(slot_tuples, key=lambda (id, p, t): t)
% for i, (id, person, ts) in enumerate(slot_tuples, 1):
	<tr>
		<th style="width: 1px; text-align: right">
			% if id:
				<div class="anchor" id="slot-{{ id }}"></div>
			% end
			{{ i }}
		</th>
		<td>
			% include('parts/user-link', user=person)
		</td>
		% day = '{:%d %b}'.format(ts)
		<td style="white-space: nowrap; width: 1px">
			{{ day if day != last_day else ''}}
		</td>
		% last_day = day
		<td style="width: 1px">
			{{ '{:%H:%M}'.format(ts) }}
		</td>
	</tr>
% end

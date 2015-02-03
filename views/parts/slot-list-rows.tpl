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
			<a href="/users/{{ person.crsid }}" style="display: block; padding-left: 25px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap">
				<img src="{{ person.gravatar(size=20) }}" width="20" height="20" style="margin-left: -25px; float: left" />
				{{person.name}}
			</a>
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

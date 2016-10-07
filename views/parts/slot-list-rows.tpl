% last_day = None
% pred = get('pred')
% if pred is not None:
	<tr><td colspan="4" class="text-muted">
		<p>Apparently, showing the whole ballot list would be a privacy issue. If like me, you disagree with this, please take it up with Wendy Fox.</p>
		<p>Since obviously the information is useful, I'll show the people around your position anyway as a compromise.</p>
	</td></tr>
% end
% slot_tuples = sorted(slot_tuples, key=lambda (id, p, t): t)
% for i, (id, person, ts) in enumerate(slot_tuples, 1):
	% if not pred or pred(id, person, ts):
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
% end


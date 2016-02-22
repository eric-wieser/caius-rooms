% import database.orm as m
% from bottle import request
% from collections import Counter, defaultdict
% from datetime import datetime, timedelta, date
% from utils import format_ts_html
% rebase('layout')

<%
def layout_breadcrumb():
	yield (url_for(event.season), u'{} season'.format(event.season))
	yield ('#', event.type.name)
end
last_day = None
%>
<div class="container">

	<h1>
		{{ event.type.name }} ballot for {{ event.season }}
		% if event.is_active:
			<span class="label label-success">In progress</span>
		% elif event.opens_at > date.today():
			<span class="label label-warning">Scheduled</span>
		% else:
			<span class="label label-default">Complete</span>
		% end
	</h1>

	<table class="table table-condensed">
		<thead>
			<tr>
				<td></td>
				<th>Person</th>
				<th colspan='2' class="rule-right">Slot time</th>
				<th>Last seen</th>
				<!-- <th>Choice</th>
				<th>Chosen at</th> -->
			</tr>
		</thead>
		<tbody>
			% for i, s in enumerate(sorted(event.slots, key=lambda s: s.time), 1):
				% id, person, ts = (s.id, s.person, s.time)
				% occ = None # s.choice
				% t = datetime.now()
				% if occ:
					% cls = 'class="success"'
				% elif not person.last_seen or t > s.time and s.time > person.last_seen:
					% cls = 'class="danger"'
				% else:
					% cls = ''
				% end
				<tr {{! cls}}>
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
					<td style="width: 1px" class="rule-right">
						{{ '{:%H:%M}'.format(ts) }}
					</td>
					<td>
						{{! format_ts_html(s.person.last_seen)}}
					</td>

					<!-- <td>
						% if occ:
							% room = occ.listing.room
							<a href='{{url_for(room) }}'>{{room.pretty_name() }}</a>
						% end
					</td>
					<td>
						% if occ:
							{{! format_ts_html(occ.chosen_at) }}
						% end
					</td> -->
				</tr>
			% end
		</tbody>
	</table>
</div>

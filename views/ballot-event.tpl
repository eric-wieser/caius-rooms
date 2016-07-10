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

	<p class="text-muted small">
		Row colors indicate
		<span style="display: inline-block; padding: 2px; border-style: solid; border-width: 1px" class="alert-success">finished balloting</span>;
		<span style="display: inline-block; padding: 2px; border-style: solid; border-width: 1px" class="alert-warning">hasn't logged in since the ballot opened</span>; and
		<span style="display: inline-block; padding: 2px; border-style: solid; border-width: 1px" class="alert-danger">hasn't logged in since their slot opened</span>.
	</p>

	<p><em>Choice</em> indicates the room that the user actively selected on the website. The <em>Actual room</em> column shows the room these people most recently resided in. This column may contain multiple simultaneous rooms!</p>

	<table class="table table-condensed">
		<thead>
			<tr>
				<th></th>
				<th>Person<div class='small text-muted'>Last seen</div></th>
				<th colspan='2' class="rule-right">Slot time</th>
				<th>Choice<div class='small text-muted'>Choice time</div></th>
				<th>Actual room<div class='small text-muted'>Last updated</div></th>
			</tr>
		</thead>
		<tbody>
			% for i, s in enumerate(sorted(event.slots, key=lambda s: s.time), 1):
				% id, person, ts = (s.id, s.person, s.time)
				% occ = s.choice
				% final_occs = {
				% 	o for o in person.occupancies
				% 	if o.listing.ballot_season == event.season
				%   and not o.cancelled
				% }
				% t = datetime.now()
				% if occ:
					% cls = 'class="success"'
				% elif not person.last_seen or t > s.time and s.time > person.last_seen:
					% cls = 'class="danger"'
				% elif event.opens_at > person.last_seen.date():
					% cls = 'class="warning"'
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
						% include('parts/user-link', user=person, shrink=False)
						<div class='text-muted small'>{{! format_ts_html(s.person.last_seen)}}</div>
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
						% if occ:
							% if occ not in final_occs:
								<del>
							% end
							% room = occ.listing.room
							<a href='{{url_for(room) }}#occupancy-{{occ.id}}'>{{room.pretty_name() }}</a>
							<div class='text-muted small'>{{! format_ts_html(occ.chosen_at) }}</div>
							% if occ not in final_occs:
								</del>
							% end
						% end
					</td>

					<td>
						<!--
						% for i, o in enumerate(final_occs):
							% room = o.listing.room
							% if i != 0:
								-->; <!--
							% end
							--><a href='{{url_for(room) }}#occupancy-{{o.id}}'>{{room.pretty_name() }}</a><!--
						% end
						-->
						% if final_occs:
							<div class='text-muted small'>{{! format_ts_html(max(occ.chosen_at for occ in final_occs)) }}</div>
						% end
					</td>
				</tr>
			% end
		</tbody>
	</table>
</div>

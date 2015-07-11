<%
from collections import namedtuple

import database.orm as m
import json
from datetime import timedelta

rebase('layout')

def layout_breadcrumb():
	yield (
		url_for(ballot_event.season),
		'{} - {} season'.format(ballot_event.season.year, ballot_event.season.year + 1))
	yield ('#', ballot_event.type.name)
	yield ('#', 'slots')
end

def group_slots():
	group = []
	dt = None
	for sl in sorted(ballot_event.slots, key=lambda s: s.time):
		if not group:
			group.append(sl)
		else:
			ndt = sl.time - group[-1].time
			if dt is None and ndt < timedelta(hours=1):
				group.append(sl)
				dt = ndt
			elif dt == ndt:
				group.append(sl)
			else:
				yield dt, group
				group = [sl]
				dt = None
			end
		end
	end
	if group:
		yield dt, group
	end
end

%>
<style>
textarea {
	font-family: monospace;
}
</style>
<div class="container">
	<h1>{{ ballot_event.type.name }} ballot for {{ ballot_event.season }}</h1>
	<p>This page allows you to edit the times that people may choose their rooms in the ballot. Download the csv file below, edit it, and reupload it. It will be checked for errors. Hit save to accept the changes.</p>
	<div class="row">
		<div class="col-md-4">
			<h2>Edit</h2>
			<p>
				<a class="btn btn-primary btn-block" href="slots.csv">Download slots.csv</a>
			</p>
			<p class="small text-muted">
				We've had to suffix every date and crsid with an @. This stops excel doing <i>stupid</i> things like reordering the day and month, or converting crsids into dates.
			</p>
			<p class="small text-muted">
				Leave a date column empty to use the same date as the previous slot. Leave the time column empty to use a time 3 minutes later than the previous slot.
			</p>
			<table class="table small table-condensed" style="table-layout: fixed">
				<thead>
					<tr>
						<th>date</th>
						<th>time</th>
						<th>crsid</th>
						<th>name (ignored)</th>
					</tr>
				</thead>
				% last_date = None
				% for s in sorted(ballot_event.slots, key=lambda s: s.time)[:10]:
					<tr>
						% if s.time.date() != last_date:
							<td>{{ s.time.date() }}@</td>
							% last_date = s.time.date()
						% else:
							<td></td>
						% end
						<td>{{ s.time.time() }}</td>
						<td>{{ s.person.crsid }}@</td><td><div style="text-overflow: ellipsis; white-space: nowrap; overflow: hidden">{{ s.person.name }}</div></td>
					</tr>
				% end
				<tfoot>
					<tr>
						<td colspan="4" class="text-center lead">&#8230;</td>
					</tr>
				</tfoot>
			</table>
			<form action="" method="POST" enctype="multipart/form-data">
				<div class="form-group">
					<input type="file" class="form-control" name="slot_csv" />
				</div>
				<button class="btn btn-block btn-primary" type="submit">Upload new version</button>
			</form>
		</div>
		% if step2:
			% result, errors = step2
			<div class="col-md-4">
				<h2>Uploaded results</h2>
				% for error in errors:
					<div class="alert alert-danger">
						% cat, args = error[0], error[1:]
						% if cat == 'bad-header':
							Header row has been changed or removed - it should match the one in the file you downloaded
						% elif cat == 'no-date':
							First data row must contain a date
						% elif cat == 'no-time':
							First data row must contain a time
						% elif cat == 'bad-date':
							Invalid date column <code>{{args[0]}}</code> - expecting <code>YYYY-MM-DD@</code>
						% elif cat == 'bad-time':
							Invalid time column <code>{{args[0]}}</code> - expecting <code>HH:MM:SS</code>
						% elif cat == 'bad-crsid':
							No person can be found for the crsid <code>{{args[0]}}</code>
						% elif cat == 'slot-used-move':
							% s = args[0]
							% r = s.choice.listing.room
							% ts = args[1]
							Cannot change slot time for
							<a target="_blank" href="{{ url_for(s.person) }}">{{s.person.name}}</a>.
							They have already chosen
							<a target="_blank" href="{{ url_for(r) }}">{{ r.pretty_name() }}</a>!
							<p>
								<b>Old time:</b>{{ s.time }} <br />
								<b>New time:</b>{{ ts }}
							</p>
						% elif cat == 'slot-used-delete':
							% s = args[0]
							% r = s.choice.listing.room
							Cannot delete slot time for
							<a target="_blank" href="{{ url_for(s.person) }}">{{s.person.name}}</a>.
							They have already chosen
							<a target="_blank" href="{{ url_for(r) }}">{{ r.pretty_name() }}</a>!
						% else:
							Unknown error code <code>{{error}}</code>
						% end
					</div>
				% end
				<table class="table table-condensed">
					<tbody>
						<%
						include('parts/slot-list-rows', slot_tuples=(
							(None, p, d)
							for (p, d) in result.items()
						))
						%>
					</tbody>
				</table>
			</div>
			<div class="col-md-4">
				<h2>Changes</h2>
				<%
				old = sorted(ballot_event.slots, key=lambda s: s.time)
				old_lookup = {o.person.crsid: o.time for o in old}
				new_lookup = {u.crsid: t for u, t in result.items()}

				diffs = []
				for o in old:
					if o.person.crsid not in new_lookup:
						diffs.append(['remove', o.person, o.time])
					end
				end
				for o in old:
					if o.person.crsid in new_lookup:
						n_t = new_lookup[o.person.crsid]
						o_t = old_lookup[o.person.crsid]
						if n_t != o_t:
							diffs.append(['modify', o.person, o_t, n_t])
						end
					end
				end
				for (user, date) in result.items():
					if user.crsid not in old_lookup:
						diffs.append(['add', user, date])
					end
				end

				diffs = sorted(diffs, key=lambda d: d[2])
				%>
				% if diffs:
					<table class="table table-condensed">
						% last_day = None
						% for d in diffs:
							% mode, user, t = d[:3]
							% if mode == 'remove':
								<tr class="danger">
									<td>
										% include('parts/user-link', user=user)
									</td>
									% day = '{:%d %b}'.format(t)
									<td style="white-space: nowrap; width: 1px">
										{{ day if day != last_day else ''}}
									</td>
									% last_day = day
									<td style="width: 1px">
										{{ '{:%H:%M}'.format(t) }}
									</td>
								</tr>
							% elif mode == 'modify':
								% t2 = d[3]
								<tr class="warning">
									<td>
										% include('parts/user-link', user=user)
									</td>
									% if t.date() == t2.date():
										% day = '{:%d %b}'.format(t)
										<td style="white-space: nowrap; width: 1px">
											{{ day if day != last_day else ''}}
										</td>
										% last_day = day
										<td style="width: 1px">
											{{ '{:%H:%M}'.format(t) }}&nbsp;&#8594;&nbsp;{{ '{:%H:%M}'.format(t2) }}
										</td>
									% else:
										<td colspan="2" style="width: 1px">
											{{ '{:%d %b %H:%M}'.format(t) }} &#8594;<br />{{ '{:%d %b %H:%M}'.format(t2)  }}
										</td>
									% end
								</tr>
							% elif mode == 'add':
								<tr class="success">
									<td>
										% include('parts/user-link', user=user)
									</li>
									% day = '{:%d %b}'.format(t)
									<td style="white-space: nowrap; width: 1px">
										{{ day if day != last_day else ''}}
									</td>
									% last_day = day
									<td style="width: 1px">
										{{ '{:%H:%M}'.format(t) }}
									</td>
								</tr>
							% end
						% end
					</table>
					<form method="POST">
						<%
						j = json.dumps([
							(t.isoformat(), u.crsid) for u, t in result.items()
						])
						%>
						<input type="hidden" name="slot_json" value="{{ j }}" />
						% if errors:
							<div class="alert alert-danger">
								<strong>Are you sure?</strong>
								<p>There were {{ len(errors) }} errors in your data, shown on the left. The changelist above may likely not match what you intended.</p>
							</div>
						% end
						<button type="submit" class="btn btn-danger">Confirm changes</button>
					</form>
				% else:
					<div class="alert alert-info">
						<strong>Did you change anything?</strong>
						<p>The data all looks the same to us. Did you upload the right file?</p>
					</div>
				% end
			</div>
		% end
	</div>
</div>

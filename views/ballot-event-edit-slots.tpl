<%
from collections import namedtuple

import database.orm as m
import json
from datetime import timedelta

rebase('layout')

def layout_breadcrumb():
	yield (
		'/ballots/{}'.format(ballot_event.season.year),
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
	<form method="post">
		<button class="btn btn-primary btn-lg pull-right" type="submit">
			<span class="glyphicon glyphicon-floppy-disk"></span>
			Save
		</button>
		<h1>{{ ballot_event.type.name }} ballot for {{ ballot_event.season }}</h1>
		<p>Use the tree view in the left to column to select which rooms should be available in the ballot. The two other columns show changes, with additions shown in green, and deletions shown in red.</p>
		<div class="row">
			% it = group_slots()
			% import itertools
			% for day, slot_groups in itertools.groupby(it, key=lambda (dt, slots): slots[0].time.date()):
				<div class="col-md-6">
					<h2>{{ day }}</h2>
					% for dt, slots in slot_groups:
						<h3>
							{{ slots[0].time.time() }}
							% if dt:
								<small>every {{ dt }}</small>
							% end
						</h3>
						<textarea class="form-control" rows="{{ len(slots)}}">{{ '\n'.join('{t} - {s.person.crsid} ({s.person.name})'.format(s=s, t=s.time.time()) for s in slots) }}</textarea>
					% end
				</div>
			% end
		</div>
	</form>
</div>

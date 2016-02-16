<%
from collections import namedtuple

import database.orm as m
import json
from datetime import timedelta, date

rebase('layout')

def layout_breadcrumb():
	yield (
		url_for(ballot_event.season),
		u'{} season'.format(ballot_event.season)
	)
	yield ('#', ballot_event.type.name)
end
%>
<style>
textarea {
	font-family: monospace;
}
</style>
<div class="container">
	<h1>
		{{ ballot_event.type.name }} ballot for {{ ballot_event.season }}
		% if ballot_event.is_active:
			<span class="label label-success">In progress</span>
		% elif ballot_event.opens_at > date.today():
			<span class="label label-warning">Scheduled</span>
		% else:
			<span class="label label-default">Complete</span>
		% end
	</h1>

	<div class="row">
		<div class="col-md-4">
			<h2>Times</h2>
			<p>
				These control when the balloting interface will be shown to balloters.
				It should open before the first slot, so people can check they're in a ballot, and close well after the last slot.
			</p>
			<form method="POST">
				<div class="form-group">
					<label for="opens_at-input">Opens at</label>
					<input id="opens_at-input" name="opens_at" value="{{ ballot_event.opens_at }}" type="date" class="form-control" />
				</div>
				<div class="form-group">
					<label for="closes_at-input">Closes at</label>
					<input id="closes_at-input" name="closes_at" value="{{ ballot_event.closes_at }}" type="date" class="form-control" />
				</div>
				<button type="submit" class="btn btn-default btn-block">update times</button>
			</form>
		</div>
		<div class="col-md-4">
			<h2>Rooms <small>{{ sum(ballot_event.type in l.audience_types for l in ballot_event.season.room_listings) }}</small></h2>
			<a class="btn btn-block btn-default" href="edit-rooms">edit</a>
		</div>
		<div class="col-md-4">
			<h2>Students <small>{{ len(ballot_event.slots) }}</small></h2>
			<a class="btn btn-block btn-default" href="edit-slots">edit</a>
		</div>
	</div>
</div>

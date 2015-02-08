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
end
%>
<style>
textarea {
	font-family: monospace;
}
</style>
<div class="container">
	<h1>{{ ballot_event.type.name }} ballot for {{ ballot_event.season }}</h1>
	<div class="row">
		<div class="col-md-4">
			<h2>Rooms</h2>
			<a class="btn btn-block btn-default" href="edit-rooms">edit</a>
		</div>
		<div class="col-md-4">
			<h2>Slots</h2>
			<a class="btn btn-block btn-default" href="edit-slots">edit</a>
		</div>
		<div class="col-md-4">
			<h2>Rents</h2>
			<a class="btn btn-block btn-default" href="edit-rents">edit</a>
		</div>
	</div>
</div>

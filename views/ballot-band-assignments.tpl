% import database.orm as m
% from bottle import request
% from collections import Counter, defaultdict
% import sqlalchemy.orm.exc
% rebase('layout')

<%

def flatten_iter(p, level=0, path=[]):
	for c in p.children:
		yield c, level, path
		for np, nlevel, npath in flatten_iter(c, level + 1, path=path+[c]):
			yield np, nlevel, npath
		end
	end
end

def layout_breadcrumb():
	yield (url_for(ballot_season), u'{} season'.format(ballot_season))
	yield ('#', u'Bands')
end

# d[old_band, new_band] = {room1, room2}
changed_bands = defaultdict(set)

# extract listings keyed by room
curr_by_room = { l.room: l for l in ballot_season.room_listings }
if ballot_season.previous:
	prev_by_room = { l.room: l for l in ballot_season.previous.room_listings	}
else:
	prev_by_room = {}
end

# group them by added/removed/changed
still_listed = {
	k: (prev_by_room[k], curr_by_room[k])
	for k in curr_by_room.viewkeys() & prev_by_room.viewkeys()
}
newly_listed = {
	k: curr_by_room[k]
	for k in curr_by_room.viewkeys() - prev_by_room.viewkeys()
}
not_listed = {
	k: prev_by_room[k]
	for k in prev_by_room.viewkeys() - curr_by_room.viewkeys()
}

# Repeat, but now do so by banding
with_removed_bands = {}
with_removed_bands.update({k: v  for k, v        in not_listed.iteritems()   if v.band})
with_removed_bands.update({k: v1 for k, (v1, v2) in still_listed.iteritems() if v1.band and not v2.band})

with_changed_bands = {k: (v1, v2) for k, (v1, v2) in still_listed.iteritems() if v1.band and v2.band and v1.band != v2.band}

with_added_bands = {}
with_added_bands.update({k: v  for k, v        in newly_listed.iteritems() if v.band})
with_added_bands.update({k: v2 for k, (v1, v2) in still_listed.iteritems() if not v1.band and v2.band})

# Repeat, but now do so by modifiers
with_removed_modifiers = {}
with_removed_modifiers.update({k: v  for k, v        in not_listed.iteritems()   if v.modifiers})
with_removed_modifiers.update({k: v1 for k, (v1, v2) in still_listed.iteritems() if v1.modifiers and not v2.modifiers})

with_changed_modifiers = {k: (v1, v2) for k, (v1, v2) in still_listed.iteritems() if v1.modifiers and v2.modifiers and v1.modifiers != v2.modifiers}

with_added_modifiers = {}
with_added_modifiers.update({k: v  for k, v        in newly_listed.iteritems() if v.modifiers})
with_added_modifiers.update({k: v2 for k, (v1, v2) in still_listed.iteritems() if not v1.modifiers and v2.modifiers})
%>
<div class="container">
	<h1>Banding and modifier changes for {{ ballot_season }}</h1>
	<h2>Bands</h2>
	<div class="row">
		<div class="col-md-4">
			<h3>Removed</h3>
			<table class='table table-condensed sortable' id="place-heirarchy">
				<thead>
					<tr>
						<th>Room</th>
						<th>Band</th>
					</tr>
				</thead>
				<tbody>
					% for room, listing in sorted(with_removed_bands.items(), key=lambda p: p[0].pretty_name()):
						<tr>
							<td>
								<a href="{{ url_for(room) }}">{{ room.pretty_name() }}</a>
							</td>
							<td>
								<span class="label" style="background-color: #{{listing.band.color}}" title="{{listing.band.description}}">
									{{listing.band.name}}
								</span>
							</td>
						</tr>
					% end
				</tbody>
			</table>
		</div>
		<div class="col-md-4">
			<h3>Changed</h3>
			<table class='table table-condensed sortable' id="place-heirarchy">
				<thead>
					<tr>
						<th>Room</th>
						<th>Old band</th>
						<th>New band</th>
					</tr>
				</thead>
				<tbody>
					% for room, (listing1, listing2) in sorted(with_changed_bands.items(), key=lambda p: p[0].pretty_name()):
						<tr>
							<td>
								<a href="{{ url_for(room) }}">{{ room.pretty_name() }}</a>
							</td>
							<td>
								% if listing1.band:
									<span class="label" style="background-color: #{{listing1.band.color}}" title="{{listing1.band.description}}">
										{{listing1.band.name}}
									</span>
								% else:
									<span class="text-muted">None</span>
								% end
							</td>
							<td>
								% if listing2.band:
									<span class="label" style="background-color: #{{listing2.band.color}}" title="{{listing2.band.description}}">
										{{listing2.band.name}}
									</span>
								% else:
									<span class="text-muted">None</span>
								% end
							</td>
						</tr>
					% end
				</tbody>
			</table>
		</div>
		<div class="col-md-4">
			<h3>Added</h3>
			<table class='table table-condensed sortable' id="place-heirarchy">
				<thead>
					<tr>
						<th>Room</th>
						<th>Band</th>
					</tr>
				</thead>
				<tbody>
					% for room, listing in sorted(with_added_bands.items(), key=lambda p: p[0].pretty_name()):
						<tr>
							<td>
								<a href="{{ url_for(room) }}">{{ room.pretty_name() }}</a>
							</td>
							<td>
								<span class="label" style="background-color: #{{listing.band.color}}" title="{{listing.band.description}}">
									{{listing.band.name}}
								</span>
							</td>
						</tr>
					% end
				</tbody>
			</table>
		</div>
	</div>

	<h2>Modifiers</h2>
	<div class="row">
		<div class="col-md-4">
			<h3>Removed</h3>
			<table class='table table-condensed sortable' id="place-heirarchy">
				<thead>
					<tr>
						<th>Room</th>
						<th>Modifier</th>
					</tr>
				</thead>
				<tbody>
					% for room, listing in sorted(with_removed_modifiers.items(), key=lambda p: p[0].pretty_name()):
						<tr>
							<td>
								<a href="{{ url_for(room) }}">{{ room.pretty_name() }}</a>
							</td>
							<td>
								{{ ', '.join(m.name for m in listing.modifiers) }}
							</td>
						</tr>
					% end
				</tbody>
			</table>
		</div>
		<div class="col-md-4">
			<h3>Changed</h3>
			<table class='table table-condensed sortable' id="place-heirarchy">
				<thead>
					<tr>
						<th>Room</th>
						<th>Old modifier</th>
						<th>New modifier</th>
					</tr>
				</thead>
				<tbody>
					% for room, (listing1, listing2) in sorted(with_changed_modifiers.items(), key=lambda p: p[0].pretty_name()):
						<tr>
							<td>
								<a href="{{ url_for(room) }}">{{ room.pretty_name() }}</a>
							</td>
							<td>
								{{ ', '.join(m.name for m in listing1.modifiers) }}
							</td>
							<td>
								{{ ', '.join(m.name for m in listing2.modifiers) }}
							</td>
						</tr>
					% end
				</tbody>
			</table>
		</div>
		<div class="col-md-4">
			<h3>Added</h3>
			<table class='table table-condensed sortable' id="place-heirarchy">
				<thead>
					<tr>
						<th>Room</th>
						<th>Modifier</th>
					</tr>
				</thead>
				<tbody>
					% for room, listing in sorted(with_added_modifiers.items(), key=lambda p: p[0].pretty_name()):
						<tr>
							<td>
								<a href="{{ url_for(room) }}">{{ room.pretty_name() }}</a>
							</td>
							<td>
								{{ ', '.join(m.name for m in listing2.modifiers) }}
							</td>
						</tr>
					% end
				</tbody>
			</table>
		</div>
	</div>
</div>

<%
import database.orm as m
from bottle import request
from utils import restricted
from sqlalchemy.orm.session import object_session

if isinstance(ballot, m.BallotEvent):
	ballot_event = ballot
	ballot = ballot.season
else:
	ballot_event = None
end

n = roomsq.count()
for f in filters:
	roomsq = roomsq.filter(f)
end
rooms = roomsq.all()

# try and categorize listings
last_listings = {
	room: room.listing_for.get(ballot)
	for room in rooms
}
listing_state = {}
for room in rooms:
	last_listing = last_listings[room]
	is_listed = bool(last_listing)
	if ballot_event:
		is_in_ballot = is_listed and (ballot_event.type in last_listing.audience_types or bool(last_listing.occupancies))
	else:
		is_in_ballot = is_listed and not last_listing.bad_listing
	end

	listing_state[room] = is_listed, is_in_ballot
end

rooms.sort(
	key=lambda r: (
		listing_state[room],
		r.stats.adjusted_rating,
		r.stats.photo_count,
		-r.id
	),
	reverse=True
)
%>
<div class="dropdown pull-right">
	<button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">
		Change year
		<span class="caret"></span>
	</button>
	<ul class="dropdown-menu dropdown-menu-right" role="menu" aria-labelledby="dropdownMenu1">
		% ballots = object_session(ballot).query(m.BallotSeason).order_by(m.BallotSeason.year.desc())
		% for b in ballots:
			<li {{! 'class="active"' if b == ballot else '' }} >
				<a href="?ballot={{ b.year }}">{{ b }}</a>
			</li>
		% end

	</ul>
</div>
<p>
	<span class="lead">
		% if len(rooms) == n:
			Showing all {{n}} rooms
		% else:
			Showing {{len(rooms)}} of {{ n }}
		% end
	</span><br />
	<small class="text-muted">Owners and prices show are for the year {{ ballot}}</small>
	% if not ballot_event:
		<div class="text-muted small">
			Row colors indicate
			<span style="display: inline-block; padding: 2px; border-style: solid; border-width: 1px" class="alert-success">your favorites</span>;
			<span style="display: inline-block; padding: 2px; border-style: solid; border-width: 1px" class="alert-warning">not ballotable yet, but may be in a future ballot</span>; and
			<span style="display: inline-block; padding: 2px; border-style: solid; border-width: 1px" class="alert-danger">no information for this year</span>.
		</div>
	% end
</p>
<div class="table-responsive">
<table class="table table-condensed table-hover sortable">
	<thead>
		<%
		skip_place = True
		for room in rooms:
			containing_place = room.parent
			if containing_place.type == 'staircase' and containing_place != relative_to:
				containing_place = containing_place.parent
			end
			if containing_place != relative_to:
				skip_place = False
			end
		end
		%>
		<tr>
			% if skip_place:
				<th class="rule-right" style="text-align: right">Room</th>
			% else:
				<th style="text-align: right">Room</th>
				<th class="rule-right">Block</th>
			% end
			<th>Rent</th>
			<th>Area</th>
			<th class="rule-right">Rating</th>
			<th data-defaultsort='disabled' colspan="4" class="rule-right" style="text-align: center">Feedback</th>
			<th data-defaultsort='disabled' colspan="3" style="text-align: center" class="rule-right">Features</th>
			<th>
				% if request.user:
					Owner
				% else:
					{{! restricted("Owner") }}
				% end
			</th>
		</tr>
	</thead>
	<tbody>
		% for room in rooms:
			<%
			containing_place = room.parent
			if containing_place.type == 'staircase' and containing_place != relative_to:
				containing_place = containing_place.parent
			end

			last_listing = last_listings[room]
			is_listed, is_in_ballot = listing_state[room]
			lookup = {
				# listed, b
				(True, True): '',
				(True, False): 'warning',
				(False, False): 'danger'
			}
			if ballot_event and not is_in_ballot and not request.query.show_all:
				continue
			end
			%>

			<tr class="room {{ lookup[is_listed, is_in_ballot]}}" data-roomid="{{ room.id }}">
				<td class="shrink{{ ' rule-right' if skip_place else '' }}" style="text-align: right">
					<a href="{{ url_for(room) }}">{{room.pretty_name(containing_place) }}</a>
				</td>
				% if not skip_place:
					<td class="rule-right">
						<a href="{{ url_for(containing_place) }}">{{ containing_place.pretty_name(relative_to) }}</a>
					</td>
				% end
				<td>
					% if last_listing and last_listing.rent:
						£{{ last_listing.rent }}
					% end
				</td>
				<%
				b_w, b_h = room.bedroom_x, room.bedroom_y
				l_w, l_h = room.living_room_x, room.living_room_y

				area = (b_w * b_h if b_w else 0) + (l_w * l_h if l_w else 0)
				%>
				<td data-value="{{area if b_w or l_w else -1}}">
					% if b_w or l_w:
						{{area}}<span class="hidden-xs">&nbsp;ft&sup2;</span>
					% end
					<span class="hidden-xs text-muted">
						% if b_w and l_w:
							({{b_w}}&times;{{b_h}} + {{l_w}}&times;{{l_h}})
						% elif b_w:
							({{b_w}}&times;{{b_h}})
						% elif l_w:
							({{l_w}}&times;{{l_h}})
						% end
					</span>
				</td>
				<td class="rule-right" data-value="{{room.stats.adjusted_rating or 0}}"
					{{! 'title="from {} ratings"'.format(room.stats.rating_count) if room.stats.adjusted_rating else ''}}
					>
					%if room.stats.adjusted_rating is not None:
						{{ '{:.1f}'.format(room.stats.adjusted_rating) }}<span class="hidden-xs">/10</span>
					% end
				</td>
				<td class="shrink center">
					% n = room.stats.review_count
					% if n:
						% m = '1 review' if n == 1 else '{} reviews'.format(n)
						<a href="{{ url_for(room) }}#reviews" style="color: inherit; text-decoration: none">
							<span class="hidden-xs" style="display: inline-block; width: 2ex; text-align: right">{{ n if n != 1 else '' }}</span>
							<span class="glyphicon glyphicon-comment" title="{{m}}"></span>
						</a>
					% end
				</td>
				<td class="shrink center">
					% n = room.stats.resident_count
					% if n:
						% m = '1 recorded resident' if n == 1 else '{} recorded residents'.format(n)
						% if n != 0:
							<span class="hidden-xs" style="display: inline-block; width: 2ex; text-align: right">{{ n if n != 1 else '' }}</span>
							<span class="glyphicon glyphicon-user" title="{{m}}"></span>
						% end
					% end
				</td>
				<td class="shrink center">
					% n = room.stats.photo_count
					% if n:
						% m = '1 photo' if n == 1 else '{} photos'.format(n)
						<a href="{{ url_for(room) }}#photos" style="color: inherit; text-decoration: none">
							<span class="hidden-xs" style="display: inline-block; width: 2ex; text-align: right">{{ n if n != 1 else '' }}</span>
							<span class="glyphicon glyphicon-picture" title="{{m}}"></span>
						</a>
					% end
				</td>
				<td class="shrink center rule-right">
					% n = room.stats.reference_count
					% if n:
						% m = '1 reference' if n == 1 else '{} references'.format(n)
						<a href="{{ url_for(room) }}#references" style="color: inherit; text-decoration: none">
							<span class="hidden-xs" style="display: inline-block; width: 2ex; text-align: right">{{ n if n != 1 else '' }}</span>
							<span class="glyphicon glyphicon-link" title="{{m}}"></span>
						</a>
					% end
				</td>
				<td class="shrink center">
					% e = room.is_set
					% if e == True:
						<span class="glyphicon glyphicon-th-large text-success" title="Set"></span>
					% elif e is None:
						<span class="glyphicon glyphicon-th-large text-muted" title="Possibly a set"></span>
					% end
				</td>
				<td class="shrink center">
					% e = room.is_ensuite
					% if e == True:
						<span class="glyphicon glyphicon-certificate text-success" title="Ensuite"></span>
					% elif e is None:
						<span class="glyphicon glyphicon-certificate text-muted" title="Possible ensuite"></span>
					% end
				</td>
				<td class="shrink center rule-right">
					% w = room.has_washbasin
					% if w == True:
						<span class="glyphicon glyphicon-tint text-success" title="Washbasin"></span>
					% elif w is None:
						<span class="glyphicon glyphicon-tint text-muted" title="Possible Washbasin"></span>
					% end
				</td>
				% 
				% if request.user and last_listing:
					% occupancies = [occ for occ in last_listing.occupancies if not occ.cancelled]
					% resident = occupancies and occupancies[0].resident
				% else:
					% occupancies = []
					% resident = None
				% end
				% if resident:
					<td style="vertical-align: middle" class="small" data-value="{{ resident.crsid }}">
						<a href="{{ url_for(resident) }}" style="display: inline-block; padding-left: 20px;">
							<img src="{{ resident.gravatar(size=15) }}" width="15" height="15" style="margin-left: -20px; float: left" />
							{{resident.name}}
						</a>
					</td>
				% elif occupancies:
					<td style="vertical-align: middle" class="small" data-value="!">
						<span class="text-muted">not recorded</span>
					</td>
				% else:
					<td></td>
				% end
				</td>
			</tr>
		% end
	</tbody>
	<script>
	$('.room').each(function() {
		if(localStorage['favorited-' + $(this).data('roomid')]) {
			$(this).addClass('success');
		}
	});
	</script>
</table>
</div>
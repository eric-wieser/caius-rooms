% import database.orm as m
% from bottle import request
% from utils import restricted

<table class="table table-condensed table-hover sortable">
	<thead>
		% skip_place = True
		% for room in rooms:
			% containing_place = room.parent
			% if containing_place.type == 'staircase' and containing_place != relative_to:
				% containing_place = containing_place.parent
			% end
			% if containing_place != relative_to:
				% skip_place = False
			% end
		% end
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
			% if not request.user:
				<th data-defaultsort='disabled' colspan="3" style="text-align: center">Features</th>
			% else:
				<th data-defaultsort='disabled' colspan="3" style="text-align: center" class="rule-right">Features</th>
				<th>Owner</th>
			% end
		</tr>
	</thead>
	<tbody>
		% for room in rooms:
			% containing_place = room.parent
			% if containing_place.type == 'staircase' and containing_place != relative_to:
				% containing_place = containing_place.parent
			% end

			% last_listing = room.listing_for.get(ballot)

			<tr class="room{{ ' warning' if not last_listing else ''}}" data-roomid="{{ room.id }}">
				<td class="shrink{{ ' rule-right' if skip_place else '' }}" style="text-align: right">
					% if room.is_suite:
						<span class="glyphicon glyphicon-th-large text-muted" title="Suite"></span>
					% end
					<a href="/rooms/{{room.id}}">{{room.pretty_name(containing_place) }}</a>
				</td>
				% if not skip_place:
					<td class="rule-right">
						<a href="{{ get_url('place', place_id=containing_place.id) }}">{{ containing_place.pretty_name(relative_to) }}</a>
					</td>
				% end
				<td>
					% if last_listing and last_listing.rent:
						£{{ last_listing.rent }}
					% end
				</td>
				% b_w, b_h = room.bedroom_x, room.bedroom_y
				% l_w, l_h = room.living_room_x, room.living_room_y

				% area = (b_w * b_h if b_w else 0) + (l_w * l_h if l_w else 0)
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
				<td class="rule-right" data-value="{{room.adjusted_rating or 0}}">
					%if room.adjusted_rating is not None:
						{{ '{:.1f}'.format(room.adjusted_rating) }}<span class="hidden-xs">/10</span>
					% end
				</td>
				<td class="shrink center">
					% n = room.review_count
					% if n:
						% m = '1 review' if n == 1 else '{} reviews'.format(n)
						<a href="/rooms/{{room.id}}#reviews" style="color: inherit; text-decoration: none">
							<span class="hidden-xs" style="display: inline-block; width: 2ex; text-align: right">{{ n if n != 1 else '' }}</span>
							<span class="glyphicon glyphicon-comment" title="{{m}}"></span>
						</a>
					% end
				</td>
				<td class="shrink center">
					% n = room.resident_count
					% if n:
						% m = '1 recorded resident' if n == 1 else '{} recorded residents'.format(n)
						% if n != 0:
							<span class="hidden-xs" style="display: inline-block; width: 2ex; text-align: right">{{ n if n != 1 else '' }}</span>
							<span class="glyphicon glyphicon-user" title="{{m}}"></span>
						% end
					% end
				</td>
				<td class="shrink center">
					% n = room.photo_count
					% if n:
						% m = '1 photo' if n == 1 else '{} photos'.format(n)
						<a href="/rooms/{{room.id}}#photos" style="color: inherit; text-decoration: none">
							<span class="hidden-xs" style="display: inline-block; width: 2ex; text-align: right">{{ n if n != 1 else '' }}</span>
							<span class="glyphicon glyphicon-picture" title="{{m}}"></span>
						</a>
					% end
				</td>
				<td class="shrink center rule-right">
					% n = room.reference_count
					% if n:
						% m = '1 reference' if n == 1 else '{} references'.format(n)
						<a href="/rooms/{{room.id}}#references" style="color: inherit; text-decoration: none">
							<span class="hidden-xs" style="display: inline-block; width: 2ex; text-align: right">{{ n if n != 1 else '' }}</span>
							<span class="glyphicon glyphicon-link" title="{{m}}"></span>
						</a>
					% end
				</td>
				<td class="shrink center">
					% n = last_listing and last_listing.has_ethernet
					% if n == True:
						<span class="glyphicon glyphicon-cloud text-success" title="Ethernet"></span>
					% elif n == False:
						<span class="glyphicon glyphicon-cloud text-danger" title="No Ethernet"></span>
					% else:
						<span class="glyphicon glyphicon-cloud text-muted" title="Possible Ethernet"></span>
					% end
				</td>
				<td class="shrink center">
					% w = last_listing and last_listing.has_washbasin
					% if w == True:
						<span class="glyphicon glyphicon-tint text-success" title="Washbasin"></span>
					% elif w == False:
						<span class="glyphicon glyphicon-tint text-danger" title="No Washbasin"></span>
					% else:
						<span class="glyphicon glyphicon-tint text-muted" title="Possible Washbasin"></span>
					% end
				</td>
				<td class="shrink center  rule-right">
					% p = last_listing and last_listing.has_piano
					% if p == True:
						<span class="glyphicon glyphicon-music text-success" title="Piano"></span>
					% elif p == False:
						<span class="glyphicon glyphicon-music text-danger" title="No Piano"></span>
					% else:
						<span class="glyphicon glyphicon-music text-muted" title="Possible Piano"></span>
					% end
				</td>
				% if request.user:
					<td>
						% if last_listing and last_listing.occupancies and last_listing.occupancies[0].resident:
							% resident = last_listing.occupancies[0].resident
							<small>
								<a href="/users/{{ resident.crsid }}">
									{{resident.name}}
								</a>
							</small>
						% end
					</td>
				% end
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
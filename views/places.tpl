<%
import database.orm as m

rebase('layout')
layout_random = "/places/random"

def flatten_iter(p, level=0, path=[]):
	for c in p.children:
		yield c, level, path
		for np, nlevel, npath in flatten_iter(c, level + 1, path=path+[c]):
			yield np, nlevel, npath
		end
	end
end

if isinstance(ballot, m.BallotEvent):
	ballot_event = ballot
	ballot_season = ballot.season
else:
	ballot_event = None
	ballot_season = ballot
end

n_free_by_loc = {
	sub_loc: sum(
		1
		for room in sub_loc.rooms
		if ballot_season in room.listing_for
		if ballot_event is None or ballot_event.type in room.listing_for[ballot_season].audience_types
		if all(occ.cancelled for occ in room.listing_for[ballot_season].occupancies)
	)
	for i, (sub_loc, level, path) in enumerate(flatten_iter(location))
}

def n_free_nested(loc):
	return n_free_by_loc[loc] + sum(n_free_nested(subloc) for subloc in loc.children)
end


%>
<div class="container">
	<table class="table table-condensed table-hover sortable" id="place-heirarchy">
		<thead>
			<tr>
				<th>Place</th>
				<th>Free rooms</th>
				<th>Mean Rating</th>
			</tr>
		</thead>
		<tbody>
			% for i, (sub_loc, level, path) in enumerate(flatten_iter(location)):
				<%
				if not sub_loc.rooms:
					continue
				end
				%>
				<tr>
					<td {{! 'colspan="3"' if not sub_loc.rooms else '' }} data-value="{{ i }}">
						% for j, p in enumerate(path):
							<a class="small parent-link" style="margin-left: {{ 2 * j }}rem; display: block"
							   href="{{ url_for(p) }}"
							   data-id="{{ p.id }}">{{ p.pretty_name(p.parent) }}</a>
						% end
						<a style="margin-left: {{ 2 * level }}rem; "
						   href="{{ url_for(sub_loc) }}">{{ sub_loc.pretty_name(sub_loc.parent) }}</a>
						% if sub_loc.summary:
							<span class="glyphicon glyphicon-info-sign text-success" title='Has place summary'></span>
						% end
					</td>
					% if sub_loc.rooms:
						<%
						n_rooms = len(sub_loc.rooms)
						n_free = n_free_by_loc[sub_loc]
						%>
						<td data-value="{{n_free}}">
							{{ n_free }} / {{ n_rooms }}
						</td>
						% ratings = [r.stats.adjusted_rating for r in sub_loc.rooms if r.stats.adjusted_rating is not None]
						<td>
							% if ratings:
								{{ '{:.1f}'.format(sum(ratings) / len(ratings)) }}
							% end
						</td>
					% end
				</tr>
			% end
		</tbody>
	</table>
	<div id="map" style="height: 400px; margin-top: 10px"></div>
		<script src="https://maps.googleapis.com/maps/api/js?v=3.exp&amp;sensor=false"></script>
		<script>
			% import json
			google.maps.visualRefresh = true;

			var mapElem = $('#map');

			function initialize() {
				var opts;
			    map = new google.maps.Map(mapElem[0], opts = {
					zoom: 14,
					center: new google.maps.LatLng(52.20675, 0.1223485),
					disableDefaultUI: true,
					draggable: true,
					zoomControl: false,
					scaleControl: false,
					scrollwheel: false,
					mapTypeId: google.maps.MapTypeId.ROADMAP,
					styles: [
						{
							featureType: "poi",
							elementType: "labels",
							stylers: [
								{visibility: "off" }
							]
						}, {
							featureType: "administrative",
							elementType: "labels",
							stylers: [
								{visibility: "off" }
							]
						}
					]
				});

				% data = [dict(coords=loc.geocoords, name=loc.pretty_name(), id=loc.id, nf=n_free_nested(loc)) for loc, _, _ in flatten_iter(location) if loc.latitude and loc.longitude]
				var data = {{! json.dumps(data) }};

				var windows = [];
				windows = data.map(function(d) {
					var color = d.nf == 0 ? '#d9534f' :
							             d.nf < 5 ? '#f0ad4e' : '#5cb85c';
					var marker = new google.maps.Marker({
						position: new google.maps.LatLng(d.coords[0], d.coords[1]),
						map: map,
						icon: {
							path: google.maps.SymbolPath.CIRCLE,
							scale: 8,
							strokeWeight: 2,
							fillOpacity: 0.75,
							strokeColor: color,
							fillColor: color
						}
					});
					var infoWindow = new google.maps.InfoWindow({
						maxWidth: 200,
						content: $('<div>').append(
							$('<a>').attr('href', '/places/'+d["id"]).text(d["name"]),
							$('<br>'),
							$('<small>').text(d.nf == 1 ? '1 space' : d.nf + ' spaces')
						).html()
					});
					marker.addListener('click', function(evt) {
						infoWindow.open(map, marker);
						windows.filter(function(w) { return w != infoWindow; }).forEach(function(w) { w.close(); });
					});
					return infoWindow;
				});

				var active = false;
				mapElem.on('click', function(e) {
					active = true;
					map.setOptions({scrollwheel: true});
				}).on('mouseout', function() {
					map.setOptions({scrollwheel: false});
				})
			}

			initialize();
		</script>
	<style>
	#place-heirarchy td {
		vertical-align: bottom;
	}
	.parent-link {
		text-transform: small-caps;
		font-weight: bold;
		color: rgb(119, 119, 119);
	}
	</style>
	<script>
	$('#place-heirarchy').on('sorted', function() {
		var last = [];
		$(this).children('tbody').children('tr').each(function() {
			var $cell = $(this).find('td').eq(0);
			var $parents = $cell.find('a.parent-link');

			var ids = $parents.map(function() { return $(this).data('id'); }).get()

			$parents.show().each(function(i) {
				if(ids[i] == last[i])
					$(this).hide();
				else
					return false;
			})

			last = ids;
		})
	});
	</script>
</div>

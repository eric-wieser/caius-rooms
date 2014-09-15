% rebase layout.tpl

% def layout_breadcrumb():
	% for part in location.path:
		% yield ("/places/{}".format(part.id), part.pretty_name(part.parent))
	% end
% end

% def layout_extra_nav():
	<li><a href="{{ get_url('place-photos', place_id=location.id) }}">
		<span class="glyphicon glyphicon-picture"></span> Photos
	</a></li>
% end

% layout_random = '/places/random'

% import itertools

<div class="container">
	% filtered_rooms = location.all_rooms_q.all()
	% for filter in filters:
		% filtered_rooms = [room for room in filtered_rooms if filter(room)]
	% end

	% filtered_rooms.sort(key=lambda r: (r.adjusted_rating, r.photo_count, -r.id), reverse=True)
	<p class="lead">
		{{len(filtered_rooms)}} rooms
	</p>

	<ul class="list-group">
		% for filter in filters:
			<li class="list-group-item">{{filter.description}}</li>
		% end
	</ul>
	% include room-table.tpl rooms=filtered_rooms, skip_place=True, relative_to=location

	<div id="map" style="height: 400px"></div>
	% lat_lon = location.geocoords
	% if lat_lon:
		<script>
			google.maps.visualRefresh = true;

			var loc = new google.maps.LatLng(
				{{ lat_lon[0] }},
				{{ lat_lon[1] }}
			);
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
				new google.maps.Marker({position: loc}).setMap(map);

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
	% end
</div>
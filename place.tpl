% rebase layout.tpl place=place
% import itertools

<div class="container">
	% filtered_rooms = [r for r in rooms if r['place'] == place]
	% for filter in filters:
		% filtered_rooms = [room for room in filtered_rooms if filter(room)]
	% end

	% filtered_rooms.sort(key=lambda r: (r['bayesian_rank'], len(r['images']), -r['id']), reverse=True)
	<p class="lead">
		{{len(filtered_rooms)}} rooms
	</p>

	<ul class="list-group">
		% for filter in filters:
			<li class="list-group-item">{{filter.description}}</li>
		% end
	</ul>
	% include room-table.tpl rooms=filtered_rooms, skip_place=True

	<div id="map" style="height: 400px"></div>
	% try:
	<script>
		google.maps.visualRefresh = true;

		var loc = new google.maps.LatLng(
			{{ place['location']['lat'] }},
			{{ place['location']['lng'] }}
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
			new google.maps.Marker({position: loc}).setMap(map)
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
	% except KeyError:
		% pass
	% end
</div>

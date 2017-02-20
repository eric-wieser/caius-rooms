<%
rebase('layout')
import utils
from bottle import request

def layout_breadcrumb():
	for part in location.path:
		yield (url_for(part), part.pretty_name(part.parent))
	end
end

def layout_extra_nav(): %>
	<li><a href="{{ get_url('place-photos', place_id=location.id) }}">
		<span class="glyphicon glyphicon-picture"></span> Photos
	</a></li>
	<%
end

layout_random = '/places/random'

user_can_edit = request.user and request.user.is_admin

import itertools
%>
<div class="container">
	% roomsq = location.all_rooms_q

	<h1>{{ location.pretty_name() }}</h1>

	% include('parts/room-table', roomsq=roomsq, ballot=ballot, relative_to=location)
	<hr />

	% if location.summary:
		<div class="anchor" id="summary">
			% include('parts/markdown', content=location.summary.markdown_content, columnize=True)
		</div>
		<%
		editors = []
		for s in location.summaries:
			if s.editor not in editors:
				editors.append(s.editor)
			end
		end
		%>
		<div class="row">
			<div class="col-xs-6">
				% if user_can_edit:
					<a class="btn btn-primary btn-sm" href="{{url_for(location, extra_path='edit') }}">
						Edit
					</a>
				% end
			</div>
			<div class="col-xs-6 text-right text-muted small">
				Contributed by <!--
				% for i, person in enumerate(editors):
					% if i != 0:
						-->, <!--
					% end
					--><a href="{{url_for(person)}}">{{person.name}}</a><!--
				% end
				-->
				&bullet;
				<a href="{{ url_for(location, extra_path='revisions') }}" class='text-muted'>{{! utils.format_ts_html(location.summary.published_at) }}</a>
			</div>
		</div>
		<hr />
	% elif user_can_edit:
		<div class='text-center'>
			<p class="lead text-muted">No place summary yet</p>
			<a class="btn btn-lg btn-success" href="{{url_for(location, extra_path='edit') }}">Write one</a>
		</div>
		<hr />
	% end
	% lat_lon = location.geocoords
	% if lat_lon:
		<div id="map" style="height: 400px; margin-top: 10px"></div>
		<script src="https://maps.googleapis.com/maps/api/js?v=3.exp&amp;sensor=false"></script>
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

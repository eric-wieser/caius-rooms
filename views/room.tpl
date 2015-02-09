<%
from utils import format_ts_html, restricted
from bottle import request
import json
from datetime import datetime

rebase('layout')

layout_random = '/rooms/random'

def layout_breadcrumb():
	for part in room.parent.path:
		yield (url_for(part), part.pretty_name(part.parent))
	end
	yield ('#', room.pretty_name(room.parent))
end

def layout_extra_nav(): %>
	<li style="display: none"><a href="#info"></a></li>
	<li><a href="#photos">
		<span class="glyphicon glyphicon-picture"></span> <span class="hidden-sm">Photos</span>
	</a></li>
	<li><a href="#reviews">
		<span class="glyphicon glyphicon-comment"></span> <span class="hidden-sm">Reviews</span>
	</a></li>
	<li><a href='#' id="favorite" title="Record as favorite on this PC">
		<span class="glyphicon glyphicon-star"></span> <span class="hidden-sm">Favorite</span>
	</a></li>
	<script>
	var thisRoom = {{! json.dumps(room.id) }};
	if(localStorage['favorited-' + thisRoom])
		$('#favorite').parent().addClass('alert-success');

	$('#favorite').click(function() {
		if(localStorage['favorited-' + thisRoom]) {
			delete localStorage['favorited-' + thisRoom];
			$('#favorite').parent().removeClass('alert-success');
		}
		else {
			localStorage['favorited-' + thisRoom] = true;
			$('#favorite').parent().addClass('alert-success');
		}
	});
	</script>
<% end
%>

<div style="margin-bottom: 6em" itemscope itemtype="http://schema.org/Product">
<div class="container">
	<%
	active_listing = None

	%>
	% if not request.user:
		% pass
	% else:
		% slot_dict = request.user.active_ballot_events
		% ballot_count = sum(x is not None for x in slot_dict.values())
		% if ballot_count > 1:
			<div class="alert alert-info">
				<strong>
					<span class="glyphicon glyphicon glyphicon-fire text-danger"></span>
					Experimental
				</strong>
				You're entered into multiple ballots which are happening right now. Rents and other info could be incorrect. Stuff will go wrong. You should probably contact efw27.
			</div>
		% end
		% for e, slot in slot_dict.items():
			% if not slot:
				% continue
			% end
			% active_listing = room.listing_for.get(e.season)
			% active_occ = active_listing and next(iter(active_listing.occupancies), None)
			% if not active_listing or e.type not in active_listing.audience_types:
				<div class="alert alert-warning lead">
					<strong>
						<span class="glyphicon glyphicon-warning-sign"></span>
						Heads up:
					</strong>
					This room isn't and won't be available in the {{ e.type.name }} ballot
					% if ballot_count == 2:
						<small class="text-muted" style="display: block">{{ e.type.name }}, {{ e.season }}</small>
					% end
				</div>
			% elif not active_occ:
				% if slot.time >= datetime.now():
					<div class="alert alert-info lead">
						<strong>
							<span class="glyphicon glyphicon-time"></span>
							You can't choose this room yet.
						</strong>
						You'll have to wait till your slot time comes up
						% if ballot_count == 2:
							<small class="text-muted" style="display: block">{{ e.type.name }}, {{ e.season }}</small>
						% end
					</div>
				% else:
					<div class="alert alert-success lead">
						<strong>
							<span class="glyphicon glyphicon-ok"></span>
							All systems go!
						</strong>
						This room is available
						<a href="#" class="btn btn-md btn-success pull-right">Reserve this room</a>
						% if ballot_count == 2:
							<small class="text-muted" style="display: block">{{ e.type.name }}, {{ e.season }}</small>
						% end
					</div>
				% end
			% elif active_occ.resident != request.user:
				<div class="alert alert-danger lead">
					<strong>
						<span class="glyphicon glyphicon-remove"></span>
						Darn!
					</strong>
					You're {{ datetime.now() - active_occ.chosen_at }} too late - 
					% if active_occ.resident:
						<a href="{{ url_for(active_occ.resident) }}">
							{{active_occ.resident.name}}</a>
					% else:
						someone else
					% end
					has already taken this room
					% if ballot_count == 2:
						<small class="text-muted" style="display: block">{{ e.type.name }}, {{ e.season }}</small>
					% end
				</div>
			% else:
				<div class="alert alert-success lead">
					<strong>
						<span class="glyphicon glyphicon glyphicon-home"></span>
						That's it.
					</strong>
					You've chosen this room, and are done with balloting for the season
					% if ballot_count == 2:
						<small class="text-muted" style="display: block">{{ e.type.name }}, {{ e.season }}</small>
					% end
				</div>
			% end
		% end
		% if slot_dict and ballot_count == 0:
			<div class="alert alert-warning lead">
				<strong>
					<span class="glyphicon glyphicon-warning-sign"></span>
					You're not in any ballot
				</strong>
				There are ballots in progress ({{ ', '.join(e.type.name for e in slot_dict) }}), but you're not entered in any of them. If you think this is a mistake, please contact someone ASAP!
			</div>
		% end
	% end


	% last_listing = active_listing or room.listing_for.get(ballot)

	<div id="info" class="row anchor">
		<div class="col-md-6">
			<h1>
				<span itemprop="name">{{ room.pretty_name() }}</span>

				% if room.stats.adjusted_rating:
					<small itemprop="aggregateRating" itemscope itemtype="http://schema.org/AggregateRating">
						<span itemprop="ratingValue">{{ '{:.1f}'.format(room.stats.adjusted_rating) }}</span><!--
						-->/<span itemprop="bestRating">10</span>
						<meta itemprop="ratingCount" content="{{ room.stats.rating_count }}" />
						<meta itemprop="reviewCount" content="{{ room.stats.review_count }}" />
					</small>
				% end
			</h1>
			<table class="table">
				% two_columns = room.is_suite or room.living_room_view or room.living_room_x
				% if two_columns:
					<thead>
						<tr>
							<th></th>
							<th>Bedroom</th>
							<th>Living room</th>
						</tr>
					</thead>
				% end
				<tr>
					<th scope="row">Size</th>
					<td>
						% if room.bedroom_x:
							<div class="room-outline"
							     style="width: {{ room.bedroom_y * 10 + 1}}px;
							            height: {{ room.bedroom_x * 10 + 1}}px;
							            padding-top: {{ room.bedroom_x * 5 - 21}}px;">
								{{room.bedroom_x * room.bedroom_y}} ft&sup2;<br />
								<span class="text-muted">
									({{room.bedroom_x}} &times; {{room.bedroom_y}})
								</span>
							</div>
						% else:
							<div class="room-outline unknown">
								size unknown
							</div>
						% end
					</td>
					% if two_columns:
						<td>
							% if room.living_room_x:
								<div class="room-outline"
								     style="width: {{ room.living_room_y * 10 + 1}}px;
								            height: {{ room.living_room_x * 10 + 1}}px;
								            padding-top: {{ room.living_room_x * 5 - 21}}px;">
									{{room.living_room_x * room.living_room_y}} ft&sup2;<br />
									<span class="text-muted">
										({{room.living_room_x}} &times; {{room.living_room_y}})
									</span>
								</div>
							% else:
								<div class="room-outline unknown">
									size unknown
								</div>
							% end
						</td>
					% end
				</tr>
				<tr>
					<th scope="row">View</th>
					<td>{{ room.bedroom_view or "" }}</td>
					% if two_columns:
						<td>{{ room.living_room_view or "" }}</td>
					% end
				</tr>
				<tr>
					<th scope="row">Rent</th>
					<td colspan="2">
						% if last_listing and last_listing.rent:
							£{{ "{:.2f}".format(last_listing.rent) }} / term
						% end
					</td>
				</tr>
			</table>
		</div>
		<div class="col-md-6" style="padding-top: 20px; padding-bottom: 20px">

			<div style="position: absolute; top: 25px; right: 20px; z-index: 1; text-shadow: 0px 0px 15px white; font-size: 36px">
				% n = last_listing and last_listing.has_ethernet
				% if n == True:
					<span class="glyphicon glyphicon-cloud text-success" title="Ethernet"></span>
				% elif n == False:
					<span class="glyphicon glyphicon-cloud text-danger" title="No Ethernet"></span>
				% else:
					<span class="glyphicon glyphicon-cloud text-muted" title="Possible Ethernet"></span>
				% end

				% w = last_listing and last_listing.has_washbasin
				% if w == True:
					<span class="glyphicon glyphicon-tint text-success" title="Washbasin"></span>
				% elif w == False:
					<span class="glyphicon glyphicon-tint text-danger" title="No Washbasin"></span>
				% else:
					<span class="glyphicon glyphicon-tint text-muted" title="Possible Washbasin"></span>
				% end

				% p = last_listing and last_listing.has_piano
				% if p == True:
					<span class="glyphicon glyphicon-music text-success" title="Piano"></span>
				% elif p == False:
					<span class="glyphicon glyphicon-music text-danger" title="No Piano"></span>
				% else:
					<span class="glyphicon glyphicon-music text-muted" title="Possible Piano"></span>
				% end
			</div>
			<div id="map"></div>
			% lat_lon = room.geocoords
			% if lat_lon:
				<script src="https://maps.googleapis.com/maps/api/js?v=3.exp&amp;sensor=false"></script>
				<script>
					google.maps.visualRefresh = true;

					var loc = new google.maps.LatLng(
						{{ lat_lon[0] }},
						{{ lat_lon[1] }}
					);
					var mapElem = $('#map');

					function initialize() {
						mapElem.css('height', mapElem.parent().parent().find('div').first().height() - 20);

					    map = new google.maps.Map(mapElem[0], {
							zoom: 14,
							center: new google.maps.LatLng(52.20675, 0.1223485),
							disableDefaultUI: true,
							draggable: true,
							zoomControl: false,
							scaleControl: false,
							scrollwheel: true,
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
					}

					initialize();
				</script>
			% end
			% # <!-- <img src="http://maps.googleapis.com/maps/api/staticmap?center=52.20675,0.1223485&amp;zoom=14&amp;size=400x300&amp;maptype=roadmap&amp;markers=color:blue%7C{{latlng}}&amp;sensor=false" /> -->
		</div>
	</div>
</div>
<%
photos = [
	photo
	for listing in room.listings
	for occupancy in listing.occupancies
	for photo in occupancy.photos
]
%>
<div class="well-wide">
	<div class="container">
		<%
		occ = next((
			occupancy
			for listing in room.listings
			for occupancy in listing.occupancies
			if occupancy.resident == request.user
		), None)
		%>
		<div id="photos" class="anchor" style="text-align: center; margin: 0px -10px">
			% if photos and request.user and occ:
				<div><a class="btn btn-lg btn-success" href="/photos/new/{{occ.id}}">Upload photos</a></div>
			% end
			% for photo in photos:
				<p style="display: inline-block; text-align: left; margin: 10px; overflow: hidden">
					<img src="{{photo.href}}" class="img-rounded img-responsive"
					     width="{{ photo.width }}" />
					{{ photo.caption }}
					<span class="text-muted pull-right">{{! format_ts_html(photo.published_at) }}</span>
				</p>
			% end
			% if not photos:
				<p class="lead text-muted">No photos</p>
				% if request.user and occ:
					<p class="text-muted">But it looks like <i>you</i> could take some photos. <a class="btn btn-primary" href="/photos/new/{{occ.id}}">Add some?</a></p>
				% end
			% end
		</div>
	</div>
</div>
<div class="container">
	<div id="reviews" class="anchor">
		<% first = True
		for listing in room.listings:
			for occupancy in listing.occupancies:
				if occupancy.review or occupancy.resident:
					if not first: %>
						<hr />
						<%
					end
					first = False
					include('parts/review', occupancy=occupancy, version=version)
				end
			end
		end
		%>
	</div>

	<%
	referring_sections = set(
		ref.review_section
		for ref in room.references
		if ref.review_section.review.occupancy.listing.room != room and
		   ref.review_section.review.is_newest
	)
	if referring_sections:
		referring_sections = sorted(
			referring_sections,
			key=lambda s: s.review.occupancy.listing.ballot_season.year,
			reverse=True
		) %>
		<hr />
		<div id="references" class="anchor">
			<h2>References <small>mentions in other reviews</small></h2>

			<div class="row">
				% for section in referring_sections:
					% refered_by = section.review.occupancy.listing.room
					<div class="col-md-6">
						<h3>
							% o = section.review.occupancy
							<a href="{{ url_for(refered_by) }}#occupancy-{{ o.id }}">
								{{ refered_by.pretty_name() }}</a>
							<small>{{ o.listing.ballot_season }}
							&bull; {{ section.heading.name }}</small>
						</h3>
						{{! section.html_content(room) }}
					</div>
				% end
			</div>
		</div>
	% end
</div>
</div>
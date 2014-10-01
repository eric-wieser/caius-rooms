% from utils import format_ts_html
% from bottle import request

% rebase layout

% def layout_breadcrumb():
	% for part in room.parent.path:
		% yield ("/places/{}".format(part.id), part.pretty_name(part.parent))
	% end
	% yield ('#', room.pretty_name(room.parent))
% end

% def layout_extra_nav():
	% import json
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
% end

% layout_random = '/rooms/random'

<div class="container" style="margin-bottom: 6em" itemscope itemtype="http://schema.org/Product">
	% last_listing = room.listing_for.get(ballot)
	% if last_listing and last_listing.occupancies:
		% last_occupancy = last_listing.occupancies[-1]
	% else:
		% last_occupancy = None
	% end
	<div id="info" class="row anchor">
		<div class="col-md-6">
			<h1>
				<span itemprop="name">{{ room.pretty_name() }}</span>

				% if not last_listing:
					<span class="label label-warning" title="Not on offer for the {{ ballot.year }} ballot">unavailable</span>
				% elif not last_occupancy:
					% pass
				% elif not last_occupancy.resident:
					<span class="label label-danger" title="Owner not recorded...">reserved</span>
				% elif last_occupancy.resident != request.user:
					<span class="label label-danger" title="By {{ last_occupancy.resident.name }}">reserved</span>
				% else:
					<span class="label label-success">yours</span>
				% end

				% if room.adjusted_rating:
					<small itemprop="aggregateRating" itemscope itemtype="http://schema.org/AggregateRating">
						<span itemprop="ratingValue">{{ '{:.1f}'.format(room.adjusted_rating) }}</span><!--
						-->/<span itemprop="bestRating">10</span>
						<meta itemprop="ratingCount" content="{{ room.rating_count }}" />
						<meta itemprop="reviewCount" content="{{ room.review_count }}" />
					</small>
				% end
			</h1>
			<table class="table">
				<tr>
					<th scope="row">Bedroom area</th>
					<td>
						% if room.bedroom_x:
							{{room.bedroom_x}} &times; {{room.bedroom_y}} ft&sup2;
						% end
					</td>
				</tr>
				<tr>
					<th scope="row">Bedroom view</th>
					<td>{{ room.bedroom_view or "" }}</td>
				</tr>
				% if room.is_suite or room.living_room_view or room.living_room_x:
					<tr>
						<th scope="row">Living room area</th>
						<td>
							% if room.living_room_x:
								{{room.living_room_x}} &times; {{room.living_room_y}} ft&sup2;
							% end
						</td>
					</tr>
					<tr>
						<th scope="row">Living room view</th>
						<td>{{ room.living_room_view or "" }}</td>
					</tr>
				% end
				<tr>
					<th scope="row">Rent</th>
					<td>
						% if last_listing.rent:
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

	<div id="photos" class="anchor">
		% any_photos = False
		% for listing in room.listings:
			% for occupancy in listing.occupancies:
				% for photo in occupancy.photos:
					<p>
						<img src="{{photo.href}}" class="img-rounded img-responsive" />
						{{ photo.caption }}
						<span class="text-muted">{{! format_ts_html(photo.published_at) }}</span>
					</p>
					% any_photos = True
				% end
			% end
		% end
		% if not any_photos:
			<div class="alert alert-warning">No photos</div>
		% end
	</div>
	<div id="reviews" class="anchor">
		% for listing in room.listings:
			% for occupancy in listing.occupancies:
				% for review in occupancy.reviews:
					<hr />
					% include review.tpl review=review, version=version
				% end
				% if not occupancy.reviews and occupancy.resident:
					<div itemprop="review" itemscope itemtype="http://schema.org/Review">
						<h2>{{ listing.ballot_season.year }}</h2>
						<a itemprop="author" href="/users/{{occupancy.resident.crsid}}">{{occupancy.resident.name}}</a>
					</div>
				% end
			% end
		%end
	</div>

	% referring_sections = set(ref.review_section for ref in room.references if ref.review_section.review.occupancy.listing.room != room)

	% if referring_sections:
		<div id="references" class="anchor">
			<h3>References</h3>

			<div class="row">
				% for section in referring_sections:
					% refered_by = section.review.occupancy.listing.room
					<div class="col-md-6">
						<div class="panel panel-default">
							<div class="panel-heading">
								<a href="/rooms/{{ refered_by.id }}#review-{{ section.review.id }}">
									{{ refered_by.pretty_name() }}
									&bull; {{ section.review.occupancy.listing.ballot_season.year }} -
										   {{ section.review.occupancy.listing.ballot_season.year + 1}}
									&bull; {{ section.heading.name }}
								</a>
							</div>
							<div class="panel-body">{{! section.html_content }}</div>
						</div>
					</div>
				% end
			</div>
		</div>
	% end
</div>
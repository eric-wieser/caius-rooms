% rebase layout room=room

<div class="container" style="margin-bottom: 6em" itemscope itemtype="http://schema.org/Product">
	% last_listing = room.listings[0] if room.listings else None
	<div id="info" class="row anchor">
		<div class="col-md-6">
			% reviews = False and [r for r in room.reviews if r.rating is not None]
			<h1>
				<span itemprop="name">{{room.pretty_name()}}</span>
				% if False and room['owner']:
					<span class="label label-danger" title="{{room['owner']}}">reserved</span>
				%end
				% if reviews:
					% mean_score = sum(r.rating for r in reviews) * 1.0 / len(reviews)
					<small itemprop="aggregateRating" itemscope itemtype="http://schema.org/AggregateRating">
						<span itemprop="ratingValue">{{ '{:.1f}'.format(mean_score) }}</span><!--
						-->/<span itemprop="bestRating">10</span>
						<meta itemprop="ratingCount" content="{{len(reviews)}}" />
						<meta itemprop="reviewCount" content="{{len(reviews)}}" />
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
						<img src="http://gcsu.soc.srcf.net/roomCaius/photo.php?id={{ photo.id }}.jpg" class="img-rounded img-responsive" />
						{{ photo.caption }}
						<span class="text-muted">{{ photo.published_at }}</span>
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
					<div itemprop="review" itemscope itemtype="http://schema.org/Review">
						<h2>{{ listing.ballot_season.year }}
							% if review.rating is not None:
								<small itemprop="reviewRating" itemscope itemtype="http://schema.org/Rating">
									<span itemprop="ratingValue">{{ review.rating }}</span><!--
									-->/<span itemprop="bestRating">10</span>
								</small>
							% end
						</h2>
						% if occupancy.resident:
							<a itemprop="author" href="mailto:{{occupancy.resident.crsid}}">{{occupancy.resident.name}}</a>
						% end
						% if review.sections:
							<div class="row" style="margin-top: -10px">
								<div class="col-md-5">
									% for section in review.sections:
										% if section.heading.is_summary:
											<h3>{{ section.heading.name }}</h3>
											{{! section.html_content }}
										% end
									% end
								</div>
								<div class="col-md-7" style="margin-top: 20px">
									<dl class="dl-horizontal">
										% for section in review.sections:
											% if not section.heading.is_summary:
												<dt>{{ section.heading.name }}</dt>
												<dd>{{! section.html_content }}</dd>
											% end
										% end
									</dl>
								</div>
							</div>
						% end
						<div class="text-right"><small class="text-muted text-right">{{ review.published_at }}</small></div>
					</div>
				% end
				% if not occupancy.reviews and occupancy.resident:
					<div itemprop="review" itemscope itemtype="http://schema.org/Review">
						<h2>{{ listing.ballot_season.year }}</h2>
						<a itemprop="author" href="mailto:{{occupancy.resident.crsid}}">{{occupancy.resident.name}}</a>
					</div>
				% end
			% end
		%end
		% if False and room['references']:
			<h3 id="references">References</h3>
			<ul>
				% for reference in room['references']:
					<li>
						<a href="/rooms/{{ reference['review']['room']['id'] }}">
							{{ reference['review']['room']['name'] }}
						</a>
						<span class="text-muted">
							- {{ reference['review']['date'] }}
							- {{ reference['name'] }}
						</span>
						<p>{{! reference['value'] }}</p>
					</li>
				% end
			</ul>
		% end
	</div>
</div>
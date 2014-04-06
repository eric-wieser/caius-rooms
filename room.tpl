% rebase layout room=room

<div class="container" style="margin-bottom: 6em" itemscope itemtype="http://schema.org/Product">
	% d = room.get('details', {})
	<div id="info" class="row anchor">
		<div class="col-md-6">
			% reviews = [r for r in room['reviews'] if r['rating'] is not None]
			<h1>
				<span itemprop="name">{{room['name']}}</span>
				% if room['owner']:
					<span class="label label-danger" title="{{room['owner']}}">reserved</span>
				%end
				% if reviews:
					% mean_score = sum(r['rating'] for r in reviews) * 1.0 / len(reviews)
					<small itemprop="aggregateRating" itemscope itemtype="http://schema.org/AggregateRating">
						<span itemprop="ratingValue">{{ '{:.1f}'.format(mean_score) }}</span><!--
						-->/<span itemprop="bestRating">10</span>
						<meta itemprop="ratingCount" content="{{len(reviews)}}" />
						<meta itemprop="reviewCount" content="{{len(reviews)}}" />
					</small>
				% end

			</h1>
			<table class="table">
				% for prop, value in d.iteritems():
					% if prop not in ('Network', 'Piano', 'Washbasin', 'George Foreman nearby'):
						<tr>
							<th scope="row">{{prop}}</th>
							% if prop == 'Estimated Rent':
								<td itemprop="offers" itemscope itemtype="http://schema.org/Offer">
									<span itemprop="price">{{value}}</span>
								</td>
							% else:
								<td>{{value}}</td>
							% end
						</tr>
					%end
				% end
			</table>
		</div>
		<div class="col-md-6" style="padding-top: 20px; padding-bottom: 20px">

			<div style="position: absolute; top: 25px; right: 20px; z-index: 1; text-shadow: 0px 0px 15px white; font-size: 36px">
				% n = d.get('Network')
				% if n in ('Y', 'Yes'):
					<span class="glyphicon glyphicon-cloud text-success" title="Network"></span>
				% elif n in ('N', 'No'):
					<span class="glyphicon glyphicon-cloud text-danger" title="No Network"></span>
				% else:
					<span class="glyphicon glyphicon-cloud text-muted" title="Possible Network"></span>
				% end

				% w = d.get('Washbasin')
				% if w in ('Y', 'Yes'):
					<span class="glyphicon glyphicon-tint text-success" title="Washbasin"></span>
				% elif w in ('N', 'No'):
					<span class="glyphicon glyphicon-tint text-danger" title="No Washbasin"></span>
				% else:
					<span class="glyphicon glyphicon-tint text-muted" title="Possible Washbasin"></span>
				%end

				% p = d.get('Piano')
				% if p in ('Y', 'Yes'):
					<span class="glyphicon glyphicon-music text-success" title="Piano"></span>
				% elif p in ('N', 'No'):
					<span class="glyphicon glyphicon-music text-danger" title="No Piano"></span>
				% else:
					<span class="glyphicon glyphicon-music text-muted" title="Possible Piano"></span>
				%end
			</div>
			<div id="map"></div>
			% try:
			<script src="https://maps.googleapis.com/maps/api/js?v=3.exp&amp;sensor=false"></script>
			<script>
				google.maps.visualRefresh = true;

				var loc = new google.maps.LatLng(
					{{room['place']['location']['lat'] }},
					{{room['place']['location']['lng'] }}
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
			% except KeyError:
				% pass
			% end
			% # <!-- <img src="http://maps.googleapis.com/maps/api/staticmap?center=52.20675,0.1223485&amp;zoom=14&amp;size=400x300&amp;maptype=roadmap&amp;markers=color:blue%7C{{latlng}}&amp;sensor=false" /> -->
		</div>
	</div>

	<div id="photos" class="anchor">
		% if not room['images']:
			<div class="alert alert-warning">No photos</div>
		% end
		% for image in room['images']:
			<p>
				<img src="{{ image['href'] }}" class="img-rounded img-responsive" />
				{{ image['caption'] }}
			</p>
		% end
	</div>
	<div id="reviews" class="anchor">
		% if not room['reviews']:
			<div class="alert alert-warning">No reviews</div>
		% end
		%for review in room['reviews']:
			<div itemprop="review" itemscope itemtype="http://schema.org/Review">
				<h2>{{review['date']}}
					% if review['rating'] is not None:
						<small itemprop="reviewRating" itemscope itemtype="http://schema.org/Rating">
							<span itemprop="ratingValue">{{review['rating']}}</span><!--
							-->/<span itemprop="bestRating">10</span>
						</small>
					% end
				</h2>
				% if 'resident' in review:
					<a itemprop="author" href="mailto:{{review['resident']['email']}}">{{review['resident']['name']}}</a>
				% end
				% if 'sections' in review:
					<dl class="review dl-horizontal" itemprop="reviewBody">
						%for item in review['sections']:
							%if item['value']:
								<dt>{{item['name']}}</dt>
								<dd style="white-space: pre-wrap">{{! item['value'] }}</dd>
							%end
						%end
					</dl>
				% end
			</div>
		%end
		% if room['references']:
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
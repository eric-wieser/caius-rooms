% import json
<!doctype html>
<html>
	<head>
	    <meta charset="utf-8">
	    <meta http-equiv="X-UA-Compatible" content="IE=edge">
	    <meta name="viewport" content="width=device-width, initial-scale=1">
		<link rel="icon" type="image/png" href="http://cdn.dustball.com/house.png">
		<link href="//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css" rel="stylesheet">
		<script src="http://code.jquery.com/jquery-2.1.0.min.js"></script>
   		<script src="https://maps.googleapis.com/maps/api/js?v=3.exp&sensor=false"></script>
		<title>Rooms | {{room['name']}}</title>
	</head>
	<body>
		<div class="container" style="margin-bottom: 6em">
			<div style="position: fixed; bottom: 1em; right: 1em">
				<p><a class="btn btn-default" href='random'>
					<span class="glyphicon glyphicon-random"></span> Random
				</a></p>
				<p><button type="button" class="btn btn-default" id="favorite" title="Record as favorite on this PC">
					<span class="glyphicon glyphicon-star"></span> Favorite
				</button></p>

				<script>
				var thisRoom = {{! json.dumps(room['id']) }};
				if(localStorage['favorited-' + thisRoom])
					$('#favorite').addClass('btn-success');

				$('#favorite').click(function() {
					if(localStorage['favorited-' + thisRoom]) {
						delete localStorage['favorited-' + thisRoom];
						$('#favorite').removeClass('btn-success');
					}
					else {
						localStorage['favorited-' + thisRoom] = true;
						$('#favorite').addClass('btn-success');
					}
				});
				</script>
			</div>
			% d = room.get('details', {})

			% latlng = ','.join([room['place']['location']['lat'], room['place']['location']['lng']])
			<div class="row">
				<div class="col-md-6">
					% reviews = [r for r in room['reviews'] if r['rating'] is not None]
					<h1>
						{{room['name']}} 
						% if reviews:
							% mean_score = sum(r['rating'] for r in reviews) * 1.0 / len(reviews) 
							<small>{{ '{:.1f}'.format(mean_score) }}/10</small>
						% end

					</h1>
					<table class="table">
						% for prop, value in d.iteritems():
							% if prop not in ('Network', 'Piano', 'Washbasin', 'George Foreman nearby'):
								<tr>
									<th scope="row">{{prop}}</th>
									<td>{{value}}</td>
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


						% g = d.get('George Foreman nearby')
						% if g in ('Y', 'Yes'):
							<span class="glyphicon glyphicon-fire text-success" title="George Foreman"></span>
						% elif g in ('N', 'No'):
							<span class="glyphicon glyphicon-fire text-danger" title="No George Foreman"></span>
						% else:
							<span class="glyphicon glyphicon-fire text-muted" title="Possible George Foreman"></span>
						% end
					</div>
					<div id="map"></div>
					% try:
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
					<!-- <img src="http://maps.googleapis.com/maps/api/staticmap?center=52.20675,0.1223485&amp;zoom=14&amp;size=400x300&amp;maptype=roadmap&amp;markers=color:blue%7C{{latlng}}&amp;sensor=false" /> -->
				</div>
			</div>

			<div class="images">
				%for image in room['images']:
					<p>
						<img src="{{ image['href'] }}" class="img-rounded img-responsive" />
						{{ image['caption'] }}
					</p>
				%end
			</div>
			<div class="reviews">
				%for review in room['reviews']:
					<div>
						<h2>{{review['date']}}
							% if review['rating'] is not None:
								<small>{{review['rating']}}/10</small>
							% end
						</h2>
						% if 'resident' in review:
							<a href="mailto:{{review['resident']['email']}}">{{review['resident']['name']}}</a>
						% end
						% if 'sections' in review:
							<dl class="review dl-horizontal">
								%for item in review['sections']:
									%if item['value']:
										<dt>{{item['name']}}</dt>
										<dd style="white-space: pre-wrap">{{item['value']}}</dd>
									%end
								%end
							</dl>
						% end
					</div>
				%end
			</div>
		</div>
	</body>
</html>
% import json

% if defined('title'):
	% if isinstance(title, str):
		% parts = [('', title, None)]
	% else:
		% parts = [('', t, None) if isinstance(t, str) else t for t in title]
	% end
% else:
	% parts = []

	% if defined('room'):
		% place = room['place']
	% end

	% if defined('place'):
		% if place['group']:
			% parts.append(("/rooms?group=" + place['group'], place['group'], None))
			% parts.append((get_url('place', place=place), place['name'].split(place['group'], 1)[0], None))
		% else:
			% parts.append((get_url('place', place=place), place['name'], None))
		% end
	% end

	% if defined('room'):
		% parts.append(('#', room['number'], None))
	% end
% end

<!doctype html>
<html>
	<head>
	    <meta charset="utf-8">
	    <meta http-equiv="X-UA-Compatible" content="IE=edge">
	    <meta name="viewport" content="width=device-width, initial-scale=1">
		<link rel="icon" type="image/png" href="http://cdn.dustball.com/house.png">
		<script src="http://code.jquery.com/jquery-2.1.0.min.js"></script>

		<link href="//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css" rel="stylesheet">
		<script src="//netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"></script>
   		<script src="https://maps.googleapis.com/maps/api/js?v=3.exp&amp;sensor=false"></script>


		<link href="/static/bootstrap-sortable.css" rel="stylesheet">
		<script src="/static/bootstrap-sortable.js"></script>
		<style>
			td.shrink { width: 1px; white-space: nowrap; }
			td.center { text-align: center; }
			td.rule-right,
			th.rule-right { border-right: 1px solid #ddd; }

			#footer {
				position: absolute;
				bottom: 0;
				width: 100%;
				height: 25px;
				padding-top: 5px;
				background-color: #f5f5f5;
				text-align: center;
			}
			#footer p {
				margin: 0;
			}


			html {
				position: relative;
				min-height: 100%;
			}
			body {
				margin-top: 50px;
				padding-top: 20px;
				margin-bottom: 25px;
			}

			.cropped-photo {
				background-size: cover;
   				background-repeat: no-repeat;
   				background-position: 50% 50%;
			}

			.anchor:before {
				content:"";
				display:block;
				height:70px;
				margin:-70px 0 0;
			}

		</style>
		<script>
		$(function() {
			$('.glyphicon[title]').tooltip();
		});
		</script>
		<title>{{' | '.join([name for url, name, html in parts][::-1] + ['RoomPicks']) }}</title>
	</head>
	<body data-spy="scroll" data-target="#page-specific-nav">
		<nav class="navbar navbar-default navbar-fixed-top" role="navigation">
			<div class="container">
				<div class="navbar-header">
					<button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#collapsible-nav">
						<span class="sr-only">Toggle navigation</span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
					</button>
					% if False and defined('room'):
						<a class="navbar-brand" href="/rooms" title="For when you don't yet have the Caius">
							RoomPicks <span class="glyphicon glyphicon-home"></span>
						</a>
					% elif False and defined('place'):
						<a class="navbar-brand" href="/places" title="For when you don't yet have the Caius">
							RoomPicks <span class="glyphicon glyphicon-map-marker"></span>
						</a>
					% else:
						<a class="navbar-brand" href="/places" title="For when you don't yet have the Caius">RoomPicks</a>
					% end
				</div>
				<div class="collapse navbar-collapse" id="collapsible-nav">
					<ul class="nav navbar-nav navbar-left">
						% for url, name, html in parts[:-1]:
							<li><a href="{{url}}">{{!html or name}}</a></li>
						% end
						% if parts:
							% url, name, html = parts[-1]
							<li class="active"><a href="{{url}}">{{!html or name}}</a></li>
						% end
						% if get('extra_nav'):
							% extra_nav()
						% end
					</ul>
					<div id="page-specific-nav">
						<ul class="nav navbar-nav navbar-right">
							% if defined('room'):
								<li style="display: none"><a href="#info"></a></li>
								<li><a href="#photos">
									<span class="glyphicon glyphicon-picture"></span> Photos
								</a></li>
								<li><a href="#reviews">
									<span class="glyphicon glyphicon-comment"></span> Reviews
								</a></li>
								<li><a href="http://www.caiusjcr.org.uk/roomCaius/index.php?location={{room['place']['name']}}#room-{{room['id']}}"  target="_blank" title="View on roomCaius">
									<span class="glyphicon glyphicon-new-window"></span> roomCaius
								</a></li>
								<li><a href='#' id="favorite" title="Record as favorite on this PC">
									<span class="glyphicon glyphicon-star"></span> Favorite
								</a></li>
								<li><a href='/rooms/random'>
									<span class="glyphicon glyphicon-random"></span> Random
								</a></li>
								<script>
								var thisRoom = {{! json.dumps(room['id']) }};
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
							% elif defined('place'):
								<li{{! ' class="active"' if get('is_photos') else '' }}><a href="{{ get_url('place-photos', place=place) }}">
									<span class="glyphicon glyphicon-picture"></span> Photos
								</a></li>
								<li><a href="http://www.caiusjcr.org.uk/roomCaius/index.php?location={{place['name']}}"  target="_blank" title="View on roomCaius">
									<span class="glyphicon glyphicon-new-window"></span> roomCaius
								</a></li>
								<li><a href='/places/random{{'/photos' if get('is_photos') else '' }}'>
									<span class="glyphicon glyphicon-random"></span> Random
								</a></li>
							% elif defined('random'):
								<li><a href='{{random}}'>
									<span class="glyphicon glyphicon-random"></span> Random
								</a></li>
							% end
						</ul>
					</div>
				</div>
			</div>
		</nav>
		% include

		<div id="footer">
			<div class="container">
				<p class="text-muted">Developed by Eric Wieser. Data from <a href="http://www.caiusjcr.org.uk/roomCaius/index.php">RoomCaius</a>. No guarantee of consistency is made</p>
			</div>
		</div>
	</body>
</html>

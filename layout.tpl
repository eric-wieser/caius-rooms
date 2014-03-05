% import json

% parts = []

% if defined('room'):
	% place = room['place']
% end

% if defined('place'):
	% if place['group']:
		% parts.append(("/rooms?group=" + place['group'], place['group']))
		% parts.append((get_url('place', place=place), place['name'].split(place['group'], 1)[0]))
	% else:
		% parts.append((get_url('place', place=place), place['name']))
	% end
% end

% if defined('room'):
	% parts.append(('/rooms/{}'.format(room['id']), room['number']))
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
				overflow: hidden;
				text-align: center;
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

		</style>
		<script>
		$(function() {
			$('.glyphicon[title]').tooltip();
		});
		</script>
		<title>{{' | '.join([name for url, name in parts][::-1] + ['RoomPicks']) }}</title>
	</head>
	<body>
		<nav class="navbar navbar-default  navbar-fixed-top" role="navigation">
			<div class="container-fluid">
				<div class="navbar-header">
					<button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#collapsible-nav">
						<span class="sr-only">Toggle navigation</span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
					</button>
					<a class="navbar-brand" href="/rooms" title="For when you don't yet have the Caius">RoomPicks</a>
				</div>
				<div class="collapse navbar-collapse" id="collapsible-nav">
					<ul class="nav navbar-nav navbar-left">
						% for url, name in parts[:-1]:
							<li><a href="{{url}}">{{name}}</a></li>
						% end
						% if parts:
							% url, name = parts[-1]
							<li class="active"><a href="{{url}}">{{name}}</a></li>
						% end
					</ul>
					<ul class="nav navbar-nav navbar-right">
						<li><a href='random'>
							<span class="glyphicon glyphicon-random"></span> Random
						</a></li>
						% if defined('room'):
							<li><a href='#' id="favorite" title="Record as favorite on this PC">
								<span class="glyphicon glyphicon-star"></span> Favorite
							</a></li>

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
						% end
					</ul>
				</div>
			</div>
		</nav>
		% include

		<div id="footer">
			<div class="container">
				<p class="text-muted">Developed by Eric Wieser. Data courtesy of <a href="www.caiusjcr.org.uk/roomCaius/index.php">RoomCaius</a></p>
			</div>
		</div>
	</body>
</html>

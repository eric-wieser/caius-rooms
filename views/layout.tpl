% import json
% from bottle import request
% import urllib

% url_parts = request.path[1:].split('/')
% main_route = url_parts[0]
%
% nav = [
% 	('rooms',   'Rooms',   'glyphicon-home'),
% 	('places',  'Places',  'glyphicon-map-marker'),
% 	('users',   'Users',   'glyphicon-user'),
% 	('ballots', 'Ballots', 'glyphicon-list-alt')
% ]
% matching_nav = next((n for n in nav if n[0] == main_route), None)

% if defined('title'):
	% if isinstance(title, str):
		% parts = [('', title, None)]
	% else:
		% parts = [('', t, None) if isinstance(t, str) else t for t in title]
	% end
% else:
	% parts = []

	% if defined('room') and main_route == 'room':
		% place = room.parent
	% end

	% if defined('place') and main_route == 'place':
		% for part in place.path:
			% parts.append(("/places/{}".format(part.id), part.pretty_name(part.parent), None))
		% end
	% end

	% if defined('room') and main_route == 'room':
		% parts.append(('#', room.pretty_name(room.parent), None))
	% end
% end

<!doctype html>
<html>
	<head>
		<meta charset="utf-8">
		<meta http-equiv="X-UA-Compatible" content="IE=edge">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<link rel="icon" type="image/png" href="http://cdn.dustball.com/house.png">
		<link href="//netdna.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css" rel="stylesheet">

		<script src="http://code.jquery.com/jquery-2.1.0.min.js"></script>

		<link href="/static/bootstrap-sortable.css" rel="stylesheet">
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
		<title>{{' | '.join([name for url, name, html in parts][::-1] + ['RoomPicks']) }}</title>
	</head>
	<body data-spy="scroll" data-target="#page-specific-nav" itemscope itemtype="http://schema.org/WebPage">
		<nav class="navbar navbar-default navbar-fixed-top" role="navigation">
			<div class="container">
				<div class="navbar-header">
					<button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#collapsible-nav">
						<span class="sr-only">Toggle navigation</span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
					</button>
					<a class="navbar-brand" href="/" title="For when you don't yet have the Caius">RoomPicks</a>
				</div>
				<div class="collapse navbar-collapse" id="collapsible-nav">
					<ul class="nav navbar-nav navbar-left">
						% if len(url_parts) < 2 or not matching_nav:
							% for url, name, icon in nav:
								<li {{! 'class="active"' if main_route == url else '' }} >
									<a href="/{{ url }}">
										<span class="glyphicon {{ icon }}"></span> {{ name }}
									</a>
								</li>
							% end
						% else:
							% url, name, icon = matching_nav
							<li class="dropdown">
								<a href="#" title="{{ name }}" class="dropdown-toggle brand" data-toggle="dropdown">
									<span class="glyphicon {{icon}}"></span><span class="caret"></span>
								</a>
								<ul class="dropdown-menu" role="menu">
									% for url, name, icon in nav:
										<li {{! 'class="active"' if main_route == url else '' }} >
											<a href="/{{ url }}">
												<span class="glyphicon {{ icon }}"></span> {{ name }}
											</a>
										</li>
									% end
								</ul>
							</li>
						% end
						% for url, name, html in parts[:-1]:
							<li itemscope itemtype="http://data-vocabulary.org/Breadcrumb">
								<a href="{{url}}" itemprop="url"><span itemprop="title">
									{{!html or name}}
								</span></a>
							</li>
						% end
						% if parts:
							% url, name, html = parts[-1]
							<li itemscope itemtype="http://data-vocabulary.org/Breadcrumb" class="active">
								<a href="{{url}}" itemprop="url"><span itemprop="title">
									{{!html or name}}
								</span></a>
							</li>
						% end
					</ul>
					<div id="page-specific-nav">
						<ul class="nav navbar-nav navbar-right">
							% if main_route == 'room':
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
								<li><a href='/rooms/random'>
									<span class="glyphicon glyphicon-random"></span> <span class="hidden-sm">Random</span>
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
							% elif main_route == 'place':
								<li{{! ' class="active"' if get('is_photos') else '' }}><a href="{{ get_url('place-photos', place_id=place.id) }}">
									<span class="glyphicon glyphicon-picture"></span> Photos
								</a></li>
								<li><a href='/places/random{{'/photos' if get('is_photos') else '' }}'>
									<span class="glyphicon glyphicon-random"></span> Random
								</a></li>
							% elif defined('random'):
								<li><a href='{{random}}'>
									<span class="glyphicon glyphicon-random"></span> Random
								</a></li>
							% end

							% if request.user:
								<li class="dropdown">
									<a href="#" class="dropdown-toggle" data-toggle="dropdown">
										<img width="30" height="30" style="display: inline-block; vertical-align: top; margin: -5px 5px -5px 0" src="{{ request.user.gravatar(size=30) }}" />{{request.user.name}} <span class="caret"></span>
									</a>
									<ul class="dropdown-menu" role="menu">
										<li><a href="/users/{{ request.user.crsid }}">Profile</a></li>
										<li class="divider"></li>
										<li><a href="#">Upload photo</a></li>
										<li><a href="/reviews/new">Write review</a></li>
										<li class="divider"></li>
										<li><a href="/logout?return_to={{ request.url }}">Logout</a></li>
									</ul>
								</li>
							% else:
								<li>
									<a href="/login?return_to={{ urllib.quote_plus(request.url) }}">
										Login
									</a>
								</li>
							% end
						</ul>
					</div>
				</div>
			</div>
		</nav>

		% include

		<script src="//netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"></script>
		<script src="/static/bootstrap-sortable.js"></script>
		<script>
		$(function() {
			$('.glyphicon[title]').tooltip();
		});
		</script>

		<div id="footer">
			<div class="container">
				<p class="text-muted">Developed by Eric Wieser. Data from <a href="http://www.caiusjcr.org.uk/roomCaius/index.php">RoomCaius</a>. No guarantee of consistency is made</p>
			</div>
		</div>
	</body>
</html>

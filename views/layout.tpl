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

% if defined('layout_breadcrumb'):
	% layout_breadcrumb = list(layout_breadcrumb())
% else:
	% layout_breadcrumb = []
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
		<title>{{' | '.join([name for url, name in reversed(layout_breadcrumb)] + ['RoomPicks']) }}</title>
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
						% if layout_breadcrumb:
							<li class="dropdown">
								% url, name, icon = matching_nav or (None, '', '')
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
							% for url, name in layout_breadcrumb[:-1]:
								<li itemscope itemtype="http://data-vocabulary.org/Breadcrumb">
									<a href="{{url}}" itemprop="url"><span itemprop="title">
										{{ name }}
									</span></a>
								</li>
							% end
							% url, name = layout_breadcrumb[-1]
							<li itemscope itemtype="http://data-vocabulary.org/Breadcrumb" class="active">
								<a href="{{url}}" itemprop="url"><span itemprop="title">
									{{ name }}
								</span></a>
							</li>
						% else:
							% for url, name, icon in nav:
								<li {{! 'class="active"' if main_route == url else '' }} >
									<a href="/{{ url }}">
										<span class="glyphicon {{ icon }}"></span> {{ name }}
									</a>
								</li>
							% end
						% end
					</ul>
					<div id="page-specific-nav">
						<ul class="nav navbar-nav navbar-right">
							% if defined('layout_extra_nav'):
								% layout_extra_nav()
							% end
							% if defined('layout_random'):
								<li><a href='{{ layout_random }}'>
									<span class="glyphicon glyphicon-random"></span>
									<span class="hidden-sm">Random</span>
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
								<li class="alert-info">
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

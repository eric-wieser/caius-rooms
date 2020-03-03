<%
import json
from bottle import request
try:
	import urllib.parse as urlparse
	from urllib.parse import quote_plus
except ImportError:
	import urlparse
	from urllib import quote_plus
end
url_parts = request.path[1:].split('/')
main_route = url_parts[0]
nav = [
	('rooms',   'Rooms',   'glyphicon-home'),
	('places',  'Places',  'glyphicon-map-marker'),
	('users',   'Users',   'glyphicon-user'),
	('ballots', 'Ballots', 'glyphicon-list-alt')
]
matching_nav = next((n for n in nav if n[0] == main_route), None)

if defined('layout_breadcrumb'):
	layout_breadcrumb = list(layout_breadcrumb())
else:
	layout_breadcrumb = []
end
%>
<!doctype html>
<html>
	<head>
		<meta charset="utf-8">
		<meta http-equiv="X-UA-Compatible" content="IE=edge">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<link rel="icon"       href="http://cdn.dustball.com/house.png" type="image/png" >
		<link rel="stylesheet" href="/static/style.min.css">
		<link rel="canonical"  href="{{ request.urlparts._replace(netloc='roompicks.caiusjcr.co.uk', query="").geturl() }}" />
		<script src="http://code.jquery.com/jquery-2.1.0.min.js"></script>
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
									<span class="glyphicon {{icon}}"></span> <span class="caret"></span>
								</a>
								<ul class="dropdown-menu" role="menu">
									% for url, name, icon in nav:
										<li {{! 'class="active"' if main_route == url else '' }} >
											<a href="{{ url_for('/' + url) }}">
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
									<a href="{{ url_for('/' + url) }}">
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
										<li><a href="{{ url_for(request.user) }}">Profile</a></li>
										% cr = request.user.current_room
										% if cr:
											<li><a href="{{ url_for(cr) }}">My room</a></li>
										% else:
											<li class="disabled"><a>My room</a></li>
										% end
										<li class="divider"></li>
										<li><a href="/logout?return_to={{ request.url }}">Logout</a></li>
									</ul>
								</li>
							% else:
								<li class="alert-info">
									<a href="/login?return_to={{ quote_plus(request.url) }}">
										Login
									</a>
								</li>
							% end
						</ul>
					</div>
				</div>
			</div>
		</nav>
		% """Render the banner prompting the user to take part in a ballot"""
		% if request.user:
			% e_dict = request.user.active_ballot_events
			% active_slots = [s for s in e_dict.values() if s]
			% ballot = get('ballot')
			% if e_dict:
				% if not active_slots:
					<div class="ballot-banner ballot-banner-not-assigned">
						<div class="container">
							<strong>
								<span class="glyphicon glyphicon-warning-sign"></span>
								You're not in any ballot
							</strong>
							There are ballots in progress ({{ ', '.join(u'{} {}'.format(e.season, e.type.name) for e in e_dict) }}), but you're not entered in any of them. If you think this is a mistake, please contact <a href="mailto:jcrhousing@cai.cam.ac.uk">the Housing Officer</a> ASAP!
						</div>
					</div>
				% elif ballot:
					% sl = next((sl for sl in active_slots if sl.event == ballot), None)
					% if sl:
						<div class="ballot-banner ballot-banner-correct-view">
							<div class="container">
								You're looking at information for your ballot (<a href="{{ url_for(sl.event.season) }}">{{ sl.event.season }}</a> {{ sl.event.type.name }})
								<span class="pull-right">
									Your slot is at {{ sl.time }}
									% if len(active_slots) > 1:
										<div class="dropdown" style="display: inline-block">
											<button class="btn btn-success btn-xs dropdown-toggle" type="button"  data-toggle="dropdown" aria-expanded="true">
												Switch ballots
												<span class="caret"></span>
											</button>
											<ul class="dropdown-menu dropdown-menu-right" role="menu">
												% for s in active_slots:
													<li {{!'class="active"' if s == sl else '' }}>
														<a href="?ballot={{ s.event.season.year }}-{{s.event.type.name}}">{{ s.event.season}}: {{ s.event.type.name }} </a>
													</li>
												% end
											</ul>
										</div>
									% end
								</span>
							</div>
						</div>
					% elif len(active_slots) == 1:
						% sl = active_slots[0]
						<div class="ballot-banner ballot-banner-incorrect-view">
							<div class="container">
								You're not looking at information for the right ballot ({{ sl.event.type.name }} {{ sl.event.season }}).
								<span class="pull-right">
									<a class="btn btn-xs btn-danger" href="?ballot={{ sl.event.season.year}}-{{s.event.type.name}}">Switch to my ballot</a>
								</span>
							</div>
						</div>
					% else:
						<div class="ballot-banner ballot-banner-incorrect-view">
							<div class="container">
								You're not looking at information for the right ballot.
								<div class="dropdown pull-right">
									<button class="btn btn-danger btn-xs dropdown-toggle" type="button"  data-toggle="dropdown" aria-expanded="true">
										Switch to my ballots
										<span class="caret"></span>
									</button>
									<ul class="dropdown-menu dropdown-menu-right" role="menu">
										% for s in active_slots:
											<li>
												<a href="?ballot={{ s.event.season.year }}-{{s.event.type.name}}">{{ s.event.season}}: {{ s.event.type.name }}</a>
											</li>
										% end
									</ul>
								</div>
							</div>
						</div>

					% end
				% end
			% end
		% end

		{{!base}}

		<script src="//netdna.bootstrapcdn.com/bootstrap/3.3.2/js/bootstrap.min.js"></script>
		<script src="/static/bootstrap-sortable.js"></script>
		<script>
		$(function() {
			$('.glyphicon[title]').add('*[data-tooltip]').tooltip();
		});
		function fixWrappedNav() {
			var nav = $('#page-specific-nav .nav').get(0);
			if(nav.offsetTop == 50) {
				$('body').css('margin-top', '100px');
			}
			else {
				$('body').css('margin-top', '');
			}
		}
		var timeout;
		$(window).resize(function() {
			clearTimeout(timeout);
			timeout = setTimeout(fixWrappedNav, 100);
		});
		fixWrappedNav();
		</script>

		<div id="footer">
			<div class="container">
				<p class="text-muted">Developed by Eric Wieser (efw27). Under continued development.</p>
			</div>
		</div>
		<script>
		(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
		(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
		m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
		})(window,document,'script','//www.google-analytics.com/analytics.js','ga');

		ga('create', 'UA-57228683-1', 'auto');
		% if request.user:
			ga('send', 'pageview', {dimension5: '{{ request.user.crsid }}'});
		% else:
			ga('send', 'pageview');
		% end
		</script>
	</body>
</html>

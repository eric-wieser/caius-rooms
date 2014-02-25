<!doctype html>
<html>
	<head>
	    <meta charset="utf-8">
	    <meta http-equiv="X-UA-Compatible" content="IE=edge">
	    <meta name="viewport" content="width=device-width, initial-scale=1">
		<link rel="icon" type="image/png" href="http://cdn.dustball.com/house.png">
		<link href="//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css" rel="stylesheet">
		<title>Rooms</title>
	</head>
	<body>
		<div class="container">
			% for i, room in rooms.iteritems():
			% 	reviews = room['reviews']
			% 	room['mean_score'] = sum(r['rating'] for r in reviews) * 1.0 / len(reviews) if reviews else None
			% 	room['id'] = int(i)
			%	n = len(reviews)
			% 	room['bayesian_rank'] = (3 + n * room['mean_score'] ) / (1 + n) if reviews else None
			% end
			% rooms = rooms.values()

			<h1>Rooms <small>({{len(rooms)}} in the ballot)</small></h1>
			<table class="table table-condensed">
				% for room in sorted(rooms, key=lambda r: (r['bayesian_rank'], len(r['images']), -r['id']), reverse=True):
					<tr>
						<td><a href="/rooms/{{room['id']}}">{{room['name']}}</a></td>
						<td>
							%if room['mean_score'] is not None:
								{{ '{:.1f}'.format(room['mean_score']) }}/10
							% end
						</td>
						<td>
							% if room['reviews']:
								% n = len(room['reviews'])
								{{ "%d review%s" % (n, "s"[n==1:]) }}
							% end
						</td>
						<td>
							% if room['images']:
								% n = len(room['images'])
								{{ "%d image%s" % (n, "s"[n==1:]) }}
							% end
						</td>
					</tr>
				% end
			</ul>
		</div>
	</body>
</html>
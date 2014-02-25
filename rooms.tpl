<!doctype html>
<html>
	<head>
	    <meta charset="utf-8">
	    <meta http-equiv="X-UA-Compatible" content="IE=edge">
	    <meta name="viewport" content="width=device-width, initial-scale=1">
		<link rel="icon" type="image/png" href="http://cdn.dustball.com/house.png">
		<link href="//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css" rel="stylesheet">
		<title>Room</title>
	</head>
	<body>
		<div class="container">
			<h1>Rooms</h1>
			<table class="table">

				% for i, room in rooms.iteritems():
				% 	reviews = room['reviews']
				% 	room['mean_score'] = sum(r['rating'] for r in reviews) * 1.0 / len(reviews) if reviews else None
				% 	room['id'] = i
				% end
			    % rooms = rooms.values()

				% for room in sorted(rooms, key=lambda r: r['mean_score'], reverse=True):
					<tr>
						<td><a href="/rooms/{{room['id']}}">{{room['name']}}</a></td>
						<td>
							%if room['mean_score'] is not None:
								{{ '{:.1f}'.format(room['mean_score']) }}/10
							% end
						</td>
						<td>
						 	({{len(room['reviews'])}} reviews)
						</td>
					</tr>
				% end
			</ul>
		</div>
	</body>
</html>
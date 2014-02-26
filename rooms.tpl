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
		<title>Rooms</title>
	</head>
	<body>
		<a href="https://github.com/eric-wieser/caius-rooms">
			<img style="position: absolute; top: 0; right: 0; border: 0;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_orange_ff7600.png" alt="Fork me on GitHub">
		</a>
		<div class="container">
			% for i, room in rooms.iteritems():
			% 	reviews = room['reviews']
			% 	room['mean_score'] = sum(r['rating'] for r in reviews) * 1.0 / len(reviews) if reviews else None
			%	n = len(reviews)
			% 	room['bayesian_rank'] = (3 + n * room['mean_score'] ) / (1 + n) if reviews else None
			% end
			% rooms = rooms.values()

			<h1>Rooms <small>({{len(rooms)}} in the ballot)</small></h1>
			<table class="table table-condensed">
				% for room in sorted(rooms, key=lambda r: (r['bayesian_rank'], len(r['images']), -r['id']), reverse=True):
					<tr class="room" data-roomid="{{room['id']}}">
						<td><a href="/rooms/{{room['id']}}">{{room['name']}}</a></td>
						<td>
							%if room['mean_score'] is not None:
								{{ '{:.1f}'.format(room['mean_score']) }}/10
							% end
						</td>
						<td style="text-align: right">
							% if room['reviews']:
								{{ len(room['reviews'])}} <span class="glyphicon glyphicon-pencil" title="reviews"></span>
							% end
						</td>
						<td style="text-align: right">
							% if room['images']:
								{{ len(room['images']) }} <span class="glyphicon glyphicon-picture" title="images"></span>
							% end
						</td>
					</tr>
				% end
			</ul>
		</div>
		<script>
		var thisRoom = {{! json.dumps(room['id']) }};
		if(localStorage['favorited-' + thisRoom])
			$('#favorite').addClass('btn-success');

		$('.room').each(function() {
			if(localStorage['favorited-' + $(this).data('roomid')]) {
				$(this).addClass('success');
			}
		});
		</script>
	</body>
</html>
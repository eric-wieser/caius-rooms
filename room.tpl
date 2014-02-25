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
		<title>Rooms | {{room['name']}}</title>
	</head>
	<body>
		<div class="container">
			<div style="position: fixed; top: 1em; right: 1em">
				<a class="btn btn-default" href='random'>
					<span class="glyphicon glyphicon-random"></span> Random</a></p>
				<button type="button" class="btn btn-default" id="favorite" title="Record as favorite on this PC">
					<span class="glyphicon glyphicon-star"></span> Favorite</button>

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
			% reviews = room['reviews']
			% if reviews:
				% mean_score = sum(r['rating'] for r in reviews) * 1.0 / len(reviews) 
				<h1>{{room['name']}} <small>{{ '{:.1f}'.format(mean_score) }}/10</small></h1>
			% else:
				<h1>{{room['name']}}</h1>
			% end
			<div class="images">
				%for image in room['images']:
					<img src="{{ image['href'] }}" class="img-rounded" />
					<p>{{ image['caption'] }}</p>
				%end
			</div>
			<div class="reviews">
				%for review in room['reviews']:
					<div>
						<h2>{{review['rated-in']}} <small>{{review['rating']}}/10</small></h2>
						<dl class="review dl-horizontal">
							%for k, v in review.iteritems():
								%if k not in ('rated-in', 'rating') and v:
									<dt>{{k}}</dt>
									<dd style="white-space: pre-wrap">{{v}}</dd>
								%end
							%end
						</dl>
					</div>
				%end
			</div>
		</div>
	</body>
</html>
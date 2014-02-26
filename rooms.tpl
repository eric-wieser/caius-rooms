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

		<link href="/static/bootstrap-sortable.css" rel="stylesheet">
		<script src="/static/bootstrap-sortable.js"></script>
		<title>Rooms</title>
		<style>
			td.shrink { width: 1px; white-space: nowrap; }
			td.center { text-align: center; }
			td.rule-right,
			th.rule-right { border-right: 1px solid #ddd; }
		</style>
	</head>
	<body>
		<a class="hidden-xs" href="https://github.com/eric-wieser/caius-rooms">
			<img style="position: absolute; top: 0; right: 0; border: 0;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_orange_ff7600.png" alt="Fork me on GitHub">
		</a>
		<div class="container">
			% for i, room in rooms.iteritems():
			% 	reviews = [r for r in room['reviews'] if r['rating'] is not None]
			% 	room['mean_score'] = sum(r['rating'] for r in reviews) * 1.0 / len(reviews) if reviews else None
			%	n = len(reviews)
			% 	room['bayesian_rank'] = (3 + n * room['mean_score'] ) / (1 + n) if reviews else None
			% end
			% rooms = rooms.values()

			<h1>Rooms <small>({{len(rooms)}} in the ballot)</small></h1>
			<table class="table table-condensed table-hover sortable">
				<thead>
					<tr>
						<th data-defaultsort='disabled' style="text-align: right">Room</th>
						<th class="rule-right">Block</th>
						<th>Rent</th>
						<th class="rule-right">Rating</th>
						<th data-defaultsort='disabled' colspan="3" class="rule-right" style="text-align: center">Feedback</th>
						<th data-defaultsort='disabled' colspan="4" style="text-align: center">Features</th>
					</tr>
				</thead>
				<tbody>
					% for room in sorted(rooms, key=lambda r: (r['bayesian_rank'], len(r['images']), -r['id']), reverse=True):
						<tr class="room" data-roomid="{{room['id']}}">
							<td class="shrink" style="text-align: right"><a href="/rooms/{{room['id']}}">{{room['number'] or room['name']}}</a></td>
							<td class="rule-right">{{room['place']}}</td>
							<td>
								%if 'details' in room and 'Estimated Rent' in room['details']:
									{{room['details']['Estimated Rent']}}
								% end
							</td>
							<td class="rule-right" data-value="{{room['bayesian_rank'] or 0}}">
								%if room['mean_score'] is not None:
									{{ '{:.1f}'.format(room['mean_score']) }}<span class="hidden-xs">/10</span>
								% end
							</td>
							<td class="shrink center">
								% if room['reviews']:
									% n = sum(r['rating'] != None for r in room['reviews'])
									% m = '1 review' if n == 1 else '{} reviews'.format(n)
									% if n != 0:
										<span class="hidden-xs" style="display: inline-block; width: 2ex; text-align: right">{{ n if n != 1 else '' }}</span>
										<span class="glyphicon glyphicon-comment" title="{{m}}"></span>
									% end
								% end
							</td>
							<td class="shrink center">
								% if room['reviews']:
									% n = sum('resident' in r for r in room['reviews'])
									% m = '1 resident' if n == 1 else '{} residents'.format(n)
									% if n != 0:
										<span class="hidden-xs" style="display: inline-block; width: 2ex; text-align: right">{{ n if n != 1 else '' }}</span>
										<span class="glyphicon glyphicon-user" title="{{m}}"></span>
									% end
								% end
							</td>
							<td class="shrink center rule-right">
								% if room['images']:
									<span class="hidden-xs" style="display: inline-block; width: 2ex; text-align: right">{{ len(room['images']) }}</span>
									<span class="glyphicon glyphicon-picture" title="images"></span>
								% end
							</td>
							% d = room.get('details', {})
							<td class="shrink center">
								% n = d.get('Network')
								% if n in ('Y', 'Yes'):
									<span class="glyphicon glyphicon-cloud text-success" title="Network"></span>
								% elif n in ('N', 'No'):
									<span class="glyphicon glyphicon-cloud text-muted" title="No Network"></span>
								% else:
									<span class="glyphicon glyphicon-cloud text-warning" title="Possible Network"></span>
								% end
							</td>
							<td class="shrink center">
								% p = d.get('Piano')
								% if p in ('Y', 'Yes'):
									<span class="glyphicon glyphicon-music text-success" title="Piano"></span>
								% elif p in ('N', 'No'):
									<span class="glyphicon glyphicon-music text-muted" title="No Piano"></span>
								% else:
									<span class="glyphicon glyphicon-music text-warning" title="Possible Piano"></span>
								%end
							</td>
							<td class="shrink center">
								% w = d.get('Washbasin')
								% if w in ('Y', 'Yes'):
									<span class="glyphicon glyphicon-tint text-success" title="Washbasin"></span>
								% elif w in ('N', 'No'):
									<span class="glyphicon glyphicon-tint text-muted" title="No Washbasin"></span>
								% else:
									<span class="glyphicon glyphicon-tint text-warning" title="Possible Washbasin"></span>
								%end
							</td>
							<td class="shrink center">
								% g = d.get('George Foreman nearby')
								% if g in ('Y', 'Yes'):
									<span class="glyphicon glyphicon-fire text-success" title="George Foreman"></span>
								% elif g in ('N', 'No'):
									<span class="glyphicon glyphicon-fire text-muted" title="No George Foreman"></span>
								% else:
									<span class="glyphicon glyphicon-fire text-warning" title="Possible George Foreman"></span>
								% end
							</td>
						</tr>
					% end
				</tbody>
			</table>
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
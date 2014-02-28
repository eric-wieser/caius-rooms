% import json
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


		<link href="/static/bootstrap-sortable.css" rel="stylesheet">
		<script src="/static/bootstrap-sortable.js"></script>
		<title>Rooms</title>
		<style>
			td.shrink { width: 1px; white-space: nowrap; }
			td.center { text-align: center; }
			td.rule-right,
			th.rule-right { border-right: 1px solid #ddd; }
		</style>
		<script>
		$(function() {
			$('.glyphicon[title]').tooltip();
		});
		</script>
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
						<th style="text-align: right">Room</th>
						<th class="rule-right">Block</th>
						<th>Rent</th>
						<th>Area</th>
						<th class="rule-right">Rating</th>
						<th data-defaultsort='disabled' colspan="3" class="rule-right" style="text-align: center">Feedback</th>
						<th data-defaultsort='disabled' colspan="4" style="text-align: center">Features</th>
					</tr>
				</thead>
				<tbody>
					% for room in sorted(rooms, key=lambda r: (r['bayesian_rank'], len(r['images']), -r['id']), reverse=True):
						<tr class="room" data-roomid="{{room['id']}}">
							% d = room.get('details', {})
							<td class="shrink" style="text-align: right">
								% if d.get('Type') == 'Suite':
									<span class="glyphicon glyphicon-th-large text-muted" title="Suite"></span>
								% end
								<a href="/rooms/{{room['id']}}">{{room['number'] or room['name']}}</a>
							</td>
							<td class="rule-right" data-value="{{room['place']['group'] or ''}} | {{room['place']['name']}}">
								{{room['place']['name']}}
								% if room['place'].get('unlisted'):
									<span class="label label-danger" title="Possibly not a real building">unlisted</span>
								% end
							</td>
							<td>
								%if 'details' in room and 'Estimated Rent' in room['details']:
									{{room['details']['Estimated Rent']}}
								% end
							</td>
							% b_space = d.get('Bedroom')
							% b_space = b_space and b_space.split(' sqr ft', 1)[0]
							% b_w, b_h = 0, 0
							% if b_space:
								% try:
									% b_w, b_h = map(int, b_space.split('*'))
								% except ValueError:
									% b_space = None
								% end
							% end

							% l_space = d.get('Living Room', '')
							% l_space = l_space and l_space.split(' sqr ft', 1)[0]
							% l_w, l_h = 0, 0
							% if l_space:
								% try:
									% l_w, l_h = map(int, l_space.split('*'))
								% except ValueError:
									% l_space = None
								% end
							% end

							% area = b_w * b_h + l_w * l_h
							<td data-value="{{area if b_space or l_space else -1}}">
								% if b_space or l_space:
									{{area}}<span class="hidden-xs">&nbsp;ft&sup2;</span>
								% end
								<span class="hidden-xs text-muted">
									% if b_space and l_space:
										({{b_w}}&times;{{b_h}} + {{l_w}}&times;{{l_h}})
									% elif b_space:
										({{b_w}}&times;{{b_h}})
									% elif l_space:
										({{l_w}}&times;{{l_h}})
									% end
								</span>
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
									% m = '1 recorded resident' if n == 1 else '{} recorded residents'.format(n)
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
									<span class="glyphicon glyphicon-cloud text-danger" title="No Network"></span>
								% else:
									<span class="glyphicon glyphicon-cloud text-muted" title="Possible Network"></span>
								% end
							</td>
							<td class="shrink center">
								% w = d.get('Washbasin')
								% if w in ('Y', 'Yes'):
									<span class="glyphicon glyphicon-tint text-success" title="Washbasin"></span>
								% elif w in ('N', 'No'):
									% pass
								% else:
									<span class="glyphicon glyphicon-tint text-muted" title="Possible Washbasin"></span>
								%end
							</td>
							<td class="shrink center">
								% p = d.get('Piano')
								% if p in ('Y', 'Yes'):
									<span class="glyphicon glyphicon-music text-success" title="Piano"></span>
								% elif p in ('N', 'No'):
									% pass
								% else:
									<span class="glyphicon glyphicon-music text-muted" title="Possible Piano"></span>
								%end
							</td>
						</tr>
					% end
				</tbody>
			</table>
		</div>
	</body>
</html>
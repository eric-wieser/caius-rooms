% def extra_nav():
	<li class="active"><a href='/places'><span class="glyphicon glyphicon-map-marker"></span> Places</a></li>
	<li><a href='/rooms'><span class="glyphicon glyphicon-home"></span> Rooms</a></li>
% end

% rebase layout.tpl extra_nav=extra_nav, random="/places/random"
% import re


% def atoi(text):
%     return int(text) if text.isdigit() else text
% end

% def natural_keys(text):
%     '''
%     alist.sort(key=natural_keys) sorts in human order
%     http://nedbatchelder.com/blog/200712/human_sorting.html
%     (See Toothy's implementation in the comments)
%     '''
%     return [ atoi(c) for c in re.split('(\d+)', text) ]
% end

% places = sorted(places, key=lambda p: (p['group'] or p['name'], natural_keys(p['name'])))
<div class="container">
	<table class="table table-condensed table-hover sortable">
		<thead>
			<tr>
				<th>Place</th>
				<th>Free rooms</th>
				<th>Mean Rating</th>
			</tr>
		</thead>
		<tbody>
			% for place in places:
				<tr>
					<td data-value="{{place['group'] or ''}} | {{place['name']}}">
						<a href="{{ get_url('place', place=place) }}">{{place['name']}}</a>
					</td>
					% n = sum(room['owner'] is None for room in place['rooms'])
					<td data-value="{{n}}">
						{{ n }} / {{ len(place['rooms']) }}
					</td>
					% ratings = [r['mean_score'] for r in place['rooms'] if r['mean_score'] is not None]
					<td>
						% if ratings:
							{{ '{:.1f}'.format(sum(ratings) / len(ratings)) }}
						% end
					</td>
				</tr>
			% end
		</tbody>
	</table>
</div>

% rebase layout.tpl
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
	<ul class="list-group">
		% for place in places:
			<li class="list-group-item">
				<a href="{{ get_url('place', place=place) }}">{{place['name']}}</a>
			</li>
		% end
	</ul>
</div>

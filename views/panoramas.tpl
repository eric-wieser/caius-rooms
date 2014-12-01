% rebase('layout')
% from utils import format_ts_html

% def layout_breadcrumb():
	% yield (None, 'Special pages')
	% yield ("/photos/panoramas", 'Panoramas')
% end

% import itertools
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

<div class="container">
	% for photo in photos:
		<div style="margin-bottom: 20px; overflow: hidden">
			% room = photo.occupancy.listing.room
			<img src="{{ photo.href }}" title="{{ photo.caption }}" class="img-rounded" style="width: 100%; display: block"/>
			{{ photo.caption }}
			<span class="text-muted pull-right">
				% if photo.occupancy.resident:
					<a href="/users/{{ photo.occupancy.resident.crsid }}">{{ photo.occupancy.resident.name }}</a> &bullet;
				% end
				<a href="/rooms/{{ room.id }}">{{ room.pretty_name() }}</a> &bullet;
				{{! format_ts_html(photo.published_at) }}
			</span>
		</div>
	% end
</div>

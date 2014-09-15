% rebase layout.tpl

% def layout_breadcrumb():
	% for part in place.path:
		% yield ("/places/{}".format(part.id), part.pretty_name(part.parent))
	% end
% end

% def layout_extra_nav():
	<li class="active"><a href="{{ get_url('place-photos', place_id=place.id) }}">
		<span class="glyphicon glyphicon-picture"></span> Photos
	</a></li>
% end

% layout_random = '/places/random/photos'

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
	% filtered_rooms  = place.all_rooms_q.all()
	% filtered_rooms.sort(key=lambda r: map(lambda l: l.name, r.parent.path + [r]))

	% def grouper(n, iterable, fillvalue=None):
    	% "grouper(3, 'ABCDEFG', 'x') --> ABC DEF Gxx"
    	% it = iter(iterable)
		% while True:
			% chunk = tuple(itertools.islice(it, n))
			% if not chunk:
				% return
			% end
			% yield chunk
		% end
    % end

	% def all_photos():
		% for room in filtered_rooms:
			% for listing in room.listings:
				% for occupancy in listing.occupancies:
					% for photo in occupancy.photos:
						% yield room, photo
					% end
				% end
			% end
		% end
	% end

	<div class="row">
		% for room, photo in all_photos():
			<div class="col-md-3 col-sm-4 col-xs-6">
				<a href="/rooms/{{room.id}}" title="{{ photo.caption }}" class="thumbnail cropped-photo" style="display: block; height: 200px; background-image: url({{ photo.href }}); margin: 15px 0px; position: relative; overflow: hidden" target="_blank"><span class="label label-default" style="display: block; position: absolute; top: 0; left: 0;">{{room.pretty_name(place)}}</span></a>
			</div>
		% end
	</div>
</div>

% rebase layout.tpl place=place, is_photos=True
% import itertools

<div class="container">
	% filtered_rooms = [r for r in rooms if r['place'] == place]
	% filtered_rooms.sort(key=lambda r: r['number'])

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
			% for photo in room['images']:
				% yield room, photo
			% end
		% end
	% end

	% for items in grouper(4, all_photos()):
		<div class="row">
			% for room, photo in items:
				<div class="col-md-3">
					<a href="/rooms/{{room['id']}}" title="{{photo['caption']}}" class="thumbnail" style="display: block; height: 200px; background-image: url({{ photo['href'] }}); margin: 15px 0px; position: relative; overflow: hidden" target="_blank"><span class="label label-default" style="display: block; position: absolute; top: 0; left: 0;">{{room['number']}}</span></a>
				</div>
			% end
		</div>
	% end

</div>

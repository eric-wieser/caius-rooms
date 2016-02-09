<%
def ordered_photos(photos, cols=6, rows=2):
	x = 0
	y = 0
	it = iter(photos)
	queued = []

	def fits(p):
		return x + 1 + p.is_panorama <= cols
	end
	while y < rows:
		if queued and fits(queued[0]):
			x += 1 + queued[0].is_panorama
			p, queued = queued[0], queued[1:]
			yield p
		else:
			p = next(it)
			if fits(p):
				x += 1 + p.is_panorama
				yield p
			else:
				queued.append(p)
			end
		end

		if x >= cols:
			x = 0
			y += 1
		end
	end
end
%>
% for photo in ordered_photos(photos, cols, rows):
	% room = photo.occupancy.listing.room
	<div class="{{ 'col-md-4 col-sm-6 col-xs-12' if photo.is_panorama else 'col-md-2 col-sm-3 col-xs-6' }} ">
		<a href="{{ url_for(room) }}" title="{{ photo.caption }}&NewLine;{{ photo.published_at }}" class="thumbnail cropped-photo" style="display: block; height: 150px; background-image: url({{ photo.href }}); margin: 15px 0px; position: relative; overflow: hidden" target="_blank"><span class="label label-default" style="display: block; position: absolute; top: 0; left: 0;">{{room.pretty_name()}}</span></a>
	</div>
% end
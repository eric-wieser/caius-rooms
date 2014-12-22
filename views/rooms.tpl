% rebase('layout')
% layout_random = '/rooms/random'

<a class="hidden-xs" href="https://github.com/eric-wieser/caius-rooms">
	<img style="position: absolute; top: 0px; right: 0; border: 0; z-index: 10000;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_orange_ff7600.png" alt="Fork me on GitHub">
</a>
<div class="container">
	% filtered_rooms = rooms
	% for filter in filters:
		% filtered_rooms = [room for room in filtered_rooms if filter(room)]
	% end

	% filtered_rooms.sort(key=lambda r: (r.adjusted_rating, r.photo_count, -r.id), reverse=True)
	<p class="lead">
		% if len(filtered_rooms) == len(rooms):
			{{len(rooms)}} in the ballot
		% else:
			Showing {{len(filtered_rooms)}} of {{len(rooms)}}
		% end
	</p>
	<ul class="list-group">
		% for filter in filters:
			<li class="list-group-item">{{filter.description}}</li>
		% end
	</ul>
	% include('parts/room-table', rooms=filtered_rooms, ballot=ballot, relative_to=None)
</div>

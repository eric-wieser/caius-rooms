% rebase('layout')
% layout_random = '/rooms/random'
<div class="container">
	% filtered_rooms = rooms
	% for filter in filters:
		% filtered_rooms = [room for room in filtered_rooms if filter(room)]
	% end

	<%
	filtered_rooms.sort(
		key=lambda r: (r.adjusted_rating, r.photo_count, -r.id),
		reverse=True
	)
	%>
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

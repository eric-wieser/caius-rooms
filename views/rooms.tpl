% from bottle import request
% rebase('layout')
% layout_random = '/rooms/random'
<div class="container">
	% n = roomsq.count()
	% for f in filters:
		% roomsq = roomsq.filter(f)
	% end
	% rooms = roomsq.all()

	<%
	rooms.sort(
		key=lambda r: (r.adjusted_rating, r.photo_count, -r.id),
		reverse=True
	)
	%>
	<p>
		<span class="lead">
			% if len(rooms) == n:
				Showing all {{n}} rooms
			% else:
				Showing {{len(rooms)}} of {{ n }}
			% end
		</span><br />
		<small class="text-muted">Owners and prices show are for the year {{ ballot}}</small>
	</p>
	% include('parts/room-table', rooms=rooms, ballot=ballot, relative_to=None)
</div>

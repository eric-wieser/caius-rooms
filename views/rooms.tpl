<%
rebase('layout')
layout_random = '/rooms/random'
%>
<div class="container">
	% include('parts/room-table', roomsq=roomsq, filters=filters, ballot=ballot, relative_to=None)
</div>

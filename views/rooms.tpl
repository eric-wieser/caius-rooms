<%
from bottle import request
from sqlalchemy.orm.session import object_session
import database.orm as m

rebase('layout')
layout_random = '/rooms/random'
%>
<div class="container">
	% n = roomsq.count()
	% for f in filters:
		% roomsq = roomsq.filter(f)
	% end
	% rooms = roomsq.all()

	<%
	rooms.sort(
		key=lambda r: (r.stats.adjusted_rating, r.stats.photo_count, -r.id),
		reverse=True
	)
	%>
	<div class="dropdown pull-right">
		<button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">
			Change year
			<span class="caret"></span>
		</button>
		<ul class="dropdown-menu dropdown-menu-right" role="menu" aria-labelledby="dropdownMenu1">
			% ballots = object_session(ballot).query(m.BallotSeason).order_by(m.BallotSeason.year.desc())
			% for b in ballots:
				<li {{! 'class="active"' if b == ballot else '' }} >
					<a href="?ballot={{ b.year }}">{{ b }}</a>
				</li>
			% end

		</ul>
	</div>
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

<%
from utils import format_ts_html, restricted, format_ballot_html, url_for
from bottle import request
%>
<table class="table">
	% for review in reviews:
		% room = review.occupancy.listing.room
		% author = review.occupancy.resident
		<tr>
			<td class="text-right">
				<a href="{{ url_for(room) }}#occupancy-{{review.occupancy.id}}">{{ room.pretty_name() }}</a>
			</td>
			% if request.user:
				<td>
					% if author:
						<a href="{{ url_for(author) }}" style="display: block; padding-left: 25px;">
							<img src="{{ author.gravatar(size=20) }}" width="20" height="20" style="margin-left: -25px; float: left" />
							{{ author.name }}
						</a>
					% else:
						<span class="text-muted">unknown</span>
					% end
				</td>
			% end
			<td>
				{{! format_ts_html(review.published_at) }}
			</td>
		</tr>
	%end
</table>

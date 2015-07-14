<%
import database.orm as m

rebase('layout')
layout_random = "/places/random"

def flatten_iter(p, level=0, path=[]):
	for c in p.children:
		yield c, level, path
		for np, nlevel, npath in flatten_iter(c, level + 1, path=path+[c]):
			yield np, nlevel, npath
		end
	end
end

if isinstance(ballot, m.BallotEvent):
	ballot_event = ballot
	ballot_season = ballot.season
else:
	ballot_event = None
	ballot_season = ballot
end
%>
<div class="container">
	<table class="table table-condensed table-hover sortable" id="place-heirarchy">
		<thead>
			<tr>
				<th>Place</th>
				<th>Free rooms</th>
				<th>Mean Rating</th>
			</tr>
		</thead>
		<tbody>
			% for i, (sub_loc, level, path) in enumerate(flatten_iter(location)):
				<%
				if not sub_loc.rooms:
					continue
				end
				%>
				<tr>
					<td {{! 'colspan="3"' if not sub_loc.rooms else '' }} data-value="{{ i }}">
						% for j, p in enumerate(path):
							<a class="small parent-link" style="margin-left: {{ 2 * j }}rem; display: block"
							   href="{{ url_for(p) }}"
							   data-id="{{ p.id }}">{{ p.pretty_name(p.parent) }}</a>
						% end
						<a style="margin-left: {{ 2 * level }}rem; "
						   href="{{ url_for(sub_loc) }}">{{ sub_loc.pretty_name(sub_loc.parent) }}</a>
					</td>
					% if sub_loc.rooms:
						<%
						n_rooms = len(sub_loc.rooms)
						n_free = sum(
							1
							for room in sub_loc.rooms
							if ballot_season in room.listing_for
							if ballot_event is None or ballot_event.type in room.listing_for[ballot_season].audience_types
							if all(occ.cancelled for occ in room.listing_for[ballot_season].occupancies)
						)
						%>
						<td data-value="{{n_free}}">
							{{ n_free }} / {{ n_rooms }}
						</td>
						% ratings = [r.stats.adjusted_rating for r in sub_loc.rooms if r.stats.adjusted_rating is not None]
						<td>
							% if ratings:
								{{ '{:.1f}'.format(sum(ratings) / len(ratings)) }}
							% end
						</td>
					% end
				</tr>
			% end
		</tbody>
	</table>
	<style>
	#place-heirarchy td {
		vertical-align: bottom;
	}
	.parent-link {
		text-transform: small-caps;
		font-weight: bold;
		color: rgb(119, 119, 119);
	}
	</style>
	<script>
	$('#place-heirarchy').on('sorted', function() {
		var last = [];
		$(this).children('tbody').children('tr').each(function() {
			var $cell = $(this).find('td').eq(0);
			var $parents = $cell.find('a.parent-link');

			var ids = $parents.map(function() { return $(this).data('id'); }).get()

			$parents.show().each(function(i) {
				if(ids[i] == last[i])
					$(this).hide();
				else
					return false;
			})

			last = ids;
		})
	});
	</script>
</div>

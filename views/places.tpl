<%
rebase('layout')
layout_random = "/places/random"

def flatten_iter(p, level=0):
	for c in p.children:
		yield c, level
		for np, nlevel in flatten_iter(c, level + 1):
			yield np, nlevel
		end
	end
end
%>
<div class="container">
	<table class="table table-condensed table-hover sortable">
		<thead>
			<tr>
				<th>Place</th>
				<th>Free rooms</th>
				<th>Mean Rating</th>
			</tr>
		</thead>
		<tbody>
			% for i, (sub_loc, level) in enumerate(flatten_iter(location)):
				<tr>
					<td {{! 'colspan="3"' if not sub_loc.rooms else '' }} data-value="{{ i }}">
						<a style="margin-left: {{ 2 * level }}em; "
						   href="/places/{{ sub_loc.id }}">{{ sub_loc.pretty_name(sub_loc.parent) }}</a>
					</td>
					% if sub_loc.rooms:
						% if False:
							% n = sum(room['owner'] is None for room in place['rooms'])
							<td data-value="{{n}}">
								{{ n }} / {{ len(place['rooms']) }}
							</td>
						% else:
						<td></td>
						% end
						% ratings = [r.adjusted_rating for r in sub_loc.rooms if r.adjusted_rating is not None]
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
	% for room in location.rooms:
		<div>
			<a href="/rooms/{{ room.id }}">{{ room.pretty_name(location) }}</a>
		</div>
	% end
</div>

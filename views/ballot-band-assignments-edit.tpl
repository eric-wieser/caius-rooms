% import database.orm as m
% from bottle import request
% from collections import Counter
% rebase('layout')

<%

def flatten_iter(p, level=0, path=[]):
	for c in p.children:
		yield c, level, path
		for np, nlevel, npath in flatten_iter(c, level + 1, path=path+[c]):
			yield np, nlevel, npath
		end
	end
end

def layout_breadcrumb():
	yield (url_for(ballot_season), u'{} season'.format(ballot_season))
	yield ('#', u'Editing Bands')
end

modifiers = sorted(modifiers, key=lambda b: b.name)
%>
<div class="container">
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
	$(function() {
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

		$('td.band-selector').each(function() {
			var self = this;
			$(this).find('select').change(function() {
				$(self).attr('data-value', this.value);
			});
		});
		$('td.modifier-selector').each(function() {
			var self = this;
			$(this).find('input').change(function() {
				$(self).attr('data-value',
					this.find('input').map(function() {
						return +$(this).prop('checked');
					}).get().join(',')
				);
			});
		});
	});
	</script>
	<form class="form-inline" method="post">
		<p><button type="submit" class="btn btn-danger" name='reset'>Reset band assignments to {{ballot_season.previous}}</button></p>

		<table class='table table-condensed sortable' id="place-heirarchy">
			<thead>
				<tr>
					<th>Room</th>
					<th>Band</th>
					<th>Modifiers</th>
				</tr>
			</thead>
			<tbody>
				% for r in sorted(ballot_season.room_listings, key=lambda rl: tuple(p.name for p in rl.room.parent.path + [rl.room])):
					<tr>
						<td>
							% path = r.room.parent.path
							% for j, p in enumerate(path):
								<a class="small parent-link" style="margin-left: {{ 2 * j }}rem; display: block"
								   href="{{ url_for(p) }}"
								   target='_blank'
								   data-id="{{ p.id }}">{{ p.pretty_name(p.parent) }}</a>
							% end
							<a href="{{url_for(r.room)}}" style="margin-left: {{ 2 * len(path) }}rem" target='_blank'>{{r.room.pretty_name()}}</a>
						</td>
						<td class="band-selector" data-value="{{r.band.id if r.band is not None else ''}}">
							<select class="form-control" name="listings[{{r.id}}].band">
								% if r.band is None:
									<option value="" selected>None</option>
								% else:
									<option value="">None</option>
								% end
								% for b in sorted(bands, key=lambda b: b.name):
									% if r.band == b:
										<option value="{{b.id}}" selected>{{b.name}}</option>
									% else:
										<option value="{{b.id}}">{{b.name}}</option>
									% end
								% end

							</select>
						</td>
						<td class="modifier-selector" data-value="{{ ','.join(['1' if b in r.modifiers else '0' for b in modifiers]) }}">
							% for b in sorted(modifiers, key=lambda b: b.name):
								<div class="checkbox" style="display: block">
									<label>
										% if b in r.modifiers:
											<input type="checkbox" name="listings[{{r.id}}].modifiers[]" value="{{b.id}}" checked />
										% else:
											<input type="checkbox" name="listings[{{r.id}}].modifiers[]" value="{{b.id}}" />
										% end
										{{b.name}}
									</label>
								</div>
							% end
						</td>
					</tr>
				% end
			</tbody>
		</table>
		<button type="submit" class="btn btn-primary">Save band assignments</button>
	</form>
</div>

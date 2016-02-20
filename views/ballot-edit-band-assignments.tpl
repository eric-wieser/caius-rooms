% import database.orm as m
% from bottle import request
% from collections import Counter
% rebase('layout')

<%
def layout_breadcrumb():
	yield (url_for(ballot_season), u'{} season'.format(ballot_season))
	yield ('#', u'Editing Bands')
end
%>
<div class="container">
	<div class="alert alert-warning">
		<strong>This form does not work yet</strong> - spending time filling it out leads only to sadness
	</div>
	<form class="form-inline" method="post">
		<table class='table table-condensed'>
			<thead>
				<tr>
					<th>Room</th>
					<th>Band</th>
					<th>Modifiers</th>
				</tr>
			</thead>
			<tbody>
				% for r in ballot_season.room_listings:
					<tr>
						<td><a href="{{url_for(r.room)}}" target='_blank'>{{r.room.pretty_name()}}</a></td>
						<td>
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
						<td>
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

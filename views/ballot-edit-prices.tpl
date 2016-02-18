% import database.orm as m
% from bottle import request
% from collections import Counter
% rebase('layout')

<%
def layout_breadcrumb():
	yield (url_for(ballot_season), u'{} season'.format(ballot_season))
	yield ('#', u'Editing Prices')
end
%>
<div class="container">
	<div class="alert alert-warning">
		<strong>This form does not work yet</strong> - spending time filling it out leads only to sadness
	</div>
	<form class="form-inline">
		<div class="row">
			<div class="col-md-6">
				<table class="table table-condensed">
					<thead>
						<tr>
							<th>Band</th>
							<th>Description</th>
							<th class='text-right'>Rent</th>
						</tr>
					</thead>
					<tbody>
						% active_bands = {b.band: b for b in ballot_season.band_prices}
						% for b in sorted(bands, key=lambda b: b.name):
							<tr>
								<td><span class="label" style="background-color: #{{b.color}}">{{b.name}}</span></td>
								<td>{{b.description}}</td>
								<td class='text-right'>
									<div class="input-group">
										<div class="input-group-addon">&pound;</div>
										<input class="form-control"  name="band-{{b.id}}" size="7" type="number" value="{{active_bands[b].rent if b in active_bands else ''}}" />
									</div>
								</td>
							</tr>
						% end
					</tbody>
				</table>
			</div>

			<div class="col-md-6">
				<table class="table table-condensed">
					<thead>
						<tr>
							<th>Modifier</th>
							<th>Description</th>
							<th class='text-right'>Discount</th>
						</tr>
					</thead>
					<tbody>
						% active_modifiers = {m.modifier: m for m in ballot_season.modifier_prices}
						% for b in sorted(modifiers, key=lambda b: b.name):
							<tr>
								<td>{{b.name}}</td>
								<td>{{b.description}}</td>
								<td class='text-right'>
									<div class="input-group">
										<div class="input-group-addon">&pound;</div>
										<input class="form-control"  name="modifier-{{b.id}}" size='7' type="number" value="{{active_modifiers[b].discount if b in active_modifiers else ''}}" />
									</div>
								</td>
							</tr>
						% end
					</tbody>
				</table>
			</div>
		</div>

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
							<select class="form-control">
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
											<input type="checkbox" name="{{r.id}}-mod" value="{{b.id}}" checked />
										% else:
											<input type="checkbox" name="{{r.id}}-mod" value="{{b.id}}" />
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
		<button type="submit" class="btn btn-primary">Update band prices</button>
	</form>
</div>

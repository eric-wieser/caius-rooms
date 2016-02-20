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
	<form class="form-inline" method="post">
		<div class="row">
			<div class="col-md-6">
				<table class="table table-condensed">
					<thead>
						<tr>
							<th>Band</th>
							<th>Description</th>
							% if last_ballot:
								<th class='text-right'>
									Rent from {{ last_ballot }}
								</th>
							% end
							<th class='text-right'>New Rent</th>
						</tr>
					</thead>
					<tbody>
						% active_bands = {b.band: b for b in ballot_season.band_prices}
						% last_bands = {b.band: b for b in last_ballot.band_prices} if last_ballot else {}
						% for b in sorted(bands, key=lambda b: b.name):
							<tr>
								<td><span class="label" style="background-color: #{{b.color}}">{{b.name}}</span></td>
								<td>{{b.description}}</td>
								% if last_ballot:
									<td class='text-right'>
										% if b in last_bands:
											&pound;{{last_bands[b].rent}}
										% end
									</td>
								% end
								<td class='text-right'>
									<div class="input-group">
										<div class="input-group-addon">&pound;</div>
										<input class="form-control" name="bands[{{b.id}}].rent" size="7" type="number" value="{{active_bands[b].rent if b in active_bands else ''}}" />
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
										<input class="form-control"  name="modifiers[{{b.id}}].discount" size='7' type="number" value="{{active_modifiers[b].discount if b in active_modifiers else ''}}" />
									</div>
								</td>
							</tr>
						% end
					</tbody>
				</table>
			</div>
		</div>
		<div class="row">
			<div class='col-sm-6 text-left'>
				<button type="submit" class="btn btn-primary">Update band prices</button>
			</div>
			<div class='col-sm-6 text-right'>
				<a href='edit-band-assignments' class="btn btn-default" target='_blank'>Edit band assignments</a>
			</div>
		</div>
	</form>
</div>

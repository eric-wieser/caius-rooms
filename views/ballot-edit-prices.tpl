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
							% if ballot_season.previous:
								<th class='text-right'>
									Rent from <span style='white-space: nowrap'>{{ ballot_season.previous }}</span>
								</th>
							% end
							<th class='text-right'>New Rent</th>
						</tr>
					</thead>
					<tbody>
						% for b in sorted(bands, key=lambda b: b.name):
							% price = b.price_for.get(ballot_season)
							% last_price = b.price_for.get(ballot_season.previous)
							<tr>
								<td><span class="label" style="background-color: #{{b.color}}">{{b.name}}</span></td>
								<td>{{b.description}}</td>
								% if ballot_season.previous:
									<td class='text-right'>
										% if last_price:
											&pound;{{last_price.rent}}
										% else:
											<span class="text-muted">Not set</span>
										% end
									</td>
								% end
								<td class='text-right'>
									<div class="input-group">
										<div class="input-group-addon">&pound;</div>
										<input class="form-control" name="bands[{{b.id}}].rent" size="7" type="number" step="0.01" value="{{price.rent if price else ''}}" />
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
							% if ballot_season.previous:
								<th class='text-right'>
									Discount in <span style='white-space: nowrap'>{{ ballot_season.previous }}</span>
								</th>
							% end
							<th class='text-right'>Discount</th>
						</tr>
					</thead>
					<tbody>
						% active_modifiers = {m.modifier: m for m in ballot_season.modifier_prices}
						% for b in sorted(modifiers, key=lambda b: b.name):
							% price = b.price_for.get(ballot_season)
							% last_price = b.price_for.get(ballot_season.previous)
							<tr>
								<td>{{b.name}}</td>
								<td>{{b.description}}</td>
								% if ballot_season.previous:
									<td class='text-right'>
										% if last_price:
											&pound;{{last_price.discount}}
										% else:
											<span class="text-muted">Not set</span>
										% end
									</td>
								% end
								<td class='text-right'>
									<div class="input-group">
										<div class="input-group-addon">&pound;</div>
										<input class="form-control"  name="modifiers[{{b.id}}].discount" size='7' type="number" step="0.01" value="{{price.discount if price else ''}}" />
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
		</div>
	</form>
</div>

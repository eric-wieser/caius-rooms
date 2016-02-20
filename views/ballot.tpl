% import database.orm as m
% from bottle import request
% from collections import Counter
% rebase('layout')

<%
def layout_breadcrumb():
	yield ('#', u'{} season'.format(ballot_season))
end

show_edit = request.user and request.user.is_admin
%>
<div class="container">

	<h1>Ballots for {{ ballot_season }}</h1>

	% by_band = Counter(l.band for l in ballot_season.room_listings)
	% by_modifier = Counter(m for l in ballot_season.room_listings for m in l.modifiers)
	<h2>
		Prices
		% if show_edit:
			<small><a href="{{ url_for(ballot_season, extra_path="edit-prices") }}">
				<span class="glyphicon glyphicon-pencil"></span>
			</a></small>
		% end
	</h2>

	<div class="row">
		<div class="col-md-6">
			<table class="table table-condensed">
				<thead>
					<tr>
						<th>Band</th>
						<th>Description</th>
						<th class='text-right'>Rent</th>
						<th class='text-right'>Rooms</th>
					</tr>
				</thead>
				<tbody>
					% for b in sorted(ballot_season.band_prices, key=lambda b: b.band.name):
						<tr>
							<td><span class="label" style="background-color: #{{b.band.color}}">{{b.band.name}}</span></td>
							<td>{{b.band.description}}</td>
							<td class='text-right'>
								% last_b = b.band.price_for.get(ballot_season.previous)
								% if last_b and b.rent and last_b.rent:
									% pct = 100 * (b.rent - last_b.rent) / last_b.rent
									% if pct > 0:
										<small class="text text-danger" title='Compared to &pound;{{last_b.rent}}'>+{{ '{:.2f}'.format(pct)}}%</small>
									% else:
										<small class="text text-success" title='Compared to &pound;{{last_b.rent}}'>&minus;{{ '{:.2f}'.format(abs(pct))}}%</small>
									% end
								% end
								&pound;{{b.rent}}
							</td>
							<td class='text-right'>{{by_band[b.band]}}</td>
						</tr>
					% end
					% if by_band[None]:
						% unpriced = sum(l.rent is None and l.band is None for l in ballot_season.room_listings)
						% unbanded = by_band[None] - unpriced
						% if unbanded:
							<tr>
								<td></td>
								<td>Unbanded</td>
								<td></td>
								<td class='text-right'>{{by_band[None] - unpriced}}</td>
							</tr>
						% end
						% if unpriced:
							<tr>
								<td></td>
								<td>Unpriced</td>
								<td></td>
								<td class='text-right'>{{ unpriced}}</td>
							</tr>
						% end
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
						<th class='text-right'>Rooms</th>
					</tr>
				</thead>
				<tbody>
					% for b in sorted(ballot_season.modifier_prices, key=lambda b: b.modifier.name):
						<tr>
							<td>{{b.modifier.name}}</td>
							<td>{{b.modifier.description}}</td>
							<td class='text-right'>
								% last_b = b.modifier.price_for.get(ballot_season.previous)
								% if last_b and b.discount and last_b.discount:
									% pct = 100 * (b.discount - last_b.discount) / last_b.discount
									% if pct > 0:
										<small class="text text-success" title='Compared to &pound;{{last_b.discount}}'>+{{ '{:.2f}'.format(pct)}}%</small>
									% else:
										<small class="text text-danger" title='Compared to &pound;{{last_b.discount}}'>&minus;{{ '{:.2f}'.format(abs(pct))}}%</small>
									% end
								% end
								&pound;{{b.discount}}
							</td>
							<td class='text-right'>{{by_modifier[b.modifier]}}</td>
						</tr>
					% end
				</tbody>
			</table>
		</div>
	</div>

	% if show_edit:
		<a href="{{ url_for(ballot_season, extra_path='add-event') }}" class="btn btn-primary pull-right">
			<span class="glyphicon glyphicon-plus"></span> Add new ballot event
		</a>
	% end
	<h2>Schedule</h2>

	<div class="row">
		% for event in ballot_season.events:
			<div class="col-md-4">
				<h3>
					{{ event.type.name }}
					<small>
						{{ '{:%d %b}'.format(event.opens_at) }}
						&#x2012;
						{{ '{:%d %b}'.format(event.closes_at) }}

						% if show_edit:
							<a href="{{ url_for(ballot_season, extra_path="{}/edit".format(event.type.name)) }}">
								<span class="glyphicon glyphicon-pencil"></span>
							</a>
						% end
					</small>
				</h3>

				<table class="table table-condensed">
					<tbody>
						<%
						pred = None

						from datetime import datetime, timedelta
						# if request.user.is_admin:
						# 	pass
						# elif max(s.time for s in event.slots) < datetime.now():
						# 	pass

						# elif event in request.user.slot_for:
						# 	st = request.user.slot_for[event].time
						# 	width = timedelta(minutes=45)
						# 	pred = lambda _1, _2, ts: st - width <= ts <= st + width
						# else:
						# 	pred = lambda *args: False
						# end
						include('parts/slot-list-rows', pred=pred, slot_tuples=(
							(s.id, s.person, s.time)
							for s in event.slots
						))
						%>
					</tbody>
				</table>
			</div>
		% end
	</div>
</div>

% import database.orm as m
% from bottle import request
% from collections import Counter, defaultdict
% rebase('layout')

<%
def layout_breadcrumb():
	yield ('#', u'{} season'.format(ballot_season))
end
show_pct_change = True

show_edit = request.user and request.user.is_admin
%>
<div class="container">

	<h1>Ballots for {{ ballot_season }}</h1>

	% by_band = defaultdict(set)
	% by_modifier = defaultdict(set)
	% for l in ballot_season.room_listings:
		% by_band[l.band].add(l.room_id)
		% for m in l.modifiers:
			% by_modifier[m].add(l.room_id)
		% end
	% end

	% by_band_prev = defaultdict(set)
	% by_modifier_prev = defaultdict(set)
	% if ballot_season.previous:
		% for l in ballot_season.previous.room_listings:
			% by_band_prev[l.band].add(l.room_id)
			% for m in l.modifiers:
				% by_modifier_prev[m].add(l.room_id)
			% end
		% end
	% end
	<h2>
		Prices
		% if show_edit:
			<small><a href="{{ url_for(ballot_season, extra_path="edit-prices") }}">
				<span class="glyphicon glyphicon-pencil"></span>
			</a></small>
		% end
		<a href="{{ url_for(ballot_season, extra_path='band-assignments') }}" class="btn btn-default pull-right">
			<span class="glyphicon glyphicon-transfer"></span> View band and modifier changes
		</a>
	</h2>
	<p>Red and green numbers next to columns indicate changes since last year. If cells are blank, then there is no information yet for this year.</p>
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
					% for b in sorted((b for b in by_band if b is not None), key=lambda b: b.name):
						<tr>
							<td><span class="label" style="background-color: #{{b.color}}">{{b.name}}</span></td>
							<td>{{b.description}}</td>
							<td class='text-right'>
								% b_price = b.price_for.get(ballot_season)
								% last_b_price = b.price_for.get(ballot_season.previous)
								% if show_pct_change and last_b_price and b_price and b_price.rent and last_b_price.rent:
									% pct = 100 * (b_price.rent - last_b_price.rent) / last_b_price.rent
									% if pct > 0:
										<small class="text text-danger" title='Compared to &pound;{{last_b_price.rent}}'>+{{ '{:.2f}'.format(pct)}}%</small>
									% else:
										<small class="text text-success" title='Compared to &pound;{{last_b_price.rent}}'>&minus;{{ '{:.2f}'.format(abs(pct))}}%</small>
									% end
								% end
								% if b_price:
									&pound;{{b_price.rent}}
								% end
							</td>
							<td class='text-right'>
								% if by_band[b] - by_band_prev[b]:
									<a href="/rooms?ballot={{ballot_season.year}}&amp;filter_id={{','.join(str(l) for l in by_band[b] - by_band_prev[b])}}"
									   class='small text-success' target='_blank'>
										+{{len(by_band[b] - by_band_prev[b])}}</a>
								% end
								% if by_band_prev[b] - by_band[b]:
									<a href="/rooms?ballot={{ballot_season.previous.year}}&amp;filter_id={{','.join(str(l) for l in by_band_prev[b] - by_band[b])}}"
									   class='small text-danger' target='_blank'>
										&minus;{{len(by_band_prev[b] - by_band[b])}}</a>
								% end
								<a href='/rooms?ballot={{ballot_season.year}}&amp;filter_id={{','.join(str(l) for l in by_band[b])}}' target='_blank'>{{len(by_band[b])}}</a>
							</td>
						</tr>
					% end
					% if by_band[None]:
						% unpriced = {l.room_id for l in ballot_season.room_listings if l.rent is None and l.band is None}
						% unbanded = by_band[None] - unpriced
						% if unbanded:
							<tr>
								<td></td>
								<td>Unbanded</td>
								<td></td>
								<td class='text-right'>
									<a href='/rooms?ballot={{ballot_season.year}}&amp;filter_id={{','.join(str(l) for l in unbanded)}}' target='_blank'>{{len(unbanded)}}</a>
								</td>
							</tr>
						% end
						% if unpriced:
							<tr>
								<td></td>
								<td>Unpriced</td>
								<td></td>
								<td class='text-right'>
									<a href='/rooms?ballot={{ballot_season.year}}&amp;filter_id={{','.join(str(l) for l in unpriced)}}' target='_blank'>{{len(unpriced)}}</a>
								</td>
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
					% for b in sorted((b for b in by_modifier if b is not None), key=lambda b: b.name):
						<tr>
							<td>{{b.name}}</td>
							<td>{{b.description}}</td>
							<td class='text-right'>
								% b_price = b.price_for.get(ballot_season)
								% last_b_price = b.price_for.get(ballot_season.previous)
								% if show_pct_change and last_b_price and b_price and b_price.discount and last_b_price.discount:
									% pct = 100 * (b_price.discount - last_b_price.discount) / last_b_price.discount
									% if pct > 0:
										<small class="text-success" title='Compared to &pound;{{last_b_price.discount}}'>+{{ '{:.2f}'.format(pct)}}%</small>
									% else:
										<small class="text-danger" title='Compared to &pound;{{last_b_price.discount}}'>&minus;{{ '{:.2f}'.format(abs(pct))}}%</small>
									% end
								% end
								% if b_price:
									&pound;{{b_price.discount}}
								% end
							</td>
							<td class='text-right'>
								% if by_modifier[b] - by_modifier_prev[b]:
									<a href="/rooms?ballot={{ballot_season.year}}&amp;filter_id={{','.join(str(l) for l in by_modifier[b] - by_modifier_prev[b])}}"
									   class='small text-success' target='_blank'>
										+{{len(by_modifier[b] - by_modifier_prev[b])}}</a>
								% end
								% if by_modifier_prev[b] - by_modifier[b]:
									<a href="/rooms?ballot={{ballot_season.previous.year}}&amp;filter_id={{','.join(str(l) for l in by_modifier_prev[b] - by_modifier[b])}}"
									   class='small text-danger' target='_blank'>
										&minus;{{len(by_modifier_prev[b] - by_modifier[b])}}</a>
								% end
								<a href='/rooms?ballot={{ballot_season.year}}&amp;filter_id={{','.join(str(l) for l in by_modifier[b])}}' target='_blank'>{{len(by_modifier[b])}}</a>
							</td>
						</tr>
					% end
				</tbody>
			</table>
		</div>
	</div>
	% if not show_pct_change:
		<div class='text-muted'>
			Not showing the percentage increase in prices yet, as the prices are not finalized
		</div>
	% else:
		<div class='text-muted'>
			Note that prices do not reflect the actual charge made by the college, which will be rounded
			to a multiple of 70p for technical reasons.
		</div>
	% end

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

% rebase('layout')
% from sqlalchemy import inspect

<%
def last_it(it):
	it = iter(it)
	last = next(it)
	for i in it:
		yield last, False
		last = i
	end
	yield last, True
end

done = all([user, room, season])
if done:
	dest_listing = room.listing_for.get(season)
	occ_dest = [
		occ
		for occ in dest_listing.occupancies
		if not occ.cancelled
	] if dest_listing else []
	occ_src = [
		occ
		for occ in user.occupancies
		if occ.listing.ballot_season == season
		if not occ.cancelled
	]
else:
	occ_dest = []
	occ_src = []
end
%>
<div class="container">
	<h1>Assign rooms</h1>
	<form method="{{ 'GET' if not done else 'POST' }}">
		<div class="row">
			<div class="col-md-4">
				<div class="form-group">
					<label for="user-input">User</label>
					% if user:
						<div class="form-control">
							<img width="30" height="30" style="display: inline-block; vertical-align: top; margin: -5px 5px -5px 0" src="{{ user.gravatar(size=30) }}" /><a href="{{ url_for(user) }}">{{user.name}}</a>
						</div>
						<input id="user-input" name="user" type="hidden" value="{{ user.crsid }}" />
					% else:
						<input id="user-input" name="user" class="form-control" placeholder="crsid" />
					% end
				</div>
				% if user and inspect(user).transient:
					<div class='alert alert-warning'>
						This user is new to the roompicks system, but their CRSID is valid - check this was intentional.
					</div>
				% end
				% if occ_src:
					<div class="alert alert-danger">
						This user is already booked into
						% for o, is_last in last_it(occ_src):
							<a href="{{ url_for(o.listing.room) }}" target="_blank">{{ o.listing.room.pretty_name() }}</a>
						% end
						for this season.
						<div class="radio">
							<label>
								<input type="radio" name="cancel_src" value="1" checked />Cancel their occupancy in the previous room(s), so future balloters can choose them
							</label>
						</div>
						<div class="radio">
							<label>
								<input type="radio" name="cancel_src" value="0" /> Leave the occupancy in the previous room(s), if the student is now occupying both old and new rooms
							</label>
						</div>
						% if len(occ_dest) == 1:
							<div class="radio">
								<label>
									<input type="radio" name="cancel_src" value="swap" class="exclusive"/> Swap this student with the student in their destination room
								</label>
							</div>
						% end
					</div>
				% end
			</div>

			<div class="col-md-4">
				<div class="form-group">
					<label for="room-input">Room</label>
					% if room:
						<div class="form-control">
							<a href="{{ url_for(room) }}">{{ room.pretty_name() }}</a>
						</div>
						<input id="room-input" name="room" type="hidden" value="{{ room.id }}" />
					% else:
						<input id="room-input" name="room" class="form-control" placeholder="room id" />
					% end
				</div>
				% if occ_dest:
					<div class="alert alert-danger">
						This room is already occupied by
						% for o, is_last in last_it(occ_dest):
							<a href="{{ url_for(o.resident) }}" target="_blank">{{o.resident.name}}</a>
						% end
						for this season.
						<div class="radio">
							<label>
								<input type="radio" name="cancel_dest" value="1" checked />Cancel their occupancy, leaving them free to book another room
							</label>
						</div>
						<div class="radio">
							<label>
								<input type="radio" name="cancel_dest" value="0" />Allow both people to occupy the new room, as in the case of a shared set
							</label>
						</div>
						% if len(occ_src) == 1:
							<div class="radio">
								<label>
									<input type="radio" name="cancel_dest" value="swap" /> Swap this student with the student moving into their room
								</label>
							</div>
						% end
					</div>
				% end
			</div>

			<script>
			// make sure that if one swap is selected, so is the other
			$(function() {
				var i0 = $('input[name=cancel_dest'), i1 = $('input[name=cancel_src]');

				[[i0, i1], [i1, i0]].forEach(function(p) {
					p[0].on('change', function() {
						var isSwap = p.map(function(el) { return el.filter(':checked').val() == 'swap'; });
						if(isSwap[0] && !isSwap[1]) p[1].val(['swap']);
						else if(!isSwap[0] && isSwap[1]) p[1].val(['1']);
					});
				})
			})
			</script>

			<div class="col-md-4">
				<div class="form-group">
					<label for="room-input">Rental period</label>
					<select name="year" class="form-control" {{ 'readonly' if done else ''}} >
						% for s in reversed(seasons):
							<option value="{{ s.year }}"{{ ' selected' if s == season else ''}}>{{ s }}</option>
						% end
					</select>
				</div>
			</div>
		</div>

		<div class="form-group">
			<button type="submit" id="submit-button" class="btn btn-success pull-right">{{ 'Confirm' if done else 'Check' }}</button>
		</div>
	</form>
</div>
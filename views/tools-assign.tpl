% rebase('layout')

<div class="container">
	<h1>Assign rooms</h1>
	% done = all([user, room, season])
	<form method="{{ 'GET' if not done else 'POST' }}">
		<div class="row">
			<div class="col-md-4">
				<div class="form-group">
					<label for="user-input">User</label>
					% if user:
						<div class="form-control">
							<img width="30" height="30" style="display: inline-block; vertical-align: top; margin: -5px 5px -5px 0" src="{{ user.gravatar(size=30) }}" /><a href="/users/{{ user.crsid}}">{{user.name}}</a>
						</div>
						<input id="user-input" name="user" type="hidden" value="{{ user.crsid }}" />
					% else:
						<input id="user-input" name="user" class="form-control" placeholder="crsid" />
					% end
				</div>
			</div>

			<div class="col-md-4">
				<div class="form-group">
					<label for="room-input">Room</label>
					% if room:
						<div class="form-control">
							<a href="/rooms/{{ room.id }}">{{ room.pretty_name() }}</a>
						</div>
						<input id="room-input" name="room" type="hidden" value="{{ room.id }}" />
					% else:
						<input id="room-input" name="room" class="form-control" placeholder="room id" />
					% end
				</div>
			</div>

			<div class="col-md-4">
				<div class="form-group">
					<label for="room-input">Rental period</label>
					<select name="year" class="form-control">
						% for s in reversed(seasons):
							<option value="{{ s.year }}"{{ ' selected' if s == season else ''}}>{{ s }}</option>
						% end
					</select>
				</div>
			</div>
		</div>
		<div class="form-group">
			<button type="submit" id="submit-button" class="btn btn-success">{{ 'Confirm' if done else 'Check' }}</button>
		</div>
	</form>
</div>
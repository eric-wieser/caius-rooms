<%
rebase('layout')
def layout_breadcrumb():
	yield (
		'/ballots/{}'.format(ballot_season.year),
		'{} - {} season'.format(ballot_season.year, ballot_season.year + 1))
	yield ('#', 'Add new event')
end
%>

<div class="container">
	<h1>Add new ballot event</h1>
	<form method="POST">
		<div class="row">
			<div class="col-md-4">
				<div class="form-group">
					<label for="type-input">Type</label>
					<select id="type-input" name="type" class="form-control">
						% for e, exists in event_types:
							% if not exists:
								<option value="{{ e.id }}">{{ e.name }}</option>
							% else:
								<option value="{{ e.id }}" disabled="disabled" title="Already exists!">{{ e.name }}</option>
							% end
						% end
					</select>
				</div>
			</div>
			<div class="col-md-4">
				<div class="form-group">
					<label for="opens_at-input">Opens at</label>
					<input id="opens_at-input" name="opens_at" type="date" class="form-control" />
				</div>
			</div>
			<div class="col-md-4">
				<div class="form-group">
					<label for="closes_at-input">End date</label>
					<input id="closes_at-input" name="closes_at" type="date" class="form-control" />
				</div>
			</div>
		</div>
		<div class="form-group">
			<button type="submit" id="submit-button" class="btn btn-success">Add</button>
		</div>
	</form>
</div>
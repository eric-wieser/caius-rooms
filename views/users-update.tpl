% rebase('layout')

<div class="container">
	<h1>Checking user names</h1>
	<p>Data is from <a href="http://lookup.cam.ac.uk">lookup.cam.ac.uk</a>. Changes are shown below. Use the delete buttons to remove unwanted changes, and the blue buttons to apply columns of changes</p>
	<div class="row">
		<div class="col-md-12">
			<h2>Missing users <small>{{ len(users_unknown) }}</small></h2>
			<p>Users who don't exist, according to lookup. These need their crsids changing!</p>
			<table class="table">
				% for user in sorted(users_unknown, key=lambda u: u.crsid):
					<tr>
						<td>
							<div style="padding-left: 25px; position: relative; min-height: 20px">
								<a href="{{ url_for(user) }}">
									<img src="{{ user.gravatar(size=20) }}" width="20" height="20" style="position: absolute; left: 0; right: 0" />
									<div style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis">
										% if user.name:
											{{ user.name }}
										% else:
											<span class="text-muted">{{user.crsid}}</span>
										% end
										% if user.is_admin:
											<span title="administrator">&diams;</span>
										% end
									</div>
								</a>
							</div>
						</td>
					</tr>
				% end
			</table>
		</div>

		<div class="col-md-6">
			<h2>Manually entered names <small>{{ len(users_reverted) }}</small></h2>
			<p>Users who haven't set a manual name on lookup, but have one here</p>
			<table class="table">
				<thead>
					<tr>
						<th>Custom name on Roompicks</th>
						<th>Default name on lookup.cam.ac.uk</th>
					</tr>
				</thead>
				% for user in sorted(users_reverted, key=lambda u: u.crsid):
					<tr>
						<td>
							<div style="padding-left: 25px; position: relative; min-height: 20px">
								<a href="{{ url_for(user) }}">
									<img src="{{ user.gravatar(size=20) }}" width="20" height="20" style="position: absolute; left: 0; right: 0" />
									<div style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis">
										% if user.name:
											{{ user.name }}
										% else:
											<span class="text-muted">{{user.crsid}}</span>
										% end
										% if user.is_admin:
											<span title="administrator">&diams;</span>
										% end
									</div>
								</a>
							</div>
						</td>
						<td>
							{{ names[user] }}
						</td>
					</tr>
				% end
			</table>
		</div>

		<div class="col-md-6">
			<form method="post">
				<h2>Changed names <small>{{ len(users) or 'None'}}</small></h2>
				<p>Other name changes</p>
				% if users:
					<p>
						<button type="submit" class="btn btn-primary text-right">Accept changes</button>
					</p>
					<table class="table" id="changed-names">
						<thead>
							<tr>
								<th>Current name on Roompicks</th>
								<th>New name from lookup.cam.ac.uk</th>
							</tr>
						</thead>
						% for user in sorted(users, key=lambda u: u.crsid):
							<tr>
								<td>
									<div style="padding-left: 25px; position: relative; min-height: 20px">
										<a href="{{ url_for(user) }}">
											<img src="{{ user.gravatar(size=20) }}" width="20" height="20" style="position: absolute; left: 0; right: 0" />
											<div style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis">
												% if user.name:
													{{ user.name }}
												% else:
													<span class="text-muted">{{user.crsid}}</span>
												% end
												% if user.is_admin:
													<span title="administrator">&diams;</span>
												% end
											</div>
										</a>
									</div>
								</td>
								<td>
									<input type="hidden" name="{{ user.crsid }}-name" value="{{ names[user] }}">
									{{ names[user] }}
								</td>
								<td>
									<a href="#" class="text-danger delete-user">
										<span class="glyphicon glyphicon-remove"></span>
									</a>
								</td>
							</tr>
						% end
					</table>
					<script>
					$(function() {
						$('#changed-names').find('tr').each(function() {
							var $t =  $(this);
							$t.find('.delete-user').on('click', function() {
								$t.fadeOut(function() { $(this).remove(); });
								return false;
							});
						});
					});
					</script>
				% end
			</form>
		</div>
	</div>
</div>
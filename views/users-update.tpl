% rebase('layout')
% layout_random = "/users/random"

<div class="container">
	<h1>Updating user names</h1>
	<p>Data is from <a href="http://lookup.cam.ac.uk">lookup.cam.ac.uk</a>. Changes are shown below</p>
	<table class="table">
		% for user, new_name in data:
			<tr>
				<td>
					<div style="padding-left: 25px; position: relative; min-height: 20px">
						<a href="/users/{{ user.crsid }}">
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
					% if new_name:
						{{new_name}}
					% else:
						<span class="text-muted">crsid not found</span>
					% end
				</td>
			</tr>
		% end
	</table>
</div>

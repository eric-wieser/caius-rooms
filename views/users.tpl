% rebase('layout')
% layout_random = "/users/random"

<%
from bottle import request
def layout_extra_nav():
	if request.user and request.user.is_admin: %>
		<li class="dropdown">
			<a href="#" class="dropdown-toggle" data-toggle="dropdown">
				<span class="glyphicon glyphicon-flag text-danger"></span> Admin <span class="caret"></span>
			</a>
			<ul class="dropdown-menu" role="menu">
				<li><a href="/users/update">Update names from lookup</a></li>
			</ul>
		</li>
		<%
	end
end
%>

<div class="container">
	<div class="row">
		% for user in users:
			<div class="col-lg-2 col-md-3 col-sm-4 col-xs-6" style="margin-top: 5px; margin-bottom: 5px">
				<div style="padding-left: 50px; position: relative; min-height: 40px">
					<a href="{{ url_for(user) }}">
						<img src="{{ user.gravatar(size=40) }}" width="40" height="40" style="position: absolute; left: 0; right: 0" />
						<div style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis">
							{{ user.name }}
							% if user.is_admin:
								<span title="administrator">&diams;</span>
							% end
						</div>
					</a>
					<div style="width: 50%; max-width: 3em; display: inline-block" class="text-muted">
						% n = sum(1 for o in user.occupancies if o.reviews)
						% if n:
							% m = '1 review' if n == 1 else '{} reviews'.format(n)
							<span class="glyphicon glyphicon-comment" title="{{m}} "></span>
							{{ n if n != 1 else '' }}
						% end
					</div><div style="width: 50%; max-width: 3em; display: inline-block" class="text-muted">
						% n = sum(len(o.photos) for o in user.occupancies)
						% if n:
							% m = '1 photo' if n == 1 else '{} photos'.format(n)
							<span class="glyphicon glyphicon-picture" title="{{m}} "></span>
							{{ n if n != 1 else '' }}
						% end
					</div>
				</div>
			</div>
		% end
	</div>
</div>

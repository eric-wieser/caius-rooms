% def extra_nav():
	<li class="active"><a href='/places'><span class="glyphicon glyphicon-map-marker"></span> Places</a></li>
	<li><a href='/rooms'><span class="glyphicon glyphicon-home"></span> Rooms</a></li>
% end

% rebase layout.tpl extra_nav=extra_nav, random="/people/random"

<div class="container">
	<div class="row">
		% for user in users:
			<div class="col-lg-2 col-md-3 col-sm-4 col-xs-6" style="margin-top: 5px; margin-bottom: 5px">
				<div style="padding-left: 50px; position: relative; min-height: 40px">
					<a href="mailto:{{ user.email }}">
						<img src="{{ user.gravatar(size=40) }}" width="40" height="40" style="position: absolute; left: 0; right: 0" />
						<div style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{{ user.name }}</div>
					</a>
					<div style="width: 2em; display: inline-block" class="text-muted">
						% n = sum(1 for o in user.occupancies if o.reviews)
						% if n:
							% m = '1 review' if n == 1 else '{} reviews'.format(n)
							<span class="glyphicon glyphicon-comment" title="{{m}} "></span>
							{{ n if n != 1 else '' }}
						% end
					</div>
					<div style="width: 2em; display: inline-block" class="text-muted">
						% n = sum(1 for o in user.occupancies if o.photos)
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

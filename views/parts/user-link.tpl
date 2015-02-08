<a href="{{ url_for(user) }}" style="display: block;width: 0; min-width: 100%; padding-left: 25px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap">
	<img src="{{ user.gravatar(size=20) }}" width="20" height="20" style="margin-left: -25px; float: left" />
	{{user.name}}
</a>

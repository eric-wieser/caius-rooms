<%
rebase('layout')

def layout_breadcrumb():
	for part in place.path:
		yield (url_for(part), part.pretty_name(part.parent))
	end
	yield ('#', 'Edit')
end
%>
<div class="container">
	<h1>Editing {{ place.pretty_name() }}</h1>
	<form action="{{ url_for(place) }}" method="POST">
		<textarea class="form-control"
		          name="content" rows="30" style="resize: vertical"
		>{{ place.summary.markdown_content if place.summary else '' }}</textarea>
		<div class="text-right">
			<a href="{{ url_for(place) }}" class="btn btn-default btn-lg">Cancel</a>
			<button type="submit" class="btn btn-success btn-lg">Submit</button>
		</div>
	</form>
</div>

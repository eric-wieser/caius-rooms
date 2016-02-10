<%
rebase('layout')
%>
<div class="container">
	<form action="{{ url_for(place) }}" method="POST">
		<textarea class="form-control"
		          name="content" rows="10" style="resize: vertical"
		>{{ place.summary.markdown_content if place.summary else '' }}</textarea>
		<div class="text-right">
			<a href="{{ url_for(place) }}" class="btn btn-default btn-lg">Cancel</a>
			<button type="submit" class="btn btn-success btn-lg">Submit</button>
		</div>
	</form>
</div>

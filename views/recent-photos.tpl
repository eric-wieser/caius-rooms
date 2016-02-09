<%
import database.orm as m

def layout_breadcrumb():
	yield ('/photos', 'Photos')
end

rebase('layout')
%>
<div class="container">
	<div class="row">
		<div class="col-xs-12">
			<h2>Recent photos</h2>
		</div>
		<%
		include('parts/photo-grid', cols=6, rows=12, photos=photos)
		%>

	</div>
</div>

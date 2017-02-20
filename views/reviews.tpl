<%
rebase('layout')
def layout_breadcrumb():
	yield ('#', u'Recent reviews')
end
n = 100
%>
<div class="container">
	<p class="lead">Showing the {{n}} most recently submitted or edited reviews.</p>
	<div class="row">
		<div class="col-md-6">
			% include('parts/review-list', reviews=reviews.limit(n))
		</div>
	</div>
</div>

% rebase('layout')
% from bottle import request
% import urllib

<div class="container">
	<div class="jumbotron">
		% if not request.user:
			% if reason == 'publicity':
				<h1>You'll need to login first</h1>
				<p>The college would prefer that this information is not visible to the general public. Member of the university?</p>
			% elif reason == 'privacy':
				<h1>You'll need to login first</h1>
				<p>For our privacy, some information is not visible to the public. Member of the university?</p>
			% elif reason == 'ownership':
				<h1>Sorry, who's posting this?</h1>
				<p>It looks like you've been logged out while trying to add some content.</p>
			% elif reason == 'personalized':
				<h1>Hello!</h1>
				<p>You're going to have to tell me who you are before I can take you to the right place</p>
			% elif reason == 'admin':
				<h1>You're not supposed to do that</h1>
				<p>The page you requested is for use by staff and GCSU members involved in the housing ballot. If you feel you should have access, ask efw27. Perhaps you're just no longer logged in?</p>
			% else:
				<h1>You'll need to login first</h1>
				<p>Something odd's happened, but logging in will probably fix it</p>
			% end

			% if not request.user:
				<a class="btn btn-lg btn-primary" href="/login?return_to={{ urllib.quote_plus(request.url) }}" id="login-prompted">Login with Raven</a>
				<script>
				$('#login-prompted').attr('href', function(_, old) {
					return old + location.hash;
				})
				</script>
			% end
		% else:
			% if reason == 'admin':
				<h1>You're not supposed to do that</h1>
				<p>The page you requested is for use by staff and GCSU members involved in the housing ballot. If you feel you should have access, ask efw27.</p>
			% else:
				<h1>You're not supposed to do that</h1>
				<p>Although it's pretty unclear which <em>"that"</em> is being referred to...</p>
			% end#
		% end
	</div>
</div>

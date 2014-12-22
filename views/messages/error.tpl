% from bottle import DEBUG, HTTP_CODES, request, touni

% rebase('layout', title="Error: {}".format(e.status))

<div class="container">
	<h1>Error: {{e.status}}</h1>
	<p>Sorry, the requested URL <tt>{{repr(request.url)}}</tt> caused an error:</p>
	<pre>{{e.body}}</pre>
	% if DEBUG and e.exception:
		<h2>Exception:</h2>
		<pre>{{repr(e.exception)}}</pre>
	% end
	% if DEBUG and e.traceback:
		<h2>Traceback:</h2>
		<pre>{{e.traceback}}</pre>
	% end
</div>

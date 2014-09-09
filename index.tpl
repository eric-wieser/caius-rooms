% def extra_nav():
	<li><a href='/places'><span class="glyphicon glyphicon-map-marker"></span> Places</a></li>
	<li><a href='/rooms'><span class="glyphicon glyphicon-home"></span> Rooms</a></li>
% end

% rebase layout.tpl extra_nav=extra_nav
<a class="hidden-xs" href="https://github.com/eric-wieser/caius-rooms">
	<img style="position: absolute; top: 0px; right: 0; border: 0; z-index: 10000;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_orange_ff7600.png" alt="Fork me on GitHub">
</a>
<div class="container">
	<div class="jumbotron">
		<h1>RoomPicks</h1>
		<p>For when you don't yet have the Caius</p>
	</div>
	<div class="row">
		<div class="col-md-4">
			<h2>Browse</h2>
		</div>
		<div class="col-md-4">
			<h2>Sort</h2>
		</div>
		<div class="col-md-4">
			<h2>Choose</h2>
		</div>
	</div>
</div>

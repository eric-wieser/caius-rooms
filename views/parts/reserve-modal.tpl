<div class="modal fade" id="reserve-modal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
	<div class="modal-dialog modal-lg">
		<div class="modal-content">
			<div class="modal-header">
				<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
				<h4 class="modal-title" id="myModalLabel">Confirm booking of <b>{{ room.pretty_name() }}</b></h4>
			</div>
			<div class="modal-body">
				<p>
					This window allows you to book your room through roomcaius, without having to leave roompicks.
				</p>
				<blockquote class="small">
					<p>
						On clicking the reserve button below, we will check that the room is still free and reserve it for you. If the room is still free you should receive a confirmation email. Please keep this as a receipt of your reservation. If you do not receive an email then your reservation may have been unsuccesful so please email jcrcomputing@cai.cam.ac.uk immediately.
					</p>
					<p>
						In clicking the reserve button, you are acknowledging the identity of the room, including the corresponding rental charge specified by the Bursary, and you are undertaking to complete the appropriate Licence Agreement when requested to do so by the Tutorial Office.
					</p>
					<footer><cite>Roomcaius</cite> booking page</footer>
				</blockquote>
				<p>
					The result of your booking attempt should appear below. If it does not seem to book the room, then it is suggested you report it to efw27, and then proceed to book through roomcaius directly.
				</p>
				<p>
					Note that there will be a short delay between booking your room, and your name appearing beside it here on roompicks
				</p>
				<div class="result"></div>
			</div>
			<div class="modal-footer">
				<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
				<form action="http://www.caiusjcr.org.uk/roomCaius/doReserve.php" method="POST" target="_blank" style="display: inline">
					<input type="hidden" name="roomID" value="{{ room.id }}">
					<input type="hidden" name="ballot" value="12">
					<button type="submit" class="btn btn-danger">Confirm room choice</button>
					<script>
					// use AJAX if we have javascript
					$(function() {
						$('#reserve-modal').submit(function() {
							var res = $(this).find('.result');
							$.ajax({
								type: "POST",
								url: "http://www.caiusjcr.org.uk/roomCaius/doReserve.php",
								data: {roomID: {{ room.id }}, ballot: 12},
								xhrFields: {
									withCredentials: true
								}
							}).then(function(html) {
								res.fadeOut().queue(function() {
									$(this).html(html);
									$(this).dequeue();
								}).fadeIn();
							});
							return false;
						});
					});
					</script>
				</form>
			</div>
		</div>
	</div>
</div>
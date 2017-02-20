% def booking_agreement():
	<p>
		On clicking the reserve button below, we will check that the room is still free and reserve it for you. You'll be sent back to the page for this room, and the alert at the top will inform you whether the booking was successful. If no such message appears, please email jcrcomputing@cai.cam.ac.uk immediately.
	</p>
	<p>
		In clicking the reserve button, you are acknowledging the identity of the room, including the corresponding rental charge specified by the Bursary, and you are undertaking to complete the appropriate Licence Agreement when requested to do so by the Tutorial Office.
	</p>
% end

% def booking_button(confirm):
	<form action="{{ url_for(room, extra_path="book") }}" method="POST" class="pull-right">
		<input type="hidden" name="crsf_token" value="{{ request.session.get('crsf_token', '') }}" />
		<button type="submit"
				class="btn btn-md btn-danger">
			% if confirm:
				Confirm reservation
			% else:
				Reserve this room
			% end
		</button>
	</form>
% end

% def booking_modal():
	<div class="modal fade" id="reserve-modal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
		<div class="modal-dialog">
			<div class="modal-content">
				<div class="modal-header">
					<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
					<h4 class="modal-title" id="myModalLabel">Confirm booking of <b>{{ room.pretty_name() }}</b></h4>
				</div>
				<div class="modal-body">
					% booking_agreement();
				</div>
				<div class="modal-footer">
					<button type="button" class="btn btn-default pull-left" data-dismiss="modal">Close</button>
					% booking_button(confirm=True)
				</div>
			</div>
		</div>
	</div>
% end
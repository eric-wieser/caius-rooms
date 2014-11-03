% rebase layout
% from sqlalchemy.orm.session import object_session
% import database.orm as m
% from datetime import datetime


<div class="container">
	<h1>
		Add photos
		<small>
			from your stay at {{ occupancy.listing.room.pretty_name() }} in {{ occupancy.listing.ballot_season}}
		</small>
	</h1>
	<form action="/photos" method="POST" enctype="multipart/form-data">
		<style>
		.photo-upload .photo-src{
			display: none;
		}

		.photo-upload.no-photo .photo-src{
			display: block;
		}
		.photo-upload.no-photo .photo-preview{
			display: none;
		}
		.photo-upload.no-photo .delete-photo{
			display: none;
		}

		</style>
		<input type="hidden" name="occupancy_id" value="{{ occupancy.id }}" />
		<div class="row photo-upload no-photo">
			<div class="col-md-4">
				<div class="form-group">
					<img class="img-responsive img-rounded photo-preview" />
					<input type="file" name="photo" class="photo-src" multiple/>
				</div>
			</div>
			<div class="col-md-6">
				<div class="form-group">
					<input class="form-control" type="text" name="caption" placeholder="caption" />
				</div>
			</div>
			<div class="col-md-2">
				<div class="form-group">
					<button class="btn btn-danger delete-photo">
						<span class="glyphicon glyphicon-remove"></span>
						Delete
					</button>
				</div>
			</div>
		</div>
		<div class="form-group">
			<button type="submit" class="btn btn-success">Submit</button>
		</div>
	</form>
	<script>
	function readURL(input) {
		$.each(input.files, function() {
			console.log(this);
			var reader = new FileReader();

			reader.onload = function (e) {
				var p = $(input).parents('.photo-upload');
				p.clone().insertAfter(p);

				p.find('.photo-preview').attr('src', e.target.result);
				p.removeClass('no-photo');
			}

			reader.readAsDataURL(this);
		});
	}

	$('form').on("change", ".photo-src", function(){
		readURL(this);
	}).find(each(function(){
		readURL(this);
	});

	$('delete-photo').click(function() {
		$(this).parents('.photo-upload').remove();
		return false;
	})
	</script>
	<h2>
		Existing photos
	</h2>
	<div class="row">
		% for photo in occupancy.photos:
			<div class="col-md-3 col-sm-4 col-xs-6">
				<img src="{{ photo.href }}" />
				<small>{{ photo.caption }}</small>
			</div>
		% end
	</div>
</div>
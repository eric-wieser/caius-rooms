% rebase('layout')
% from sqlalchemy.orm.session import object_session
% import database.orm as m
% from datetime import datetime
% from utils import format_ts_html

<div class="container">
	<h1>
		Add photos
		<small>
			from your stay at {{ occupancy.listing.room.pretty_name() }} in {{ occupancy.listing.ballot_season}}
		</small>
	</h1>
	<p>Images will be resized to fit within a 1280px &times; 600px rectangle. Try to upload images which are the right way up - you can't yet rotate them once they're uploaded! Landscape images are preferable.</p>
	<p>If you really want to go the extra mile, upload some <a href="/photos/panoramas" target="_blank">panoramas</a> - one good tool for generating these is <a href="http://research.microsoft.com/en-us/um/redmond/groups/ivm/ICE/">Microsoft ICE</a>.</p>
</div>
<div class="well" style="border-radius: 0; border-left: none; border-right: none">
	<div class="container">
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
			.photo-upload.no-photo .photo-caption{
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
						<input type="file" name="photo" class="photo-src" multiple accept="image/png,image/jpeg"/>
					</div>
				</div>
				<div class="col-md-6">
					<div class="form-group">
						<input class="form-control photo-caption" type="text" name="caption" title="Describing the image makes it searcheable" placeholder="caption" />
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
				<button type="submit" id="submit-button" class="btn btn-success">Submit</button>
			</div>
		</form>
	</div>
</div>
<div class="container">
	<script>
	// make a promise from a file reader
	function readFile(file) {
		var reader = new FileReader();
		var deferred = $.Deferred();

		reader.onload = function(event) {
			deferred.resolve(event.target.result);
		};

		reader.onerror = function() {
			deferred.reject(this);
		};
		reader.readAsDataURL(file);

		return deferred.promise();
	}

	// a promise where any completion counts as a success
	function alwaysOK(def) {
		var deferred = $.Deferred();
		def.then(function() { deferred.resolve(); });
		def.fail(function() { deferred.resolve(); });
		return deferred;
	}

	function readURL(input) {
		var p = $(input).parents('.photo-upload');
		var dfds = $.map(input.files, function(f) {
			readFile(f).then(function (data) {
				var p2 = p.clone();
				p2.find('.photo-src').val(null);
				p2.insertAfter(p);
				p.find('.photo-preview').attr('src', data);
				p.find('.photo-caption').prop('required', true)
				p.removeClass('no-photo');
			});
		});
		dfds = dfds.map(alwaysOK);
		return $.when.apply(null, dfds)
	}

	var button = $('#submit-button');

	$('form').on("change", ".photo-src", function(){
		button.prop('disabled', true)
		readURL(this).then(function() {
			button.prop('disabled', false);
		});
	}).find(".photo-src").each(function(){
		readURL(this);
	});

	$('form').on('click', '.delete-photo', function() {
		$(this).parents('.photo-upload').remove();
		return false;
	})
	</script>
	<h2>
		Previous photos added by you
	</h2>
	<div class="row">
		% for photo in occupancy.photos:
			<p style="display: inline-block; text-align: left; margin: 10px; overflow: hidden">
				<img src="{{photo.href}}" class="img-rounded img-responsive"
				     width="{{ photo.width }}" />
				{{ photo.caption }}
				<span class="text-muted pull-right">{{! format_ts_html(photo.published_at) }}</span>
			</p>
		% end
	</div>
</div>
% from utils import format_ts_html, restricted
% from bottle import request

% show_room = get('show_room') or False
<div itemprop="review" itemscope itemtype="http://schema.org/Review">
	<div style="position: relative; top: -50px" id="review-{{review.id}}"></div>
	<div class="row">
		% for photo in review.occupancy.photos:
			<div class="col-sm-2 col-xs-3">
				<p>
					<a href="http://gcsu.soc.srcf.net/roomCaius/photo.php?id={{ photo.id }}.jpg"
					   title="{{ photo.caption }}&#10;{{ photo.published_at }}"
					   target="_blank">
						<img src="http://gcsu.soc.srcf.net/roomCaius/photo.php?id={{ photo.id }}.jpg"
						     class="img-rounded img-responsive" />
					</a>
				</p>
			</div>
			% any_photos = True
		% end
	</div>
	<div class="row">
		<div class="col-md-2">
			<h2>{{ review.occupancy.listing.ballot_season.year }}
				% if review.rating is not None:
					<small itemprop="reviewRating" itemscope itemtype="http://schema.org/Rating">
						<span itemprop="ratingValue">{{ review.rating }}</span><!--
						-->/<span itemprop="bestRating">10</span>
					</small>
				% end
			</h2>
			% if show_room:
				<a href="/rooms/{{ review.occupancy.listing.room.id }}">
					{{ review.occupancy.listing.room.pretty_name() }}
				</a>
			% else:
				% if review.occupancy.resident:
					<p>
						% if request.user:
							<a itemprop="author" href="/users/{{ review.occupancy.resident.crsid }}">
								{{review.occupancy.resident.name}}
							</a>
						% else:
							{{! restricted() }}
						% end
						<br />
						<span class="text-muted">#{{ review.occupancy.ballot_slot.ranking }}</span>
					</p>
				% end
			% end
		</div>
		<div class="col-xs-1 visible-sm visible-xs"></div>
		% if review.sections:
			<div class="col-md-4 col-xs-11" style="padding-top: 7px">
				% for section in review.sections:
					% if section.heading.is_summary:
						<h3>
							% if "Best" in section.heading.name:
								<span class="text-success glyphicon glyphicon-thumbs-up pull-left" style="margin-left: -30px"></span>
							% elif "Worst" in section.heading.name:
								<span class="text-danger glyphicon glyphicon-thumbs-down pull-left" style="margin-left: -30px"></span>
							% else:
								<span class="glyphicon glyphicon-align-left pull-left" style="margin-left: -30px"></span>
							% end
							{{ section.heading.name }}
						</h3>
						{{! section.html_content(review.occupancy.listing.room) }}
					% end
				% end
			</div>
			<div class="col-xs-1 visible-xs"></div>
			<div class="col-md-6 col-sm-12 col-xs-11" style="margin-top: 33px">
				<dl class="dl-horizontal">
					% for section in review.sections:
						% if not section.heading.is_summary:
							<dt>{{ section.heading.name }}</dt>
							<dd>{{! section.html_content(review.occupancy.listing.room) }}</dd>
						% end
					% end
				</dl>
				<div class="text-right">
					<a href="#review-{{review.id}}"><small class="text-muted text-right">
						{{! format_ts_html(review.published_at) }}
					</small></a>
				</div>
			</div>
		% end
	</div>
</div>

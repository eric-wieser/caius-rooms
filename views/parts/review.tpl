% from utils import format_ts_html, restricted, format_ballot_html
% from bottle import request

% show_room = get('show_room') or False
% review = occupancy.review
% user_is_author = occupancy.resident == request.user != None
% user_is_admin = request.user and request.user.is_admin
<div itemprop="review" itemscope itemtype="http://schema.org/Review">
	<div style="position: relative; top: -50px" id="occupancy-{{occupancy.id}}"></div>

	% st = 'style="text-decoration: line-through"' if occupancy.cancelled else ''
	<div class="review-header">
		<div class="review-header-season" {{!st}}>
			{{! format_ballot_html(occupancy.listing.ballot_season) }}
		</div>
		<div class="review-header-thing" {{!st}}>
			% if show_room:
				<a href="{{ url_for(occupancy.listing.room) }}">
					{{ occupancy.listing.room.pretty_name() }}
				</a>
			% elif occupancy.resident:
				% if request.user:
					<a itemprop="author" href="{{ url_for(occupancy.resident) }}">
						{{occupancy.resident.name}}
					</a>
				% else:
					{{! restricted() }}
				% end
			% else:
				<span class="text-muted">Resident not recorded</span>
			% end
		</div>
		<div class="review-header-rank" {{!st}}>
			% if occupancy.resident:
				% sl = occupancy.ballot_slot
				% if sl:
					<a href="{{ url_for(occupancy.listing.ballot_season) }}#slot-{{ sl.id }}">
						#{{ sl.ranking }}</a>
					in the {{ sl.event.type.name.lower() }} ballot
				% else:
					not balloted for
				% end
			% end
		</div>
	</div>

	% if review:
		<div class="review-contents">
			<div class="review-rating-panel">
				% if review.rating is not None:
					<div itemprop="reviewRating" itemscope itemtype="http://schema.org/Rating">
						<span itemprop="ratingValue">{{ repr(review.rating) }}</span><!--
						--><span class="rating-max">/<span itemprop="bestRating">10</span></span>
					</div>
				% else:
					<span class="text-muted">No rating</span>
				% end
				% # we pull this button up in small windows
				<span class="review-edit-md-lg">
					% if (user_is_author or user_is_admin) and review.sections:
						<a class="btn btn-success btn-lg" href="/reviews/new/{{ occupancy.id }}">
							<span class="glyphicon glyphicon-pencil"></span> Edit
						</a>
					% end
				</span>
			</div>
			% if not review.sections:
				% if user_is_author:
					<div class="review-add-panel">
						<a class="btn btn-success btn-lg" href="/reviews/new/{{ occupancy.id }}">
							<span class="glyphicon glyphicon-pencil"></span> Add review
						</a>
					</div>
				% end
			% else:
				% if (user_is_author or user_is_admin):
					<div class="review-edit-xs-sm">
						<a class="btn btn-success btn-lg" href="/reviews/new/{{ occupancy.id }}">
							<span class="glyphicon glyphicon-pencil"></span> Edit
						</a>
					</div>
				% end
				<div class="review-summary-panel">
					% for section in review.sections:
						% if section.heading.is_summary:
							<h3>
								% if "Best" in section.heading.name:
									<span class="text-success glyphicon glyphicon-thumbs-up"></span>
								% elif "Worst" in section.heading.name:
									<span class="text-danger glyphicon glyphicon-thumbs-down"></span>
								% else:
									<span class="glyphicon glyphicon-align-left"></span>
								% end
								{{ section.heading.name }}
							</h3>
							{{! section.html_content(occupancy.listing.room) }}
						% end
					% end
				</div>
				<div class="review-detail-panel">
					<dl class="dl-horizontal">
						% for section in review.sections:
							% if not section.heading.is_summary:
								<dt>{{ section.heading.name }}</dt>
								<dd>{{! section.html_content(occupancy.listing.room) }}</dd>
							% end
						% end
					</dl>
				</div>
			% end
			<div class="review-meta-panel">
				% if len(occupancy.reviews) > 1:
					<a href="/occupancies/{{ occupancy.id }}">
						% revs = len(occupancy.reviews)
						Edited
						% if revs > 2:
							{{ revs - 1}} times
						% end
					</a>
					&bullet;
				% end
				<a href="#occupancy-{{occupancy.id}}">
					{{! format_ts_html(review.published_at) }}
				</a>
			</div>
		</div>
	% elif user_is_author:
		<form action="/reviews/new/{{ occupancy.id }}" method="post">
			<div class="row">
				<div class="col-md-2 col-xs-4">
					<div style="font-size: 63px" itemprop="reviewRating" itemscope itemtype="http://schema.org/Rating">
						<input name="rating" itemprop="ratingValue"
						       type="number" min="0" max="10"
						       style="display: inline-block; font-size: inherit; width: 80px; height: 90px; margin: 0; padding: 0; border: 0; background: transparent"
						       placeholder="?"
						       value="{{ review and review.rating or '' }}"/><!--
						--><span style="font-size: 65%" class="text-muted">/<span itemprop="bestRating">10</span></span>
					</div>
				</div>
				<div class="col-md-2 col-xs-4" style="padding-top: 22px">
					<button type="submit" class="btn btn-success btn-lg">
						Rate &amp; Review
						<span class="glyphicon glyphicon-chevron-right"></span>
					</button>
				</div>
			</div>
		</form>
	% end
</div>

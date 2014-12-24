% from utils import format_ts_html, restricted, format_ballot_html
% from bottle import request

% show_room = get('show_room') or False
% review = occupancy.review
% user_is_author = occupancy.resident == request.user != None
<div itemprop="review" itemscope itemtype="http://schema.org/Review">
	<div style="position: relative; top: -50px" id="occupancy-{{occupancy.id}}"></div>

	<div class="row">
		<div class="col-md-2 col-xs-2">
			<strong>{{! format_ballot_html(occupancy.listing.ballot_season) }}</strong>
		</div>
		<div class="col-md-6 col-xs-4">
			% if show_room:
				<a href="/rooms/{{ occupancy.listing.room.id }}">
					{{ occupancy.listing.room.pretty_name() }}
				</a>
			% else:
				% if occupancy.resident:
					% if request.user:
						<a itemprop="author" href="/users/{{ occupancy.resident.crsid }}">
							{{occupancy.resident.name}}
						</a>
					% else:
						{{! restricted() }}
					% end
				% else:
					<span class="text-muted">Resident not recorded</span>
				% end
			% end
		</div>
		<div class="col-md-4 col-xs-6 text-right">
			% if occupancy.resident:
				% sl = occupancy.ballot_slot
				% if sl:
					<a href="/ballots/{{ occupancy.listing.ballot_season.year }}#slot-{{ sl.id }}">
						#{{ sl.ranking }}</a>
					in the {{ sl.event.type.name.lower() }} ballot
				% else:
					not balloted for
				% end
			% end
		</div>
	</div>

	% if review:
		<div class="row">
			<div class="col-md-2 col-md-offset-0 col-xs-5 col-xs-offset-1">
				% if review.rating is not None:
					<div style="font-size: 63px" itemprop="reviewRating" itemscope itemtype="http://schema.org/Rating">
						<span itemprop="ratingValue">{{ repr(review.rating) }}</span><!--
						--><span class="text-muted" style="font-size: 65%">/<span itemprop="bestRating">10</span></span>
					</div>
				% else:
					<span class="text-muted">No rating</span>
				% end
				% # we pull this button up in small windows
				<span class="hidden-xs hidden-sm">
					% if user_is_author and review.sections:
						<a class="btn btn-success btn-lg" href="/reviews/new/{{ occupancy.id }}">
							<span class="glyphicon glyphicon-pencil"></span> Edit
						</a>
					% end
				</span>
			</div>
			% if not review.sections:
				<div class="col-xs-6 col-md-10">
					% if user_is_author:
						% # left align on large screens, right align on small
						<div class="hidden-xs hidden-sm">
							<div style="height: 22px"></div>
							<a class="btn btn-success btn-lg" href="/reviews/new/{{ occupancy.id }}">
								<span class="glyphicon glyphicon-pencil"></span> Add review
							</a>
						</div>
						<div class="hidden-md hidden-lg text-right">
							<div style="height: 22px"></div>
							<a class="btn btn-success btn-lg" href="/reviews/new/{{ occupancy.id }}">
								<span class="glyphicon glyphicon-pencil"></span> Add review
							</a>
						</div>
					% end
				</div>
			% else:
				<div class="col-xs-6 hidden-lg hidden-md text-right">
					% if user_is_author:
						<div style="height: 22px"></div>
						<a class="btn btn-success btn-lg" href="/reviews/new/{{ occupancy.id }}">
							<span class="glyphicon glyphicon-pencil"></span> Edit
						</a>
					% end
				</div>
				<div class="clearfix hidden-lg hidden-md"></div>
				<div class="col-md-4 col-md-offset-0 col-xs-11 col-xs-offset-1">
					<div style="height: 26px" class="hidden-sm hidden-xs"></div>
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
							{{! section.html_content(occupancy.listing.room) }}
						% end
					% end
				</div>
				<div class="col-md-6 col-sm-12 col-sm-offset-0 col-xs-11 col-xs-offset-1">
					<div style="height: 52px" class="hidden-sm hidden-xs"></div>
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
			<div class="col-xs-12 text-right">
				<small>
					% if len(occupancy.reviews) > 1:
						<a href="/occupancies/{{ occupancy.id }}">
							% revs = len(occupancy.reviews)
							<span class="text-muted">
								Edited
								% if revs > 2:
									{{ revs - 1}} times
								% end
							</span>
						</a>
						&bullet;
					% end
					<a href="#occupancy-{{occupancy.id}}">
						<span class="text-muted">{{! format_ts_html(review.published_at) }}</span>
					</a>
				</small>
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

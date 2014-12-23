% from utils import format_ts_html, restricted, format_ballot_html
% from bottle import request

% show_room = get('show_room') or False
% review = occupancy.review
<div itemprop="review" itemscope itemtype="http://schema.org/Review">
	<div style="position: relative; top: -50px" id="occupancy-{{occupancy.id}}"></div>

	<div class="row">
		<div class="col-xs-4">
			<h2>{{! format_ballot_html(occupancy.listing.ballot_season) }}</h2>
		</div>
		<div class="col-xs-4 text-center">
			<h2><small>
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
				% end
			% end
			</small></h2>
		</div>
		<div class="col-xs-4 text-right">
			<h2><small>
				% if occupancy.resident:
					% if occupancy.ballot_slot:
						#{{ occupancy.ballot_slot.ranking }} in the ballot
					% else:
						off-ballot
					% end
				% end
			</small></h2>
		</div>
	</div>

	% if review:
		<div class="row">
			<div class="col-md-2">
				% if review.rating is not None:
					<div style="font-size: 200%" itemprop="reviewRating" itemscope itemtype="http://schema.org/Rating">
						<span itemprop="ratingValue" style="font-size: 200%">{{ repr(review.rating) }}</span><!--
						--><span class="text-muted">/<span itemprop="bestRating">10</span></span>
					</div>
				% else:
					<span class="text-muted">No rating</span>
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
							{{! section.html_content(occupancy.listing.room) }}
						% end
					% end
				</div>
				<div class="col-xs-1 visible-xs"></div>
				<div class="col-md-6 col-sm-12 col-xs-11" style="margin-top: 33px">
					<dl class="dl-horizontal">
						% for section in review.sections:
							% if not section.heading.is_summary:
								<dt>{{ section.heading.name }}</dt>
								<dd>{{! section.html_content(occupancy.listing.room) }}</dd>
							% end
						% end
					</dl>
					<div class="text-right">
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
			% end
		</div>
	% end
</div>

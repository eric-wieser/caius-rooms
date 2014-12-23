% rebase('layout')
% from sqlalchemy.orm.session import object_session
% import database.orm as m
% from datetime import datetime

% from utils import format_ballot_html

% def last_content_for(heading):
	% if review:
		% for s in review.sections:
			% if s.heading == heading:
				% return s.content
			% end
		% end
	% end
	% return ''
% end

<div class="container">
	<form action="/reviews" method="POST">
		<input type="hidden" name="occupancy_id" value="{{ occupancy.id }}" />
		<div itemprop="review" itemscope itemtype="http://schema.org/Review">
			<div class="row">
				<div class="col-xs-2">
					<strong>{{! format_ballot_html(occupancy.listing.ballot_season) }}</strong>
				</div>
				<div class="col-xs-6">
					<a itemprop="author" href="/users/{{ occupancy.resident.crsid }}">
						{{ occupancy.resident.name }}
					</a>
				</div>
				<div class="col-xs-4 text-right">
					% sl = occupancy.ballot_slot
					% if sl:
						<a href="/ballots/{{ occupancy.listing.ballot_season.year }}#slot-{{ sl.id }}">
							#{{ sl.ranking }}</a>
						in the {{ sl.event.type.name.lower() }} ballot
					% else:
						not balloted for
					% end
				</div>
			</div>
			<div class="row">
				<div class="col-md-2">
					<div style="font-size: 63px" itemprop="reviewRating" itemscope itemtype="http://schema.org/Rating">
						<input name="rating" itemprop="ratingValue"
						       type="number" min="0" max="10"
						       style="display: inline-block; font-size: inherit; width: 80px; height: 90px; margin: 0; padding: 0; border: 0"
						       placeholder="?"
						       value="{{ review and review.rating or '' }}"/><!--
						--><span style="font-size: 65%" class="text-muted">/<span itemprop="bestRating">10</span></span>
					</div>
				</div>
				<div class="col-xs-1 visible-sm visible-xs"></div>
				% headings = object_session(occupancy).query(m.ReviewHeading).order_by(m.ReviewHeading.position)
				<div class="col-md-4 col-xs-11" style="padding-top: 26px">
					% for heading in headings:
						% if heading.is_summary:
							<h3>
								% if "Best" in heading.name:
									<span class="text-success glyphicon glyphicon-thumbs-up pull-left" style="margin-left: -30px"></span>
								% elif "Worst" in heading.name:
									<span class="text-danger glyphicon glyphicon-thumbs-down pull-left" style="margin-left: -30px"></span>
								% else:
									<span class="glyphicon glyphicon-align-left pull-left" style="margin-left: -30px"></span>
								% end
								{{ heading.name }}
							</h3>
							<textarea class="form-control"
							          required
							          name="section-{{heading.id}}" rows="4" style="resize: vertical"
							          placeholder="{{heading.prompt or ''}}">{{ last_content_for(heading) }}</textarea>
						% end
					% end
				</div>
				<div class="col-xs-1 visible-xs"></div>
				<div class="col-md-6 col-sm-12 col-xs-11" style="margin-top: 52px">
					<dl class="dl-horizontal">
						% for heading in headings:
							% if not heading.is_summary:
								<dt>{{ heading.name }}</dt>
								<dd>
									<textarea name="section-{{heading.id}}"
									          class="form-control"
									          rows="3"
									          style="resize: vertical; margin-bottom: 5px"
									          placeholder="{{heading.prompt or ''}}">{{ last_content_for(heading) }}</textarea></dd>
							% end
						% end
					</dl>
				</div>
			</div>
		</div>
		<button type="submit" class="btn btn-success btn-lg pull-right">Submit</button>
	</form>
</div>
% rebase('layout')
% from sqlalchemy.orm.session import object_session
% import database.orm as m
% from datetime import datetime

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
				<div class="col-md-2">
					<h2>{{occupancy.listing.ballot_season.year}}
						<small itemprop="reviewRating" itemscope itemtype="http://schema.org/Rating" style="white-space: nowrap">
							<input name="rating" itemprop="ratingValue" type="number" min="0" max="10" style="width: 4em; display: inline-block"  class="form-control" value="{{ review and review.rating or '' }}"/><!--
							-->/<span itemprop="bestRating">10</span>
						</small>
					</h2>
					<a itemprop="author" href="mailto:{{occupancy.resident.email}}">
						{{occupancy.resident.name}}
					</a>
				</div>
				<div class="col-xs-1 visible-sm visible-xs"></div>
				% headings = object_session(occupancy).query(m.ReviewHeading).order_by(m.ReviewHeading.position)
				<div class="col-md-4 col-xs-11" style="padding-top: 7px">
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
				<div class="col-md-6 col-sm-12 col-xs-11" style="margin-top: 33px">
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
					<div class="text-right">
						<a href="#"><small class="text-muted text-right">{{ datetime.now() }}</small></a>
					</div>
				</div>
			</div>
		</div>
		<button type="submit" class="btn btn-success">Submit</button>
	</form>
</div>
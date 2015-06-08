<%
rebase('layout')
from sqlalchemy.orm.session import object_session
import database.orm as m
from datetime import datetime
from bottle import request

from utils import format_ballot_html

def last_content_for(heading):
	if review:
		for s in review.sections:
			if s.heading == heading:
				return s.content
			end
		end
	end
	return ''
end
%>
<div class="container">
	% if request.user != occupancy.resident:
		<div class="alert alert-info"><strong>With great power comes great responsibility.</strong> Don't forget this is someone else's review you're editing, and other people will be able to see what you've changed. Use this only to correct room links and typos, and remove offensive or privacy-violating content.</div>
	% end
	% if review.occupancy != occupancy.review:
		<div class="alert alert-warning"><strong>Warning!</strong> You're editing an old revision. If you save it, you will effectively roll back to this old version of the post.</div>
	% end
	<form action="/reviews" method="POST">
		<input type="hidden" name="occupancy_id" value="{{ occupancy.id }}" />
		<div itemprop="review" itemscope itemtype="http://schema.org/Review">
			<div class="row">
				<div class="col-xs-2">
					<strong>{{! format_ballot_html(occupancy.listing.ballot_season) }}</strong>
				</div>
				<div class="col-xs-6">
					% if occupancy.resident:
						<a itemprop="author" href="{{ url_for(occupancy.resident) }}">
							{{ occupancy.resident.name }}
						</a>
					% END
				</div>
				<div class="col-xs-4 text-right">
					% sl = occupancy.ballot_slot
					% if sl:
						<a href="{{ url_for(occupancy.listing.ballot_season) }}#slot-{{ sl.id }}">
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
							          name="section-{{heading.id}}" rows="5" style="resize: vertical"
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
									          rows="4"
									          style="resize: vertical; margin-bottom: 5px"
									          placeholder="{{heading.prompt or ''}}">{{ last_content_for(heading) }}</textarea></dd>
							% end
						% end
					</dl>
				</div>
			</div>
		</div>
		<button type="submit" name="delete" class="pull-left btn btn-danger btn-lg">Delete review</button>

		<div class="text-right">
			<a href="{{ url_for(occupancy.listing.room) }}#occupancy-{{ occupancy.id }}" class="btn btn-default btn-lg">Cancel</a>
			<button type="submit" class="btn btn-success btn-lg">Submit</button>
		</div>
	</form>
</div>
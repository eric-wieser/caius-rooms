<%
from bottle import request
from utils import format_ts_html, restricted
from diff_match_patch import diff_match_patch as DMP
rebase('layout')
def layout_breadcrumb():
	yield (url_for(occupancy.listing.room), occupancy.listing.room.pretty_name())
	yield (
		url_for(occupancy.listing.room) + '#occupancy-{}'.format(occupancy.id),
		unicode(occupancy.listing.ballot_season) + ' review'
	)
	yield ('#', 'Revisions')
end

revisions = sorted(occupancy.reviews, key=lambda r: r.published_at)

differ = DMP()

user_can_edit = request.user and (request.user.is_admin or request.user == occupancy.resident)

def make_diff(prev, curr):
	# Get a list of all the sections, and their values before and after
	prev_sections = {s.heading: s.content for s in prev.sections}
	curr_sections = {s.heading: s.content for s in curr.sections}
	section_headings = sorted(set(prev_sections.keys()) | set(curr_sections.keys()), key=lambda s: s.position)
	sections = [(key, prev_sections.get(key, ''), curr_sections.get(key, '')) for key in section_headings]
	%>

	% if prev.rating != curr.rating:
		<div class="row" style="font-size: 200%">
			<div class="col-md-6">
				% if prev.rating:
					<p><span class="text-danger">{{ prev.rating }}</span>/10</p>
				% end
			</div>
			<div class="col-md-6">
				% if curr.rating:
					<p><span class="text-success">{{ curr.rating }}</span>/10</p>
				% end
			</div>
		</div>
	% end

	% for sh, prev_s, curr_s in sections:
		% if prev_s == curr_s:
			% continue
		% end
		% diffs = differ.diff_main(prev_s, curr_s)
		% differ.diff_cleanupSemantic(diffs)
		<div class="row">
			<div class="col-md-6">
				% if prev_s:
					% if curr_s:
						<h4>{{ sh.name }}</h4>
						<p><!--
							% for s, text in diffs:
								% if s == 0:
									-->{{ text }}<!--
								% elif s == -1:
									--><span class="alert-danger">{{text}}</span><!--
								% end
							% end
						--></p>
					% else:
						<div class="alert-danger">
							<h4>{{ sh.name }}</h4>
							<p>{{ prev_s }}</p>
						</div>
					% end
				% end
			</div>
			<div class="col-md-6">
				% if curr_s:
					% if prev_s:
						<h4>{{ sh.name }}</h4>
						<p><!--
							% for s, text in diffs:
								% if s == 0:
									-->{{ text }}<!--
								% elif s == 1:
									--><span class="alert-success">{{text}}</span><!--
								% end
							% end
						--></p>
					% else:
						<div class="alert-success">
							<h4>{{ sh.name }}</h4>
							<p>{{ curr_s }}</p>
						</div>
					% end
				% end
			</div>
		</div>
	% end
% end

<div class="container">
	% last = None
	% for i, review in reversed(list(enumerate(revisions, 1))):

		% if last and not last.hidden:
			</div>
			<div class="well" style="border-radius: 0; border-left: none; border-right: none">
				<div class="container">
					<div class="row">
						<div class="col-md-2 text-right">
							before
						</div>
						<div class="col-md-8">
							% make_diff(review, last)
						</div>
						<div class="col-md-2">
							after
						</div>
					</div>
				</div>
			</div>
			<div class="container">
		% elif last:
			<hr />
		% end


		<div>
			<div class="clearfix" style="margin-bottom: 10px">
				% if last and user_can_edit:
					<div class="pull-right">
						<a class="btn btn-default btn-small" href="/reviews/new/{{occupancy.id}}?revision={{review.id}}">restore old version</a>
					</div>
				% end
				<h2 style="margin-top: 0; margin-bottom: 0;">Revision {{i}} <small>{{! format_ts_html(review.published_at) }}</small></h2>
				% author = review.editor or occupancy.resident
				% if author:
					% if request.user:
						% include('parts/user-link', user=author, inline=True)
					% else:
						{{! restricted() }}
					% end
				% end
			</div>
			% if review.hidden:
				<div class="alert alert-danger text-center">Review deleted</div>
			% else:
				<div class="review-contents">
					<div class="review-rating-panel">
						% if review.rating:
							<div>
								{{ repr(review.rating) }}</span><!--
								--><span class="rating-max">/10</span>
							</div>
						% end
					</div>
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
				</div>
			% end
		</div>

		% last = review
	% end
</div>

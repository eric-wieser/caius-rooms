<%
from bottle import request
from utils import format_ts_html, restricted
from diff_match_patch import diff_match_patch as DMP
rebase('layout')
def layout_breadcrumb():
	yield ('#', 'Content history for {}'.format(occupancy.listing.room.pretty_name()))
end

revisions = sorted(occupancy.reviews, key=lambda r: r.published_at)

differ = DMP()

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
	<h1>Revision history
	<small>Of the {{ occupancy.listing.ballot_season }} review for
		<a href="/rooms/{{ occupancy.listing.room.id }}">
			{{ occupancy.listing.room.pretty_name() }}</a>
	</small></h1>
	% if occupancy.resident:
		<p>
			Authored by
			% if request.user:
				<a href="/users/{{ occupancy.resident.crsid }}">
					{{occupancy.resident.name}}
				</a>
			% else:
				{{! restricted() }}
			% end
		</p>
	% end

	% last = None
	% for i, review in reversed(list(enumerate(revisions, 1))):

		% if last:
			</div>
			<div class="well" style="border-radius: 0; border-left: none; border-right: none">
				<div class="container">
					<div class="row">
						<div class="col-md-2">
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
		% end


		<div>
			<h2>Revision {{i}} <small>{{! format_ts_html(review.published_at) }}</small></h2>
			<div class="review-contents">
				<div class="review-rating-panel">
					<div>
						{{ repr(review.rating) }}</span><!--
						--><span class="rating-max">/10</span>
					</div>
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
		</div>

		% last = review
	% end
</div>

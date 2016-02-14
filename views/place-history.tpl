<%
from bottle import request
from utils import format_ts_html, restricted
from diff_match_patch import diff_match_patch as DMP
rebase('layout')
def layout_breadcrumb():
	for part in place.path:
		yield (url_for(part), part.pretty_name(part.parent))
	end
	yield ('#', 'Revisions')
end

revisions = sorted(place.summaries, key=lambda r: r.published_at)

differ = DMP()

user_can_edit = request.user and request.user.is_admin

def make_diff_pane(prev, curr):
	%>


	% diffs = differ.diff_main(prev.markdown_content, curr.markdown_content)
	% differ.diff_cleanupSemantic(diffs)
	<div class="row">
		<div class="col-sm-6">
			<p><!--
				% for s, text in diffs:
					% if s == 0:
						-->{{ text }}<!--
					% elif s == -1:
						--><del class="alert-danger">{{text}}</del><!--
					% end
				% end
			--></p>
		</div>
		<div class="col-sm-6">
			<p><!--
				% for s, text in diffs:
					% if s == 0:
						-->{{ text }}<!--
					% elif s == 1:
						--><span class="alert-success">{{text}}</span><!--
					% end
				% end
			--></p>
		</div>
	</div>
% end

% def make_full_view(summary):
	% if summary.hidden:
		<div class="alert alert-danger text-center">Review deleted</div>
	% else:
		% include('parts/markdown', content=summary.markdown_content, columnize=True)
	% end
% end

<div class="container">
	% revision_slices = zip([None] + revisions, revisions, revisions[1:] + [None])
	% for i, (last_r, summary, next_r) in reversed(list(enumerate(revision_slices, 1))):
		<div class="row" style="margin-bottom: 10px">
			<div class="col-md-4">
				<h2 style="margin-top: 0; margin-bottom: 0;">Revision {{i}} <small>{{! format_ts_html(summary.published_at) }}</small></h2>
				% author = summary.editor or occupancy.resident
				% if author:
					% if request.user:
						% include('parts/user-link', user=author, inline=True)
					% else:
						{{! restricted() }}
					% end
				% end
			</div>
			<div class="col-md-4 text-center">
				% if last_r:
					<div class="btn-group btn-group-sm" data-toggle="buttons">
						<label class="btn btn-default active" href="#diff-{{summary.id}}" aria-controls="home" role="tab" data-toggle="tab">
							<span class="glyphicon glyphicon-transfer"></span>
							Changes
							<input type="radio" checked="checked" name="view-{{summary.id}}" autocomplete="off"/>
						</label>
						<label class="btn btn-default" href="#full-{{summary.id}}" aria-controls="profile" role="tab" data-toggle="tab">
							<span class="glyphicon glyphicon-align-left"></span>
							Full text
							<input type="radio" name="view-{{summary.id}}" autocomplete="off"/>
						</label>
					</div>
				% end
			</div>
			% if user_can_edit:
				<div class="col-md-4 text-right">
					<a class="btn btn-primary btn-sm" href="{{ url_for(place, extra_path='edit', qs=dict(revision=summary.id)) }}">
						% if next_r:
							Restore this version
						% else:
							Edit
						% end
					</a>
				</div>
			% end
		</div>

		% if last_r:
			<div class="tab-content">
				<div role="tabpanel" class="tab-pane active" id="diff-{{summary.id}}">
					% make_diff_pane(last_r, summary)
				</div>
				<div role="tabpanel" class="tab-pane" id="full-{{summary.id}}">
					% make_full_view(summary)
				</div>
			</div>
			<hr />
		% else:
			% make_full_view(summary)
		% end
	% end
</div>

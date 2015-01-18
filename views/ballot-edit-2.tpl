<%
import database.orm as m

rebase('layout')

import re
def natural_sort_key(s, _nsre=re.compile('([0-9]+)')):
   return [int(text) if text.isdigit() else text.lower() for text in re.split(_nsre, s)]
end
%>
<style>
.group {
}
.item, .group-item {
	overflow: hidden;
}

.group-item {
	margin-top: 5px;
	padding: 4px;
	background-color: rgb(245, 245, 245);
	border: 1px solid rgb(221, 221, 221);
	border-radius: 3px;
}
.group-item .audience-cbs{
	margin: -5px;
	padding: 5px 0px;
	height: 30px;
}
.group-children {
	margin-left: 10px;
	padding-left: 10px;
	border-left: 1px solid rgb(221, 221, 221);
	margin-bottom: 20px;
	margin-top: -1px;
	padding-top: 1px;
}


.group-children > * {
	position: relative;
}

.group-children > :last-child::before {
	content: "";
	position: absolute;
	top: 15px;
	left: -11px;
	bottom: 0;
	width: 10px;
	border-left: 1px solid white;
}
.audience-cbs {
	float: right;
	border-left: 1px solid rgb(231, 231, 231);
	height: 20px;
}
.audience-cbs .audience-cb {
	width: 40px;
	height: 100%;
	text-align: center;
	float: left;
}

input[type=checkbox].show-hide {
	display: none;
}

.show-hide:checked ~ .group-children {
	display: none;
}

.show-hide-buttons {
	display: inline;
}

.group-item label .show-hide-shown { display: inline; }
.group-item label .show-hide-hidden { display: none; }
.show-hide:checked ~ .group-item label .show-hide-shown { display: none; }
.show-hide:checked ~ .group-item label .show-hide-hidden { display: inline; }


</style>
<%

class fullset(set):
	""" Models the universe set containing everything"""
	def __and__(self, other):
		return other
	end
end

def all_listings(event, cl=root):
	if not event:
		return
	end

	for room in cl.rooms:
		listing = room.listing_for.get(event.season)
		if listing and event.type in listing.audience_types:
			yield listing
		end
	end
	for subcl in cl.children:
		for listing in all_listings(event, subcl):
			yield listing
		end
	end
end

listed_now = {listing.room for listing in all_listings(ballot_event)}
listed_then = {listing.room for listing in all_listings(last_ballot_event)}

def make_cluster_pred(pred, cl=root):
	if any(r in pred for r in cl.rooms):
		yield cl
	end

	for subcl in cl.children:
		for c in make_cluster_pred(pred, subcl):
			yield c
			yield cl
		end
	end
end


# build up a dictionary of Cluster => (audiences that can see every room,
#	                                   audiences that can see some rooms)
audiences = {}
def process(cl):
	some_a = set()
	all_a = fullset()
	for room in cl.rooms:
		listing = room.listing_for.get(ballot_event.season)
		audiences[room] = set(listing.audience_types) if listing else set()

		all_a = all_a & set(audiences[room])
		some_a = some_a | set(audiences[room])
	end
	for subcl in cl.children:
		process(subcl)
		all_as, some_as = audiences[subcl]
		all_a = all_a & all_as
		some_a = some_a | some_as
	end
	audiences[cl] = all_a, some_a
end
process(root)
%>

% def display(cl, pred):
	% cl_pred = set(make_cluster_pred(pred, cl))
	% for room in sorted(cl.rooms, key=lambda r: natural_sort_key(r.name)):
		% if room not in pred:
			% continue
		% end
		<div class="item">
			<a href="/rooms/{{ room.id }}" target="_blank">{{ room.pretty_name(cl) }}</a>
			<div class="audience-cbs">
				<div class="audience-cb">
					<input type="checkbox"
					       title="{{ ballot_event.type.name }}"
					       data-type="{{ ballot_event.type.name }}"
					       name="rooms[{{ room.id }}]"
					       {{ 'checked' if ballot_event.type in audiences[room] else '' }} />
				</div>
			</div>
		</div>
	% end
	% for subcl in cl.children:
		% if subcl not in cl_pred:
			% continue
		% end
		<div class="group">
			% indeterminate = audiences[subcl][0] != audiences[subcl][1]
			<input class="show-hide" type="checkbox" id="toggle-{{subcl.id}}-{{ id(pred) }}"
			       {{ '' if indeterminate else 'checked'}} />
			<div class="group-item">
				<label class="show-hide-buttons" for="toggle-{{subcl.id}}-{{ id(pred) }}">
					<span class="show-hide-shown glyphicon glyphicon-chevron-down"></span>
					<span class="show-hide-hidden glyphicon glyphicon-chevron-right"></span>
				</label>
				<a href="/places/{{ cl.id }}" target="_blank"><b>{{ subcl.pretty_name(cl) }}</b></a>
				<div class="audience-cbs">
					<%
					if ballot_event.type in audiences[subcl][0]:
						state = 'checked'
					elif ballot_event.type in audiences[subcl][1]:
						state = 'indeterminate'
					else:
						state = ''
					end
					%>
					<div class="audience-cb">
						<input type="checkbox" data-cl="{{ cl.id }}" {{ state }} />
					</div>
				</div>
			</div>
			<div class="group-children">
				% display(subcl, pred)
			</div>
		</div>
	% end
% end
<div class="container">
	<h1>Ballot for {{ ballot_event.season }}</h1>
	<p>Select which rooms should be available in which sub-ballots using the checkboxes on the right</p>
	<div class="row">
		<div class="col-md-4">
			<h2>Removed since last ballot</h2>
			% display(root, listed_then - listed_now)
		</div>
		<div class="col-md-4">
			<h2>Present in last ballot</h2>
			% display(root, listed_then & listed_now)
		</div>
		<div class="col-md-4">
			<h2>Added in current ballot</h2>
			% display(root, listed_now - listed_then)
		</div>
	</div>
</div>
<script>
$(function() {
	// deal with indeterminate
	$('input[indeterminate]').prop('indeterminate', true);

	var get_cb_for_item = function($item, type) {
		return $item.find('.audience-cb input').filter(function() {
			return $(this).data('type') == type;
		});
	}

	var get_child_items = function($item) {
		if($item.is('.group-item')) {
			return $item.siblings('.group-children').children().map(function() {
				if($(this).is('.group'))
					return $(this).children('.group-item')[0]
				else
					return this;
			})
		}
		return $();
	}

	var get_parent_item = function($item) {
		return $item.closest('.group-children').parent().children('.group-item');
	}

	$('.audience-cb input').click(function() {
		var $cb = $(this)
		var type = $cb.data('type');
		var checked = $cb.prop('checked')
		var $item = $cb.closest('.audience-cbs').parent();

		get_child_items($item).each(function check_desc() {
			get_cb_for_item($(this), type).prop({
				'checked': checked,
				'indeterminate': false
			})

			get_child_items($(this)).each(check_desc);
		});

		function go_up($p) {
			if($p.size() == 0) return;

			var all_checked = true;
			var none_checked = true;
			get_child_items($p).each(function () {
				var $cb = get_cb_for_item($(this), type);
				if($cb.prop('indeterminate')) {
					none_checked = false;
					all_checked = false;
				} else if ($cb.prop('checked')) {
					none_checked = false;
				} else {
					all_checked = false;
				}
			});

			var $cb = get_cb_for_item($p, type);
			$cb.prop('indeterminate', false);
			if(all_checked)
				$cb.prop('checked', true);
			else if(none_checked)
				$cb.prop('checked', false);
			else
				$cb.prop('indeterminate', true);

			go_up(get_parent_item($p));
		}

		go_up(get_parent_item($item));
	});
});
</script>

<%
from collections import namedtuple

import database.orm as m
import json

rebase('layout')

def layout_breadcrumb():
	yield ('#', '{} - {} season'.format(ballot_event.season.year, ballot_event.season.year + 1))
	yield ('#', ballot_event.type.name)
end

import re
def natural_sort_key(s, _nsre=re.compile('([0-9]+)')):
   return [int(text) if text.isdigit() else text.lower() for text in re.split(_nsre, s)]
end
%>
<script>

$(function() {
	// deal with indeterminate
	$('input[indeterminate]').prop('indeterminate', true);


	var get_cb_for_item = function($item) {
		return $item.find('.audience-cb input').eq(0);
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

	var update_changelogs = function(room, checked) {
		$('.changelog')
			.filter(function() {
				return $(this).data('room') == room;
			})
			.each(function() {
				if(checked)
					$(this).addClass('included');
				else
					$(this).removeClass('included');
			});

	};

	var update_numbers = function() {
		$('#count-room-total').text(
			$('.item').filter(function() {
				return get_cb_for_item($(this)).prop('checked');
			}).size()
		);

		$('#count-added-save').text(
			'+' + $('#changelog-save').find('li.changelog-add:visible').size()
		);
		$('#count-removed-save').text(
			'\u2212' + $('#changelog-save').find('li.changelog-remove:visible').size()
		);

		$('#count-added-old').text(
			'+' + $('#changelog-old').find('li.changelog-add:visible').size()
		);
		$('#count-removed-old').text(
			'\u2212' + $('#changelog-old').find('li.changelog-remove:visible').size()
		);
	};

	// ensures the treeview is consistent, given a checkbox that changed
	var update_from_cb = function($cb) {
		var checked = $cb.prop('checked')
		var $item = $cb.closest('.audience-cbs').parent();

		update_changelogs($item.data('room'), checked);

		get_child_items($item).each(function check_desc() {
			$child = $(this);

			get_cb_for_item($child).prop({
				'checked': checked,
				'indeterminate': false
			});

			update_changelogs($child.data('room'), checked);

			get_child_items($child).each(check_desc);
		});

		function go_up($p) {
			if($p.size() == 0) return;

			var all_checked = true;
			var none_checked = true;
			get_child_items($p).each(function () {
				var $cb = get_cb_for_item($(this));
				if($cb.prop('indeterminate')) {
					none_checked = false;
					all_checked = false;
				} else if ($cb.prop('checked')) {
					none_checked = false;
				} else {
					all_checked = false;
				}
			});

			var $cb = get_cb_for_item($p);
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

		update_numbers();
	};


	$('.audience-cb input').click(function() { update_from_cb($(this)); });

	// when a changelog entry is undone, update it in the tree view
	$('.changelog-undo').click(function() {
		var entry = $(this).parent('.changelog');

		// find the checkbox in the tree view
		var room = entry.data('room');
		var $item = $('.item').filter(function() { return $(this).data('room') == room; });
		var $cb = get_cb_for_item($item);

		// determine whether to check or uncheck it, and update the tree
		var added = entry.is('.changelog-remove');
		$cb.prop('checked', added);
		update_from_cb($cb);

		return false;
	});

	update_numbers();

});
</script>
<%

# build up a dictionary of Cluster => (audiences that can see every room,
#	                                   audiences that can see some rooms)
Inclusion = namedtuple('Inclusion', 'all some')
def find_inclusions(cl, evt):
	"""
	Return a dictionary of
	    Room -> bool(room is included)
	    Cluster -> Inclusion(all sub-things included, some sub-things included)
	"""
	is_included = {}

	all_desc = True
	some_desc = False
	for room in cl.rooms:
		listing = room.listing_for.get(evt.season)
		is_included[room] = (evt.type in listing.audience_types) if listing else False

		all_desc  &= is_included[room]
		some_desc |= is_included[room]
	end
	for subcl in cl.children:
		is_included.update(find_inclusions(subcl, evt))

		sub_desc = is_included[subcl]
		all_desc  &= sub_desc.all
		some_desc |= sub_desc.some
	end
	is_included[cl] = Inclusion(all_desc, some_desc)

	return is_included
end
is_included = find_inclusions(root, ballot_event)
was_included = find_inclusions(root, last_ballot_event)
%>

% def display(cl):
	% for room in sorted(cl.rooms, key=lambda r: natural_sort_key(r.name)):
		<div class="item" data-room="{{ room.id }}">
			<a href="/rooms/{{ room.id }}" target="_blank">{{ room.pretty_name(cl) }}</a>
			<div class="audience-cbs">
				<div class="audience-cb">
					<input type="checkbox"
					       title="{{ ballot_event.type.name }}"
					       name="rooms[{{ room.id }}]"
					       {{ 'checked' if is_included[room] else '' }} />
				</div>
			</div>
		</div>
	% end
	% for subcl in cl.children:
		<div class="group">
			% indeterminate = is_included[subcl].some and not is_included[subcl].all
			<input class="show-hide" type="checkbox" id="toggle-{{subcl.id}}"
			       {{ '' if indeterminate else 'checked'}} />
			<div class="group-item">
				<label class="show-hide-buttons" for="toggle-{{subcl.id}}">
					<span class="show-hide-shown glyphicon glyphicon-chevron-down"></span>
					<span class="show-hide-hidden glyphicon glyphicon-chevron-right"></span>
				</label>
				<a href="/places/{{ cl.id }}" target="_blank"><b>{{ subcl.pretty_name(cl) }}</b></a>
				<div class="audience-cbs">
					<%
					if is_included[subcl].all:
						state = 'checked'
					elif is_included[subcl].some:
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
				% display(subcl)
			</div>
		</div>
	% end
% end

<%
def all_rooms_in(cl=root):
	for r in cl.rooms:
		yield r
	end
	for c in cl.children:
		for r in all_rooms_in(c):
			yield r
		end
	end
end
%>

% def display_changes(inclusions, newer):
	<ul class="list-group">
		% for r in all_rooms_in(root):
			% if not inclusions[r]:
				<li class="changelog changelog-add {{'included' if newer[r] else ''}}"
					data-room="{{ r.id }}">
					<a href="/rooms/{{ r.id }}" target="_blank">{{ r.pretty_name() }}</a>
					<a class="changelog-undo" href="#">
						<span class="glyphicon glyphicon-share-alt" title="undo adding this room"></span>
					</a>
				</li>
			% else:
				<li class="changelog changelog-remove {{'included' if newer[r] else ''}}"
				    data-room="{{ r.id }}">
					<a href="/rooms/{{ r.id }}" target="_blank">{{ r.pretty_name() }}</a>
					<a class="changelog-undo" href="#">
						<span class="glyphicon glyphicon-share-alt" title="undo removing this room"></span>
					</a>
				</li>
			% end
		% end
	</ul>
% end


<div class="container">
	<form method="post">
		<button class="btn btn-primary btn-lg pull-right" type="submit">
			<span class="glyphicon glyphicon-floppy-disk"></span>
			Save
		</button>
		<h1>{{ ballot_event.type.name }} ballot for {{ ballot_event.season }}</h1>
		<p>Use the tree view in the left to column to select which rooms should be available in the ballot. The two other columns show changes, with additions shown in green, and deletions shown in red.</p>
		<div class="row">
			<div class="col-md-4">
				<h2>
					Rooms in the ballot
					<small id="count-room-total"></small>
				</h2>
				% display(root)
			</div>
			<div class="col-md-4" id="changelog-save">
				<h2>
					Since last save
					<small>
						<span class="text-success" id="count-added-save"></span>,
						<span class="text-danger" id="count-removed-save"></span>
					</small>
				</h2>
				% display_changes(is_included, is_included)
			</div>
			% if any(i for r, i in was_included.items() if isinstance(r, m.Room)):
				<div class="col-md-4" id="changelog-old">
					<h2>Since previous year's
						<small>
							<span class="text-success" id="count-added-old"></span>,
							<span class="text-danger" id="count-removed-old"></span>
						</small>
					</h2>
					% display_changes(was_included, is_included)
				</div>
			% end
		</div>
	</form>
</div>

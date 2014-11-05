% import database.orm as m

% rebase layout.tpl

% import re
% def natural_sort_key(s, _nsre=re.compile('([0-9]+)')):
%    return [int(text) if text.isdigit() else text.lower() for text in re.split(_nsre, s)]
% end

<style>
.group {
	margin-bottom: 20px;
}
.item, .group-item {
	overflow: hidden;
}

.group-item {
	margin-top: 5px;
	padding: 5px;
	background-color: #f0f0f0;
}
.group-item .audience-cbs{
	margin: -5px;
	padding: 5px 0px;
}
.group-children {
	margin-left: 10px;
	padding-left: 10px;
	border-left: 1px solid gray;
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
	border-left: 1px solid #c0c0c0;
}
.audience-cbs .audience-cb {
	width: 40px;
	text-align: center;
	float: left;
}
</style>

% class fullset(set):
	% def __and__(self, other):
		% return other
	% end
% end

% audiences = {}
% def process(cl):
	% some_a = set()
	% all_a = fullset()
	% for room in cl.rooms:
		% listing = room.listing_for.get(ballot_season)
		% audiences[room] = set(listing.audience_types) if listing else set()

		% all_a = all_a & set(audiences[room])
		% some_a = some_a | set(audiences[room])
	% end
	% print all_a
	% for subcl in cl.children:
		% process(subcl)
		% all_as, some_as = audiences[subcl]
		% all_a = all_a & all_as
		% some_a = some_a | some_as
	% end

	% audiences[cl] = all_a, some_a
% end
% process(root)

% def display(cl):
	% for room in sorted(cl.rooms, key=lambda r: natural_sort_key(r.name)):
		<div class="item">
			<a href="/rooms/{{ room.id }}" target="_blank">{{ room.pretty_name(cl) }}</a>
				<div class="audience-cbs">
				% for event in ballot_season.events:
					<div class="audience-cb">
						<input type="checkbox"
						       title="{{ event.type.name }}"
						       data-type="{{ event.type.name }}"
						       name="rooms[{{ room.id }}][{{ event.type.name }}]"
						       {{ 'checked' if event.type in audiences[room] else '' }} />
					</div>
				% end
			</div>
		</div>
	% end
	% for subcl in cl.children:
		<div class="group">
			<div class="group-item">
				<a href="/places/{{ cl.id }}" target="_blank"><b>{{ subcl.pretty_name(cl) }}</b></a>
				<div class="audience-cbs">
					% for event in ballot_season.events:
						% if event.type in audiences[subcl][0]:
							% state = 'checked'
						% elif event.type in audiences[subcl][1]:
							% state = 'indeterminate'
						% else:
							% state = ''
						% end
						<div class="audience-cb">
							<input type="checkbox"
							       title="{{ event.type.name }}"
							       data-type="{{ event.type.name }}"
							       {{ state }} />
						</div>
					% end
				</div>
			</div>
			<div class="group-children">
				% display(subcl)
			</div>
		</div>
	% end
% end
<div class="container">
	<h1>Ballot for {{ ballot_season }}</h1>
	<div class="row">
		<div class="col-md-6">
			% display(root)
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
})
// $(function() {
// 	  // Apparently click is better chan change? Cuz IE?
// 	$('input[type="checkbox"]').change(function(e) {
// 		var checked = $(this).prop("checked"),
// 			container = $(this).parent(),
// 			siblings = container.siblings();

// 		if(!container.is('.item')) {
// 			container.parent().find('input[type="checkbox"]').prop({
// 				indeterminate: false,
// 				checked: checked
// 			});
// 		}

// 		function checkSiblings(el) {
// 			var parent = el.parent().parent(),
// 				all = true;

// 			el.siblings().each(function() {
// 				return all = ($(this).children('input[type="checkbox"]').prop("checked") === checked);
// 			});

// 			if (all && checked) {
// 				parent.children('input[type="checkbox"]').prop({
// 					indeterminate: false,
// 					checked: checked
// 				});
// 				checkSiblings(parent);
// 			} else if (all && !checked) {
// 				parent.children('input[type="checkbox"]').prop("checked", checked);
// 				parent.children('input[type="checkbox"]').prop("indeterminate", (parent.find('input[type="checkbox"]:checked').length > 0));
// 				checkSiblings(parent);
// 			} else {
// 				el.parents("li").children('input[type="checkbox"]').prop({
// 					indeterminate: true,
// 					checked: false
// 				});
// 			}
// 		}

// 		checkSiblings(container);
// 	});
// });
</script>

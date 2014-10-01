import regex as re
import itertools

room_range = re.compile(r'''
	\b(?:
		# match the prefix indicating the next number is a room number
		(?:
			rooms\ +
			|
			(?-i:(?P<staircase>[A-Z]))
		)

		(?:
			# match a range of rooms, without all being listed
			(?P<range_start>\d+)
			\ *(?:-|to)\ *
			(?-i:\g<staircase>)?
			(?P<range_end>\d+)
			|
			# match a list of rooms, where only the first is prefixed
			(?:
				(?P<number>\d+)
				(?P<sep>,|\ |/|and|or|&)+
			)*
			(?P<number>\d++)
		)
	|
		# match a single room without a staircase. Intentionally special cased
		(?!gyp\ )room\ +(?P<number>\d++)
	)\b
	''',
	re.V1 | re.X | re.I # V1 needed for scoped case sensitivity
)
i = 0

def references_in_m(match):
	context = match.string[match.span()[0] - 10:match.span()[1] + 10]
	staircase = match.captures('staircase')

	if match.captures('number'):
		rooms = match.captures('number')
		spans = match.spans('number')

		# first match should include staircase letter
		if staircase:
			s, e = spans[0]
			spans[0] = (s - 1, e)

		items = itertools.izip(rooms, spans)

		# special case rooms like N7/8
		if match.group('sep') == '/' and len(rooms) == 2:
			yield staircase + ['/'.join(rooms)], (spans[0][0], spans[1][1])

		if len(rooms) == 1:
			yield staircase + rooms, match.span()

		else:
			for room_id, span in items:
				yield staircase + [room_id], span
	else:
		start = int(match.group('range_start'))
		end = int(match.group('range_end'))

		if start < end:
			rooms = map(str, range(start, end + 1))
		else:
			rooms = map(str, range(end, start + 1))

		span = match.span()

		for room_id in rooms:
			yield staircase + [room_id], span

def references_in(s):
	for match in room_range.finditer(s):
		for ref in references_in_m(match):
			yield ref
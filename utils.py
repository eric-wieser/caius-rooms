from datetime import datetime, date
import random
import string

def format_ts(ts):
	""" Used to format any timestamp in a readable way """
	now = datetime.now()
	today = now.date()

	if ts.date() == today:
		return "{:%H:%M:%S}".format(ts)
	if ts.date().year == today.year:
		return "{:%b %d, %H:%M}".format(ts)
	else:
		return "{:%Y, %b %d}".format(ts)

def format_ts_html(ts):
	return '<time title="{}">{}</time>'.format(
		ts.isoformat(), format_ts(ts)
	)

def restricted():
	s = random.sample(string.ascii_lowercase, 20)
	random.shuffle(s)
	s = ''.join(s)

	s1, s2 = s[:10], s[10:]

	return ''.join([
		'<span class="text-warning" title="Requires login" data-tooltip>',
			'<span class="glyphicon glyphicon-lock"></span>',
			'&nbsp;',
			'<span style="position: relative">',
				'{s1}',
				'<span style="position: absolute; left: 0">{s2}</span'
			'</span>',
		'</span>'
	]).format(s1=s1, s2=s2)
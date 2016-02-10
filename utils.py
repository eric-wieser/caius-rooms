from __future__ import division
from datetime import datetime, timedelta
import random
import string
import itertools

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

def safe_markdown(content):
	from CommonMark import Parser, HtmlRenderer
	ast = Parser().parse(content)

	a = ast.walker()

	for data in iter(a.nxt, None):
		n = data['node']
		if n.t == u'HtmlBlock':
			n.unlink()

	return HtmlRenderer().render(ast)

def format_tdelta(td):
	def s(n):
		return 's' if n != 1 else ''

	seconds = td.total_seconds()

	one_week = timedelta(weeks=1).total_seconds()
	one_day = timedelta(days=1).total_seconds()
	one_hour = timedelta(hours=1).total_seconds()
	one_minute = timedelta(minutes=1).total_seconds()
	one_second = timedelta(seconds=1).total_seconds()

	td_seconds = seconds % one_minute
	td_minutes = int((seconds % one_hour) // one_minute)
	td_hours   = int((seconds % one_day) // one_hour)
	td_days    = int((seconds % one_week) // one_day)
	td_weeks   = int(seconds // one_week)

	if td_weeks >= 2:
		return '{} weeks'.format(td_weeks)
	elif td_weeks >= 1:
		return '{} week{} and {} day{}'.format(td_weeks, s(td_weeks), td_days, s(td_days))

	elif td_days >= 3:
		return '{} days'.format(td_days)
	elif td_days >= 1:
		return '{} day{} and {} hour{}'.format(td_days, s(td_days), td_hours, s(td_hours))

	elif td_hours >= 12:
		return '{} hours'.format(td_hours)
	elif td_hours >= 1:
		return '{} hour{} and {} minute{}'.format(td_hours, s(td_hours), td_minutes, s(td_minutes))

	elif td_minutes >= 1:
		return '{} minute{} and {} second{}'.format(td_minutes, s(td_minutes), int(td_seconds), s(int(td_seconds)))

	else:
		return '{:.4f} seconds'.format(td_seconds)

def format_tdelta_html(td):
	return '<span title="Or more precisely, {}, as of loading this page">{}</span>'.format(
		str(td), format_tdelta(td)
	)

def format_ballot_html(ballot_season):
	return '{}<span class="hidden-xs"> &ndash; {}</span>'.format(ballot_season.year, ballot_season.year+1)

def restricted(message=None):
	if not message:
		s = random.sample(string.ascii_lowercase, 20)
		random.shuffle(s)
		s = ''.join(s)

		s1, s2 = s[:10], s[10:]

		message = ''.join([
			'<span style="position: relative">',
				'{s1}',
				'<span style="position: absolute; left: 0">{s2}</span'
			'</span>'
		]).format(s1=s1, s2=s2)

	return ''.join([
		'<span class="text-warning" title="Requires login" data-tooltip>',
			'<span class="glyphicon glyphicon-lock"></span>',
			'&nbsp;',
			message,
		'</span>'
	])

def grouper(iterable, n):
	it = iter(iterable)
	while True:
		chunk = tuple(itertools.islice(it, n))
		if not chunk:
			return
		yield chunk

def lookup_ldap(crsids):
	"""
	Looks up a bunch of crsids on lookup.cam.ac.uk, and return a dictionary
	mapping crsids to results. Example result format is:

	{
      "cancelled" : false,
      "identifier" : {
        "scheme" : "crsid",
        "value" : "efw27"
      },
      "displayName" : "Eric Wieser",
      "registeredName" : "E.F. Wieser",
      "surname" : "Wieser",
      "visibleName" : "Eric Wieser",
      "misAffiliation" : "student",
      "staff" : false,
      "student" : true
    }

    Not all crsids will have an associated result, and the presence of any of
    these keys is not guaranteed
    """
	import requests

	result = {}

	# limit the numver per request
	for some_crsids in grouper(crsids, 200):
		r = requests.get(
			'https://www.lookup.cam.ac.uk/api/v1/person/list',
			params=dict(
				format='json',
				crsids=','.join(some_crsids)
			),
			auth=('anonymous', '')
		)
		r.raise_for_status()
		data = r.json()[u'result'][u'people']

		# update the lookup by crsid
		result.update({
			d[u'identifier'][u'value']: d
			for d in data
		})

	return result

from bottle import request, template, response

def needs_auth(reason_or_callback, reason='privacy'):
	# handle the optional "reason" argument
	if isinstance(reason_or_callback, basestring):
		reason = reason_or_callback
		return lambda callback: needs_auth(callback, reason)
	else:
		callback = reason_or_callback

	def wrapper(*args, **kwargs):
		if not request.user or (reason == 'admin' and not request.user.is_admin):
			response.status = 403
			return template('messages/needs-auth', reason=reason)

		return callback(*args, **kwargs)

	return wrapper

def url_for(x, extra_path=None, qs={}):
	import database.orm as m
	from urllib import urlencode

	if isinstance(x, m.Room):
		base = '/rooms/{}'.format(x.id)
	elif isinstance(x, m.Person):
		base = '/users/{}'.format(x.crsid)
	elif isinstance(x, m.BallotSeason):
		base = '/ballots/{}'.format(x.year)
	elif isinstance(x, m.Place):
		base = '/places/{}'.format(x.id)
	elif isinstance(x, str):
		base = x
	else:
		raise ValueError
	if extra_path:
		base += '/' + extra_path

	query = {}

	if request.query.ballot:
		query['ballot'] = request.query.ballot

	query.update(qs)

	if query:
		return base + '?' + urlencode(query)
	else:
		return base

def update_csrf_token():
	import binascii
	import os
	request.session['crsf_token'] = binascii.hexlify(os.urandom(32))

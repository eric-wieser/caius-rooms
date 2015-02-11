from datetime import datetime
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
	elif isinstance(x, m.Cluster):
		base = '/places/{}'.format(x.id)
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


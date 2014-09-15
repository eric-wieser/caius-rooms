import requests


def logged_in_session(user, pwd=None):
	if not logged_in_session.cached:
		if pwd is None:
			with open('password.txt') as f:
				pwd = f.read()[::-1]

		s = requests.session()
		s.mount('http://www.caiusjcr.org.uk', requests.adapters.HTTPAdapter(max_retries=5))
		s.max_redirects = 3

		# make roomCaius aware we're logging in
		r = s.get('http://www.caiusjcr.org.uk/roomCaius/index.php')

		a = r.text

		# now log in
		r = s.post('https://raven.cam.ac.uk/auth/authenticate2.html', data={
			'userid': user,
			'url': 'http://www.caiusjcr.org.uk/roomCaius/index.php',
			'pwd': pwd,
			'ver': 1,
		})

		a = r.text

		logged_in_session.cached = s


	return logged_in_session.cached

logged_in_session.cached = None

def get_url(url, *args, **kwargs):
	"""Get a page, logging in if necessary"""
	s = requests.session()
	while True:
		r = s.get(url, *args, **kwargs)


		# no authentication required
		if not (
				r.url.startswith('https://raven.cam.ac.uk/auth/authenticate.html') or
				'Click <a href="/roomCaius">here to reauthenticate</a>' in r.text):
			return r.text

		# authentication not recognized
		elif s is logged_in_session.cached:
			print "Session expired"
			logged_in_session.cached = None
			s = logged_in_session('efw27')

		else:
			print "Session started"
			s = logged_in_session('efw27')

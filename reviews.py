import os
import re
import json
from datetime import datetime

# external dependencies
import requests
from bs4 import BeautifulSoup

def logged_in_session(user, pwd):
	s = requests.session()
	s.mount('http://www.caiusjcr.org.uk', requests.adapters.HTTPAdapter(max_retries=5))
	s.max_redirects = 3

	# make roomCaius aware we're logging in
	s.get('http://www.caiusjcr.org.uk/roomCaius/index.php')

	# now log in
	r = s.post('https://raven.cam.ac.uk/auth/authenticate2.html', data={
		'userid': user,
		'url': 'http://www.caiusjcr.org.uk/roomCaius/index.php',
		'pwd': pwd,
		'ver': 1,
	})

	return s

def download_reviews():
	for i in range(1000):
		r = requests.get('http://www.caiusjcr.org.uk/roomCaius/Reviews.php?roomid={}'.format(i))

		if u'data-roomname="<br />' in r.text or r.text.startswith('<b>Fatal error</b>'):
			print "Fail", i
		else:

			with open('dump/reviews/room-{}.html'.format(i), 'w') as f:
				f.write(r.text.encode('utf8'))

			print "Success", i


def download_photos():
	with open('all.json') as f:
		data = json.load(f)

	for i in data:
		r = requests.get('http://www.caiusjcr.org.uk/roomCaius/photos.php?roomid={}'.format(i))

		with open('dump/photos/room-{}.html'.format(i), 'w') as f:
			f.write(r.text.encode('utf8'))

def download_residents():
	with open('all.json') as f:
		data = json.load(f)

	for i in data:
		r = requests.get('http://www.caiusjcr.org.uk/roomCaius/previousResidents.php?roomid={}'.format(i))

		with open('dump/residents/room-{}.html'.format(i), 'w') as f:
			f.write(r.text.encode('utf8'))
		print "Done", i

def download_features():
	""" This takes a really long time! """
	s = logged_in_session('efw27', raw_input('password'))


	with open('places.json') as f:
		places = json.load(f)

	for place in places.values():
		r = s.get('http://www.caiusjcr.org.uk/roomCaius/index.php?location={}'.format(place['name'].replace(' ', '%20')), allow_redirects=False)

		with open('dump/features/place-{}.html'.format(place['name']), 'w') as f:
			f.write(r.text.encode('utf8'))

		print place['name']

def parse_reviews():
	rooms = {}

	pattern = re.compile('room-(\d+).html')
	for fname in os.listdir('dump/reviews'):
		i = int(pattern.match(fname).group(1))

		r = rooms[i] = {}

		with open(os.path.join('dump', 'reviews', fname)) as f:
			soup = BeautifulSoup(f)
			r['name'] = soup.button['data-roomname']
			r['reviews'] = []
			r['id'] = i
			for elem in soup.find_all('div', {'class': 'bubble'}):
				review = {
					'sections': []
				}
				review_list = elem.find('dl')
				last_key = None
				for c in review_list.children:
					try:
						if c.name == 'dt':
							last_key = c.getText().strip()
							if 'Overall Satisfaction' in last_key:
								review['rating'] = re.search(r'(\d*)/10', last_key).group(1)
								if not review['rating']:
									review['rating'] = 0
								else:
									review['rating'] = int(review['rating'])
								last_key = None
						elif c.name == 'dd':
							value = c.getText().strip()
							if 'Rated in' in value:
								review['date'] = int(re.search(r'in (\d+)', value).group(1))

							elif last_key is not None:
								review['sections'].append({'name': last_key, 'value': value})
								last_key = None
					except:
						print c
						raise

				r['reviews'].append(review)

	print "printing..."

	from pprint import pprint
	with open('all.json', 'w') as a:
		json.dump(rooms, a, sort_keys=True, indent=4, separators=(',', ': '))


def parse_photos():
	root = 'http://gcsu.soc.srcf.net/roomCaius/'

	with open('all.json') as f:
		rooms = json.load(f)

	for k, room in rooms.iteritems():
		with open('dump/photos/room-{}.html'.format(k)) as f:
			soup = BeautifulSoup(f)
		images = room['images'] = []

		wrapper = soup.find('div', {'class': 'carousel-inner'})
		if wrapper is None:
			print "Error getting photos for room", k
			continue

		for elem in wrapper.find_all('div', {'class': 'item'}):
			image = {}
			image['caption'] = elem.find('h4').get_text().strip()
			image['href'] = root + elem.find('img')['src']

			images.append(image)

	with open('all.json', 'w') as a:
		json.dump(rooms, a, sort_keys=True, indent=4, separators=(',', ': '))


def parse_residents():
	root = 'http://gcsu.soc.srcf.net/roomCaius/'

	with open('all.json') as f:
		rooms = json.load(f)

	for k, room in rooms.iteritems():
		with open('dump/residents/room-{}.html'.format(k)) as f:
			soup = BeautifulSoup(f)

		for item in soup.find_all('li'):
			year, link = item.contents

			year = int(year.rstrip(u'\u2014'))

			reviews = [r for r in room['reviews'] if r['date']-1 == year]

			if not reviews:
				r = {
					'date': year,
					'rating': None
				}
				room['reviews'].append(r)
				reviews = [r]

			for r in reviews:
				if 'rating' not in r:
					r['rating'] = None
				r['resident'] = {
					'name': link.get_text(),
					'email': link['href'].split(':')[1]
				}

			room['reviews'].sort(key=lambda r: r['date'], reverse=True)

	with open('all.json', 'w') as a:
		json.dump(rooms, a, sort_keys=True, indent=4, separators=(',', ': '))


def parse_features():
	with open('all.json') as f:
		rooms = json.load(f)


	with open('places.json') as f:
		places = json.load(f)

	for place in places.values():
		with open('dump/features/place-{}.html'.format(place['name'])) as f:
			soup = BeautifulSoup(f)

		for i in place['roomIds']:
			room = rooms[str(i)]
			d = soup.find('div', id='room-{}'.format(i))
			if d is None:
				print "Can't find {r} ({i}) in {p}".format(i=room['id'], r=room['name'], p=place['name'])
				continue

			details = d.find('div', id='details')
			rows = [
				c
				for row in details.find_all('div', recursive=False)
				for c in row.find_all('div', recursive=False)
			]


			data = {}
			for row in rows:
				if row.contents:
					prop = row.contents[0].get_text()
					value = row.contents[1][1:].strip()
					data[prop] = value

			room['details'] = data

		with open('all.json', 'w') as a:
			json.dump(rooms, a, sort_keys=True, indent=4, separators=(',', ': '))

def parse_places():
	pattern = re.compile(r'locations\["(.*?)"\].*new google\.maps\.LatLng\(\s*([\d.]+)\s*,\s*([\d.]+)\s*\)')
	places = {}

	# secret places. No one must know of these?
	secret = [
		{
			'name': '5 Harvey Rd'
		}, {
			'name': '6 Harvey Rd'
		}, {
			'name': '3 St Pauls Rd'
		}, {
			'name': '4 St Pauls Rd'
		}, {
			'name': '35-37 Chesterton Rd',
			"location": {"lat": "52.2129", "lng": "0.119669"}
		}, {
			'name': '1a Rose Crescent',
			"location": {"lat": "52.2063", "lng": "0.118154"}
		}, {
			'name': '43 Glisson Rd',
			"location": {"lat": "52.198", "lng": "0.1325"}
		}
	]
	for s in secret:
		s['roomIds'] = []
		s['unlisted'] = True
		s['location'] = s.get('location', {})
		places[s['name']] = s


	with open('dump/other/index.php') as f:
		while next(f) != 'var locations = new Array();\n':
			pass

		while True:
			m = pattern.match(next(f))
			if not m: break

			name, lat, lng = m.groups()

			if name == 'KBlock':
				name = 'K Block'


			places[name] = {
				"name": name,
				"location": { "lat": lat, "lng": lng },
				"roomIds": []
			}

	for place in places.values():
		parts = place['name'].split(None, 1)
		if parts[0][0].isdigit():
			place['group'] = parts[1]
		else:
			place['group'] = None


	with open('all.json') as f:
		rooms = json.load(f)

	for room in rooms.values():
		room['place'] = ''
		room['number'] = ''
		for place in places.values():
			if room['name'].startswith(place['name']):
				room['place'] = place['name']
				room['number'] = room['name'].split(place['name'], 1)[1].strip()
				place['roomIds'].append(room['id'])

	with open('all.json', 'w') as a:
		json.dump(rooms, a, sort_keys=True, indent=4, separators=(',', ': '))

	with open('places.json', 'w') as a:
		json.dump(places, a, sort_keys=True, indent=4, separators=(',', ': '))

def parse_some_things():
	parse_photos()
	parse_residents()
	parse_places()
	parse_features()


def get_all_the_things():
	d = datetime.now()

	print "Downloading reviews"
	download_reviews()

	# Reviews map to rooms, so parse these before fetching anything else
	print "Downloading other things"
	parse_reviews()
	download_photos()
	download_residents()

	# parse the rest
	print "Parsing other things"
	parse_photos()
	parse_residents()
	parse_places()

	# Y U SO SLOW?
	print "Downloading details"
	download_features()
	print "Parsing details"
	parse_features()

	d2 = datetime.now()
	print "Took", d2 - d


get_all_the_things()

import os
import re
import json

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

		if u'data-roomname="<br />' in r.text:
			print "Fail", i
		else:

			with open('reviews/room-{}.html'.format(i), 'w') as f:
				f.write(r.text.encode('utf8'))

			print "Success", i


def download_photos():
	with open('all.json') as f:
		data = json.load(f)

	for i in data:
		r = requests.get('http://www.caiusjcr.org.uk/roomCaius/photos.php?roomid={}'.format(i))

		with open('photos/room-{}.html'.format(i), 'w') as f:
			f.write(r.text.encode('utf8'))

def download_residents():
	with open('all.json') as f:
		data = json.load(f)

	for i in data:
		r = requests.get('http://www.caiusjcr.org.uk/roomCaius/previousResidents.php?roomid={}'.format(i))

		with open('residents/room-{}.html'.format(i), 'w') as f:
			f.write(r.text.encode('utf8'))

def download_features():
	""" This takes a really long time! """
	s = logged_in_session('efw27', raw_input('password'))


	with open('places.json') as f:
		places = json.load(f)

	for place in places.values():
		r = s.get('http://www.caiusjcr.org.uk/roomCaius/index.php?location={}'.format(place['name'].replace(' ', '%20')), allow_redirects=False)

		with open('features/place-{}.html'.format(place['name']), 'w') as f:
			f.write(r.text.encode('utf8'))

		print place['name']

def parse_reviews():
	rooms = {}

	pattern = re.compile('room-(\d+).html')
	for fname in os.listdir('reviews'):
		i = int(pattern.match(fname).group(1))

		r = rooms[i] = {}

		with open(os.path.join('reviews', fname)) as f:
			soup = BeautifulSoup(f)
			r['name'] = soup.button['data-roomname']
			r['reviews'] = []
			r['id'] = i
			for elem in soup.find_all('div', {'class': 'bubble'}):
				review = {}
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
								review['rated-in'] = int(re.search(r'in (\d+)', value).group(1))

							elif last_key is not None:
								review[last_key] = value
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
		with open('photos/room-{}.html'.format(k)) as f:
			soup = BeautifulSoup(f)
		images = room['images'] = []

		wrapper = soup.find('div', {'class': 'carousel-inner'})

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
		with open('residents/room-{}.html'.format(k)) as f:
			soup = BeautifulSoup(f)

		for item in soup.find_all('li'):
			year, link = item.contents

			year = int(year.rstrip(u'\u2014'))

			reviews = [r for r in room['reviews'] if r['rated-in'] == year]

			if not reviews:
				r = {
					'rated-in': year,
					'rating': None
				}
				room['reviews'].append(r)
				reviews = [r]

			for r in reviews:
				if 'rating' not in r:
					r['rating'] = None
				r['rated-by'] = {
					'name': link.get_text(),
					'email': link['href'].split(':')[1]
				}

			room['reviews'].sort(key=lambda r: r['rated-in'], reverse=True)

	with open('all.json', 'w') as a:
		json.dump(rooms, a, sort_keys=True, indent=4, separators=(',', ': '))


def parse_descriptions():
	with open('all.json') as f:
		rooms = json.load(f)


	with open('places.json') as f:
		places = json.load(f)

	for place in places.values():
		with open('features/place-{}.html'.format(place['name'])) as f:
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
				prop = row.contents[0].get_text()
				value = row.contents[1][1:].strip()
				data[prop] = value

			room['details'] = data

		with open('all.json', 'w') as a:
			json.dump(rooms, a, sort_keys=True, indent=4, separators=(',', ': '))

def parse_places():
	pattern = re.compile(r'locations\["(.*?)"\].*new google\.maps\.LatLng\(\s*([\d.]+)\s*,\s*([\d.]+)\s*\)')
	places = {}

	places['5 Harvey Rd'] = {
		'name': '5 Harvey Rd',
		"location": {},
		"roomIds": []
	}
	places['6 Harvey Rd'] = {
		'name': '6 Harvey Rd',
		"location": {},
		"roomIds": []
	}
	places['3 St Pauls Rd'] = {
		'name': '3 St Pauls Rd',
		"location": {},
		"roomIds": []
	}
	places['4 St Pauls Rd'] = {
		'name': '4 St Pauls Rd',
		"location": {},
		"roomIds": []
	}

	with open('other/index.php') as f:
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



# download_reviews()
# parse_reviews()
# download_photos()
# parse_photos()

# parse_reviews()
# parse_photos()
# parse_places()
# download_residents()
# parse_residents()

# download_features()

parse_descriptions()
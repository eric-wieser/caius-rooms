import os
import re
import json

# external dependencies
import requests
from bs4 import BeautifulSoup

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

	with open('all2.json', 'w') as a:
		json.dump(rooms, a, sort_keys=True, indent=4, separators=(',', ': '))

download_reviews()
parse_reviews()
download_photos()
parse_photos()

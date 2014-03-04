from raven import get_url


from bs4 import BeautifulSoup
import time
import json
from datetime import datetime

def last_line(f):
	line = None
	for line in f:
		pass
	return line

class Ticker(object):
	def __init__(self, fname):
		self.fname = fname
		self.last = None
		with open(fname) as f:
			l = last_line(f)
			if l is not None:
				self.last = tuple(json.loads(l))

	def update(self, data):
		while data and self.last in data:
			data = data[1:]

		if data:
			with open(self.fname, 'a') as f:
				for r in data:
					print >> f, json.dumps(r)
			self.last = r
			return True
		return False

res_tick = Ticker('reservations.json')
slots_tick = Ticker('slots.json')

def update():

	r = get_url('http://www.caiusjcr.org.uk/roomCaius/index.php')
	soup = BeautifulSoup(r)

	reservations, reviews, slots = soup.find(id='sidebar1').find('ul').find_all('ul')

	reservations = [tuple(r.get_text().split(' has reserved ')) for r in reservations.find_all('a')]
	slots = [tuple(r.get_text().strip().split(u'\u2014')) for r in slots.find_all('a')]

	return any([
		res_tick.update(reservations),
		slots_tick.update(slots)
	])

while True:
	if update():
		print "updated at ", datetime.now()
	time.sleep(30)

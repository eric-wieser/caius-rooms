""" Script to run through log files and format them readably """
from __future__ import print_function

import os
import sqlparse
import fileinput

def process(f, skip=False):
	st = []
	for line in f:
		line = line.rstrip('\n')
		if line.startswith('('):
			if skip:
				yield
			else:
				yield sqlparse.format(
					' '.join(st).replace('_room_picks_', 'RP_'),
					reindent=True
				) + ';\n-- {}\n'.format(line)
				st = []
		else:
			st.append(line)


it = fileinput.input([x for x in os.listdir('.') if x.endswith('.log')], inplace=True)

print("queries : path")

for f in sorted(os.listdir('.')):
	if f.endswith('.log'):
		with open(f) as inf, open(f + '.sql', 'w') as outf:
			qs = 0
			for line in process(inf):
				qs += 1
				print(line, file=outf)
				if qs > 200:
					break

			for line in process(inf, skip=True):
				qs += 1

			print("{1:7} : {0}".format(f[:-4].replace('.', '/'), qs))

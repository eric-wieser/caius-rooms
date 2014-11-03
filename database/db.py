import os

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

try:
	from db_conn import user, password
	engine = create_engine(
		'mysql+mysqldb://{user}:{password}@localhost/gcsu/roompicks?charset=utf8&use_unicode=1'.format(
			user=user, password=password
		),
		pool_recycle=3600
	)
except ImportError:
	print "Using development sqlite database"
	base_dir = os.path.dirname(__file__)
	engine = create_engine('sqlite:///{}'.format(os.path.join(base_dir, 'dev.db')))

Session = sessionmaker(engine)

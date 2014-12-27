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

	from sqlalchemy.engine import Engine
	from sqlalchemy import event

	@event.listens_for(Engine, "connect")
	def set_sqlite_pragma(dbapi_connection, connection_record):
	    cursor = dbapi_connection.cursor()
	    cursor.execute("PRAGMA foreign_keys=ON")
	    cursor.close()

Session = sessionmaker(engine)

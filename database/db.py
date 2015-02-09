import os

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

try:
	import db_conn
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
else:
	if db_conn.db_type == 'mysql':
		engine = create_engine(
			'mysql+mysqldb://{user}:{password}@localhost/gcsu/roompicks?charset=utf8&use_unicode=1'.format(
				user=db_conn.user,
				password=db_conn.password
			),
			pool_recycle=3600
		)
	elif db_conn.db_type == 'postgres':
		engine = create_engine(
			'postgresql+psycopg2://{user}:{password}@localhost:5432/gcsu'.format(
				user=db_conn.postgres_user,
				password=db_conn.postgres_password
			)
		)
		import orm
		Base.metadata.schema = 'roompicks'

Session = sessionmaker(engine)

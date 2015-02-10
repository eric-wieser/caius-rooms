import os

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

def makeSQLLite():
	base_dir = os.path.dirname(__file__)
	engine = create_engine('sqlite:///{}'.format(os.path.join(base_dir, 'dev.db')))

	# fix foreign keys in SQLite
	from sqlalchemy import event

	@event.listens_for(engine, "connect")
	def set_sqlite_pragma(dbapi_connection, connection_record):
		cursor = dbapi_connection.cursor()
		cursor.execute("PRAGMA foreign_keys=ON")
		cursor.close()

	return engine

def makeMySQL(user, password):
	return create_engine(
		'mysql+mysqldb://{user}:{password}@localhost/gcsu/roompicks?charset=utf8&use_unicode=1'.format(
			user=user,
			password=password
		),
		pool_recycle=3600
	)

def makePostgreSQL():
	return create_engine('postgresql+psycopg2://localhost:5432/gcsu')

try:
	import db_conn
except ImportError:
	print "Using local sqlite database"
	engine = makeSQLLite()
else:
	if db_conn.db_type == 'mysql':
		engine = makeMySQL(db_conn.user, db_conn.password)
	elif db_conn.db_type == 'postgres':
		engine = makePostgreSQL()

Session = sessionmaker(engine)

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.automap import automap_base


try:
	from db_conn import user, password
	engine = create_engine(
		'mysql+mysqldb://{user}:{password}@localhost/gcsu?charset=latin-1&use_unicode=0'.format(
			user=user, password=password
		),
		pool_recycle=3600
	)
except ImportError:
	import os
	base_dir = os.path.dirname(__file__)
	engine = create_engine('sqlite:///{}'.format(os.path.join(base_dir, 'srcf.db')))

Session = sessionmaker(engine)

Base = automap_base()
Base.prepare(engine, reflect=True)

orm = Base.classes

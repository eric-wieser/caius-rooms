from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

Session = sessionmaker()

def init(mode):
	global engine
	if mode == 'real':
		engine = create_engine(
			'<snip>',
			pool_recycle=3600
		)
	elif mode == 'dev':
		engine = create_engine('sqlite:///test.db')

	Session.configure(bind=engine)

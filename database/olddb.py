from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.automap import automap_base

import os


Session = sessionmaker()

base_dir = os.path.dirname(__file__)
engine = create_engine('sqlite:///{}'.format(os.path.join(base_dir, 'srcf.db')))

Session.configure(bind=engine)


Base = automap_base()
Base.prepare(engine, reflect=True)

orm = Base.classes

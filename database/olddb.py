from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.automap import automap_base

Session = sessionmaker()

engine = create_engine('sqlite:///srcf.db')

Session.configure(bind=engine)


Base = automap_base()
Base.prepare(engine, reflect=True)

orm = Base.classes

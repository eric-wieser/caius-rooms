from sqlalchemy import create_engine

from db import makePostgreSQL
import copydb

old_engine = makePostgreSQL('efw27')
new_engine = create_engine('sqlite:///postgres.sqlite3')

copydb.copy(old_engine, new_engine)

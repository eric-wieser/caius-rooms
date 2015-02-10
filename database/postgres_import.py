from db import makeMySQL, makePostgreSQL
from sqlalchemy.orm import sessionmaker
import orm as m

new_engine = makePostgreSQL('efw27')
old_engine = makeMySQL('gcsu', raw_input('gcsu db password:'))
import copydb

copydb.copy(old_engine, new_engine)

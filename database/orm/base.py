from sqlalchemy.types import String
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()
CRSID = String(10)

import ldap
import sys

ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT,ldap.OPT_X_TLS_NEVER)
cam_ldap = ldap.initialize('ldaps://ldap.lookup.cam.ac.uk')

def get_name(crsid):
	d = cam_ldap.search_s(
		base="ou=people,o=University of Cambridge,dc=cam,dc=ac,dc=uk",
		scope=ldap.SCOPE_SUBTREE,
		filterstr="uid={}".format(crsid),
		attrlist=['displayName']
	)
	return d[0][1]['displayName']

import db
import orm
from sqlalchemy.orm import aliased
from sqlalchemy.orm.exc import NoResultFound
import olddb

db.init('dev')

new_session = db.Session()
old_session = olddb.Session()

for user in old_session.query(olddb.orm.accom_guide_person):
	if any(x in user.CRSID for x in (u'-', u'MUSIC', u'RESERVED')):
		continue

	if user.CRSID.lower() != user.CRSID:
		continue

	p = orm.Person(
		name=user.Name,
		crsid=user.CRSID.lower()
	)
	new_session.add(p)

new_session.commit()

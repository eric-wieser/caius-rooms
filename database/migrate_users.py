import db
import orm
import olddb

import ldap
import sys

ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT,ldap.OPT_X_TLS_NEVER)
cam_ldap = ldap.initialize('ldaps://ldap.lookup.cam.ac.uk')

def get_name(crsid):
	""" Retrieve the ldap display name, if possible """
	results = cam_ldap.search_s(
		base="ou=people,o=University of Cambridge,dc=cam,dc=ac,dc=uk",
		scope=ldap.SCOPE_SUBTREE,
		filterstr="uid={}".format(crsid),
		attrlist=['displayName']
	)

	if not results:
		get_name.unlisted.add(crsid)
		return

	_, attrs = results[0]
	displayNames = attrs.get('displayName')
	if not displayNames:
		get_name.no_name.add(crsid)
		return

	return displayNames[0].decode('utf-8')

get_name.unlisted = set()
get_name.no_name = set()


db.init('dev')

new_session = db.Session()
old_session = olddb.Session()

for user in old_session.query(olddb.orm.accom_guide_person):
	if any(x in user.CRSID for x in (u'-', u'MUSIC', u'RESERVED')):
		continue

	crsid = user.CRSID.lower()

	if crsid != user.CRSID:
		continue

	p = orm.Person(
		name=get_name(crsid) or user.Name,
		crsid=crsid
	)
	new_session.add(p)

new_session.commit()

print "No displayName in LDAP - {}: {}".format(len(get_name.no_name),  ', '.join(sorted(get_name.no_name)))
print "Not listed in LDAP - {}: {}"    .format(len(get_name.unlisted), ', '.join(sorted(get_name.unlisted)))

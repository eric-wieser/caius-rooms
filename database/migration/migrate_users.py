import db
import orm
import olddb

import ldap
import sys

ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT,ldap.OPT_X_TLS_NEVER)
cam_ldap = ldap.initialize('ldaps://ldap.lookup.cam.ac.uk')

def get_name(crsid):
	""" Retrieve the ldap display name, if possible """
	if get_name.no_ldap:
		return

	try:
		results = cam_ldap.search_s(
			base="ou=people,o=University of Cambridge,dc=cam,dc=ac,dc=uk",
			scope=ldap.SCOPE_SUBTREE,
			filterstr="uid={}".format(crsid),
			attrlist=['displayName']
		)
	except ldap.NO_SUCH_OBJECT:
		get_name.no_ldap = True
		return

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
get_name.no_ldap = False

def migrate(old_session, new_session):
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

	if get_name.no_ldap:
		print "No LDAP"
	if get_name.no_name:
		print "No displayName in LDAP - {}: {}".format(
			len(get_name.no_name),  ', '.join(sorted(get_name.no_name))
		)
	if get_name.unlisted:
		print "Not listed in LDAP - {}: {}"    .format(
			len(get_name.unlisted), ', '.join(sorted(get_name.unlisted))
		)


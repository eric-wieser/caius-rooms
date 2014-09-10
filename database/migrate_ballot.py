import db
import orm
import olddb
import re

db.init('dev')

new_session = db.Session()
old_session = olddb.Session()

for old_ballot in old_session.query(olddb.orm.accom_guide_ballot):
	if '4th' in old_ballot.description:
		ballot_type = '4th'
	elif 'undergrad' in old_ballot.description:
		ballot_type = 'ugrad'
	elif 'grad' in old_ballot.description:
		ballot_type = 'grad'
	else:
		ballot_type = 'ugrad'

	ballot = orm.Ballot(
		id=old_ballot.id,
		opens_at=old_ballot.fromDate,
		closes_at=old_ballot.toDate,
		type=ballot_type
	)

	print old_ballot.toDate - old_ballot.fromDate

	new_session.add(ballot)

new_session.commit()
import db
import orm
import olddb
from sqlalchemy.orm.exc import NoResultFound, MultipleResultsFound
import migrate_utils as mu

db.init('dev')

new_session = db.Session()
old_session = olddb.Session()

ugrad = orm.BallotType(name='Undergraduate')
fourth = orm.BallotType(name='4th year')
graduate = orm.BallotType(name='Graduate')
test1 = orm.BallotType(name='Test 1')
test2 = orm.BallotType(name='Test 2')

new_session.add_all([ugrad, fourth, graduate, test1, test2])

for old_ballot in old_session.query(olddb.orm.accom_guide_ballot):
	desc = old_ballot.description.lower()
	if 'test' in desc:
		ballot_type = test2 if 'under' in desc else test1
	elif '4th' in desc:
		ballot_type = fourth
	elif 'undergrad' in desc:
		ballot_type = ugrad
	elif 'grad' in desc:
		ballot_type = graduate
	else:
		ballot_type = ugrad

	ballot_season = mu.get_ballot_season(new_session, old_ballot.toDate.year)

	ballot = orm.BallotEvent(
		id=old_ballot.id,
		opens_at=old_ballot.fromDate,
		closes_at=old_ballot.toDate,
		type=ballot_type,
		season=ballot_season
	)

	new_session.add(ballot)

new_session.commit()
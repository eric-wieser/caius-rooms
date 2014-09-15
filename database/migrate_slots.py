import db
import orm
import olddb

db.init('dev')

new_session = db.Session()
old_session = olddb.Session()

for slot in old_session.query(olddb.orm.accom_guide_slot):
	crsid = slot.person.lower()
	ballot_id = slot.ballot

	s = orm.BallotSlot(
		person=new_session.query(orm.Person).filter_by(crsid=crsid).one(),
		event=new_session.query(orm.BallotEvent).filter_by(id=ballot_id).one(),
		time=slot.time
	)
	new_session.add(s)

new_session.commit()

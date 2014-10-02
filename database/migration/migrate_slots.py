import orm
import olddb

def migrate(old_session, new_session):
	for slot in old_session.query(olddb.orm.accom_guide_slot):
		crsid = slot.person.lower()
		ballot_id = slot.ballot

		s = orm.BallotSlot(
			person=new_session.query(orm.Person).filter_by(crsid=crsid).one(),
			event=new_session.query(orm.BallotEvent).filter_by(id=ballot_id).one(),
			time=slot.time
		)
		new_session.add(s)

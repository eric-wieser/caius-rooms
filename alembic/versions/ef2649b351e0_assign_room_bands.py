"""assign room bands

Revision ID: ef2649b351e0
Revises: ed2884b09601
Create Date: 2016-02-14 15:35:40.523000

"""

# revision identifiers, used by Alembic.
revision = 'ef2649b351e0'
down_revision = 'ed2884b09601'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa
import itertools
from sqlalchemy.orm import sessionmaker
Session = sessionmaker()

def powerset(iterable):
    "powerset([1,2,3]) --> () (1,) (2,) (3,) (1,2) (1,3) (2,3) (1,2,3)"
    s = list(iterable)
    return itertools.chain.from_iterable(itertools.combinations(s, r) for r in range(len(s)+1))


def upgrade(engine_name):
    globals()["upgrade_%s" % engine_name]()


def downgrade(engine_name):
    globals()["downgrade_%s" % engine_name]()





def upgrade_live():

    # careful!
    import database.orm as m

    s = Session(bind=op.get_bind())

    season = s.query(m.BallotSeason).get(2015)

    bands = s.query(m.RoomBandPrice).filter_by(season=season).all()
    modifiers = s.query(m.RoomBandModifierPrice).filter_by(season=season).all()

    trials = sorted([
        (b.rent - sum(m.discount for m in ms), b, ms)
        for b in bands
        for ms in powerset(modifiers)
    ])

    print "Trying rents:\n\t{}".format('\n\t'.join("{} = {} - {}".format(*t) for t in trials))

    def update_listing(listing):
        for trial, b, ms in trials:
            if trial == listing.rent:
                listing.band = b.band
                listing.modifiers = {m.modifier for m in ms}
                return
        else:
            print "No rent matches {}, for {}.".format(listing.rent, listing.room)

    for listing in season.room_listings:
        update_listing(listing)


def downgrade_live():
    pass


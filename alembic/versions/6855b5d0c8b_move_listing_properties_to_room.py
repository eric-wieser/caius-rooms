"""move listing properties to room

Revision ID: 6855b5d0c8b
Revises: 
Create Date: 2015-02-10 17:07:29.158000

"""

# revision identifiers, used by Alembic.
revision = '6855b5d0c8b'
down_revision = None
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa


def upgrade(engine_name):
    globals()["upgrade_%s" % engine_name]()


def downgrade(engine_name):
    globals()["downgrade_%s" % engine_name]()


from sqlalchemy.orm import sessionmaker, Session as BaseSession, relationship

Session = sessionmaker()

def upgrade_live():

    old_bools = (
        'has_eduroam',
        'has_ethernet',
        'has_piano',
        'has_uniofcam',
        'has_washbasin')

    ### commands auto generated by Alembic - please adjust! ###
    op.add_column('rooms', sa.Column('has_eduroam', sa.Boolean(), nullable=True))
    op.add_column('rooms', sa.Column('has_ethernet', sa.Boolean(), nullable=True))
    op.add_column('rooms', sa.Column('has_piano', sa.Boolean(), nullable=True))
    op.add_column('rooms', sa.Column('has_uniofcam', sa.Boolean(), nullable=True))
    op.add_column('rooms', sa.Column('has_washbasin', sa.Boolean(), nullable=True))


    conn = op.get_bind()

    # this is a terrible idea, because the ORM is not synced with the db!
    import database.orm as m
    for b in old_bools:
        setattr(m.RoomListing, b, sa.Column(sa.Boolean()))

    s = Session(bind=conn)
    ran = 0
    for r in s.query(m.Room):
        for l in r.listings:
            for b in old_bools:
                v = getattr(l, b)
                if v is not None and getattr(r, b) is None:
                    setattr(r, b, v)
                    ran += 1

    assert ran > 0

    s.commit()

    op.drop_column('room_listings', 'has_eduroam')
    op.drop_column('room_listings', 'has_piano')
    op.drop_column('room_listings', 'has_washbasin')
    op.drop_column('room_listings', 'has_uniofcam')
    op.drop_column('room_listings', 'has_ethernet')
    ### end Alembic commands ###


def downgrade_live():
    ### commands auto generated by Alembic - please adjust! ###
    op.drop_column('rooms', 'has_washbasin')
    op.drop_column('rooms', 'has_uniofcam')
    op.drop_column('rooms', 'has_piano')
    op.drop_column('rooms', 'has_ethernet')
    op.drop_column('rooms', 'has_eduroam')
    op.add_column('room_listings', sa.Column('has_ethernet', sa.BOOLEAN(), autoincrement=False, nullable=True))
    op.add_column('room_listings', sa.Column('has_uniofcam', sa.BOOLEAN(), autoincrement=False, nullable=True))
    op.add_column('room_listings', sa.Column('has_washbasin', sa.BOOLEAN(), autoincrement=False, nullable=True))
    op.add_column('room_listings', sa.Column('has_piano', sa.BOOLEAN(), autoincrement=False, nullable=True))
    op.add_column('room_listings', sa.Column('has_eduroam', sa.BOOLEAN(), autoincrement=False, nullable=True))
    ### end Alembic commands ###


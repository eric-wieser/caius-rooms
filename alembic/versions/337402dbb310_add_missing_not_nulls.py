"""add missing not nulls

Revision ID: 337402dbb310
Revises: 3049ba88e64a
Create Date: 2015-02-25 20:31:08.922000

"""

# revision identifiers, used by Alembic.
revision = '337402dbb310'
down_revision = '3049ba88e64a'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa


def upgrade(engine_name):
    globals()["upgrade_%s" % engine_name]()


def downgrade(engine_name):
    globals()["downgrade_%s" % engine_name]()





def upgrade_live():
    ### commands auto generated by Alembic - please adjust! ###
    op.alter_column('room_listing_audiences', 'ballot_type_id',
               existing_type=sa.INTEGER(),
               nullable=False)
    op.alter_column('room_listing_audiences', 'room_listing_id',
               existing_type=sa.INTEGER(),
               nullable=False)
    op.alter_column('room_listings', 'ballot_season_id',
               existing_type=sa.INTEGER(),
               nullable=False)
    op.alter_column('room_listings', 'room_id',
               existing_type=sa.INTEGER(),
               nullable=False)
    ### end Alembic commands ###


def downgrade_live():
    ### commands auto generated by Alembic - please adjust! ###
    op.alter_column('room_listings', 'room_id',
               existing_type=sa.INTEGER(),
               nullable=True)
    op.alter_column('room_listings', 'ballot_season_id',
               existing_type=sa.INTEGER(),
               nullable=True)
    op.alter_column('room_listing_audiences', 'room_listing_id',
               existing_type=sa.INTEGER(),
               nullable=True)
    op.alter_column('room_listing_audiences', 'ballot_type_id',
               existing_type=sa.INTEGER(),
               nullable=True)
    ### end Alembic commands ###


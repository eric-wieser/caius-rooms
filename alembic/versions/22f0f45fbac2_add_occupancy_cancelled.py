"""Add Occupancy.cancelled

Revision ID: 22f0f45fbac2
Revises: 12533b2f17e5
Create Date: 2015-07-12 20:40:06.238000

"""

# revision identifiers, used by Alembic.
revision = '22f0f45fbac2'
down_revision = '12533b2f17e5'
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
    op.add_column('occupancies', sa.Column('cancelled', sa.Boolean(), nullable=True))
    occupancies = sa.sql.table('occupancies', sa.sql.column('cancelled'))
    op.execute(occupancies.update().values(cancelled=False))
    op.alter_column('occupancies', 'cancelled', nullable=False)
    ### end Alembic commands ###


def downgrade_live():
    ### commands auto generated by Alembic - please adjust! ###
    op.add_column('rooms', sa.Column('is_suite', sa.BOOLEAN(), autoincrement=False, nullable=True))
    ### end Alembic commands ###

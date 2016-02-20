"""rename cluster to place

Revision ID: 06dff4fbb0d4
Revises: 22f0f45fbac2
Create Date: 2016-02-09 21:26:12.543000

"""

# revision identifiers, used by Alembic.
revision = '06dff4fbb0d4'
down_revision = '22f0f45fbac2'
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
    op.rename_table('clusters', 'places')
    op.execute('alter type cluster_type rename to place_type')
    ### end Alembic commands ###


def downgrade_live():
    ### commands auto generated by Alembic - please adjust! ###
    op.execute('alter type place_type rename to cluster_type')
    op.rename_table('places', 'clusters')
    ### end Alembic commands ###

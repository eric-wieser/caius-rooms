"""Add editor field to reviews

Revision ID: 12533b2f17e5
Revises: 337402dbb310
Create Date: 2015-06-07 19:21:11.379000

"""

# revision identifiers, used by Alembic.
revision = '12533b2f17e5'
down_revision = '337402dbb310'
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
    op.add_column('reviews', sa.Column('hidden', sa.Boolean(), nullable=True, default=False))
    reviews = sa.sql.table('reviews', sa.sql.column('hidden'))
    op.execute(reviews.update().values(hidden=False))
    op.alter_column('reviews', 'hidden', nullable=False)

    op.add_column('reviews', sa.Column('editor_id', sa.String(length=10), nullable=True))
    op.create_foreign_key(None, 'reviews', 'people', ['editor_id'], ['crsid'])
    ### end Alembic commands ###


def downgrade_live():
    ### commands auto generated by Alembic - please adjust! ###
    op.drop_column('reviews', 'hidden')
    op.drop_column('reviews', 'editor_id')
    ### end Alembic commands ###


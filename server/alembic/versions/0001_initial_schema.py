"""Initial schema for existing ClassApp data.

The existing schema.sql remains the source-compatible bootstrap for local
development. This revision is intentionally additive and can be stamped after
the current database has been verified.
"""

revision = "0001_initial_schema"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass

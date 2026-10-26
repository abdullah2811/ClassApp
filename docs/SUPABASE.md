# Supabase setup

Use the Supabase **direct or pooler URI** as `DATABASE_URL` and keep SSL
enabled according to the URI supplied by Supabase. Apply
`server/schema.sql` to an empty database for the current compatibility
schema, or stamp an existing compatible database with Alembic after review.
Back up the database before applying migrations.

The schema includes users, classrooms, memberships, routines, tasks, bus
schedules, custom schedules, notes, personal modifications, alarms, and
refresh-token storage.

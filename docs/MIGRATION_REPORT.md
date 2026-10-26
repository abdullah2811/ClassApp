# Migration report

## Baseline

The repository began as a Flutter app with all screens in one
[`lib/main.dart`](../lib/main.dart), local token storage in
`SharedPreferences`, and an `ApiService` based on `http`. The UI uses
`StatefulWidget`, `setState`, and `FutureBuilder`; there is no centralized
state container. The backend is a single [`server/main.py`](../server/main.py)
with raw parameterized SQL through `asyncpg`. The PostgreSQL schema is in
[`server/schema.sql`](../server/schema.sql).

Existing API resources are users, classrooms/members, routines, tasks, bus
schedules, custom schedules, personal notes, personal modifications, and
alarms. Authorization is bearer JWT plus classroom role checks.

## Changes made

- Added environment-backed settings and a minimum secret length.
- Added `/health`, Railway configuration, Docker startup, `.env.example`,
  Alembic scaffolding, and refresh-token storage schema.
- Added request length validation for registration and JWT refresh endpoint.
- Replaced Flutter `http` and `SharedPreferences` token handling with Dio,
  secure storage, bearer injection, refresh retry, and logout clearing.
- Added generated Drift database with schema version 2, typed cache tables,
  migrations, and a connectivity-triggered sync queue.
- Kept the existing UI and all existing endpoint paths intact.

## Breaking changes and risks

1. Tokens are no longer read from `SharedPreferences`; users sign in once
   after upgrading.
2. `API_BASE_URL` must be supplied for non-emulator environments.
3. The backend compatibility routes still use raw `asyncpg`; SQLAlchemy
   repositories and complete Alembic ownership remain the next migration
   step.
4. The repository has no Android runner directory, so release build validation
   cannot run until `flutter create .` generates it.
5. Offline reads have the database foundation, but feature repositories still
   need to adopt cache-first reads before offline behavior is user-visible.

## Implementation tasks

- Extract backend schemas, repositories, dependencies, and routers from the
  compatibility module.
- Add persisted, revocable refresh tokens and rotation/reuse detection.
- Add Drift DAOs and cache-first repositories for every existing screen.
- Add attendance/notices server resources before exposing those local tables.
- Generate Android runner/signing configuration in a dedicated release branch.

# Smart Class

Smart Class is a Flutter application backed by FastAPI and PostgreSQL. The
current UI and API routes are preserved while the runtime is being migrated to
an offline-first architecture.

## Current architecture

- Flutter UI: [`lib/main.dart`](lib/main.dart) currently contains auth,
  classroom, routine, task, bus, event, and notes screens and uses `setState`
  with `FutureBuilder`.
- API layer: [`lib/services/api_service.dart`](lib/services/api_service.dart)
  centralizes Dio requests. Access and refresh tokens are stored only in
  `flutter_secure_storage`.
- Local data foundation: [`lib/core/storage/app_database.dart`](lib/core/storage/app_database.dart)
  defines typed Drift tables for users, classrooms, routines, attendance,
  notices, tasks, and the sync queue.
- Backend compatibility layer: [`server/main.py`](server/main.py) still owns
  the existing routes and raw SQL so no working feature is removed.
- Backend production seams: [`server/app/`](server/app/) provides settings,
  CORS, and health infrastructure; Alembic is configured in
  [`server/alembic/`](server/alembic/).

## Development

```bash
flutter pub get
dart run build_runner build
flutter analyze
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

```bash
cd server
copy .env.example .env
# Set DATABASE_URL and a random SECRET_KEY (at least 32 characters).
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## Migration status and breaking changes

The app remains backward-compatible with the existing JSON endpoints. Token
storage changed from `SharedPreferences` to secure storage; existing users
must sign in once after upgrading. The API base URL is now supplied with
`API_BASE_URL`; Android emulator development uses `http://10.0.2.2:8000`,
while production must use HTTPS.

The Drift cache is additive and currently provides the schema and queue
primitives. Feature repositories and server-side mutation endpoints should be
wired one feature at a time before enabling offline writes in production.

## Deployment

See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md), [`docs/SUPABASE.md`](docs/SUPABASE.md),
[`docs/FLUTTER_BUILD.md`](docs/FLUTTER_BUILD.md), and
[`docs/OFFLINE_SYNC.md`](docs/OFFLINE_SYNC.md).

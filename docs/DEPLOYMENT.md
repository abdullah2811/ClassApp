# Railway deployment

1. Create a Supabase project and copy its pooled PostgreSQL connection string.
2. Create a Railway service from this repository and set the root directory to
   the repository root.
3. Set `DATABASE_URL`, `SECRET_KEY`, `ACCESS_TOKEN_EXPIRE_MINUTES`,
   `REFRESH_TOKEN_EXPIRE_DAYS`, `ENVIRONMENT=production`, and optional
   `CORS_ORIGINS` in Railway variables. Never commit these values.
4. Railway uses `server/Dockerfile` and exposes `/health`.
5. Run Alembic from the service shell before serving a migrated database:
   `alembic upgrade head`.

The included `railway.json` configures Docker builds, health checks, and
restart retries. Verify `/health`, registration, login, and an authenticated
classroom request after deployment.

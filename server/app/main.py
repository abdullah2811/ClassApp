from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .core.config import get_settings
from main import app as legacy_app

settings = get_settings()
app = legacy_app
app.title = "Smart Class API"
app.version = "2.0.0"

if settings.cors_origin_list:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )


@app.get("/health", tags=["operations"])
async def health() -> dict[str, str]:
    return {"status": "ok", "environment": settings.environment}

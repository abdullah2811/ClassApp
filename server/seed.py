"""Optional, idempotent development seed entry point.

Production data should be created through the API. This script deliberately
does not contain credentials or sample passwords.
"""

import asyncio

import asyncpg

from app.core.config import get_settings


async def main() -> None:
    settings = get_settings()
    connection = await asyncpg.connect(settings.database_url)
    try:
        await connection.execute("SELECT 1")
        print("Database is reachable; no demo records were inserted.")
    finally:
        await connection.close()


if __name__ == "__main__":
    asyncio.run(main())

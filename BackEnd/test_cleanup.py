"""Manual cleanup test — delete after use."""
import asyncio
from app.infrastructure.jobs.cleanup_jobs import (
    cleanup_appointments,
    cleanup_notifications,
    cleanup_orders,
    cleanup_otps,
)


async def main():
    print("Running cleanup jobs...")
    await cleanup_notifications()
    await cleanup_appointments()
    await cleanup_orders()
    await cleanup_otps()
    print("✅ All cleanup jobs executed.")


asyncio.run(main())
"""
APScheduler setup.

All cleanup jobs run once daily at quiet hours (UTC):
    03:00  notifications
    03:15  appointments (cancelled/rejected)
    03:30  OTPs
    03:45  orders (cancelled/rejected)

Uses AsyncIOScheduler so jobs integrate with FastAPI's event loop.
"""
import logging

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from app.infrastructure.jobs.cleanup_jobs import (
    cleanup_appointments,
    cleanup_notifications,
    cleanup_orders,
    cleanup_otps,
)

logger = logging.getLogger(__name__)

_scheduler: AsyncIOScheduler | None = None


def start_scheduler() -> AsyncIOScheduler:
    """Start the scheduler and register all periodic jobs."""
    global _scheduler
    if _scheduler is not None:
        return _scheduler

    _scheduler = AsyncIOScheduler(timezone="UTC")

    # 03:00 UTC — notifications
    _scheduler.add_job(
        cleanup_notifications,
        CronTrigger(hour=3, minute=0),
        id="cleanup_notifications",
        replace_existing=True,
        misfire_grace_time=3600,
    )

    # 03:15 UTC — appointments
    _scheduler.add_job(
        cleanup_appointments,
        CronTrigger(hour=3, minute=15),
        id="cleanup_appointments",
        replace_existing=True,
        misfire_grace_time=3600,
    )

    # 03:30 UTC — OTPs
    _scheduler.add_job(
        cleanup_otps,
        CronTrigger(hour=3, minute=30),
        id="cleanup_otps",
        replace_existing=True,
        misfire_grace_time=3600,
    )

    # 03:45 UTC — orders
    _scheduler.add_job(
        cleanup_orders,
        CronTrigger(hour=3, minute=45),
        id="cleanup_orders",
        replace_existing=True,
        misfire_grace_time=3600,
    )

    _scheduler.start()
    logger.info(
        "Scheduler started with %d jobs: %s",
        len(_scheduler.get_jobs()),
        [j.id for j in _scheduler.get_jobs()],
    )
    return _scheduler


def shutdown_scheduler() -> None:
    global _scheduler
    if _scheduler is not None:
        _scheduler.shutdown(wait=False)
        _scheduler = None
        logger.info("Scheduler stopped.")
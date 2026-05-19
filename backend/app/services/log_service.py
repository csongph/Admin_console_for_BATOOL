from datetime import datetime, timedelta
from typing import List

from app.schemas.schemas import LogEntry

# Mock log data — replace with DB queries when ready
_MOCK_LOGS: List[LogEntry] = [
    LogEntry(
        id=1,
        timestamp=(datetime.utcnow() - timedelta(minutes=30)).isoformat(),
        level="INFO",
        message="Application started successfully",
    ),
    LogEntry(
        id=2,
        timestamp=(datetime.utcnow() - timedelta(minutes=25)).isoformat(),
        level="INFO",
        message="Database connection established",
    ),
    LogEntry(
        id=3,
        timestamp=(datetime.utcnow() - timedelta(minutes=15)).isoformat(),
        level="WARNING",
        message="High memory usage detected: 82%",
    ),
    LogEntry(
        id=4,
        timestamp=(datetime.utcnow() - timedelta(minutes=10)).isoformat(),
        level="ERROR",
        message="Failed to sync with external service: timeout",
    ),
    LogEntry(
        id=5,
        timestamp=(datetime.utcnow() - timedelta(minutes=2)).isoformat(),
        level="INFO",
        message="Scheduled task completed in 1.2s",
    ),
]


def get_all_logs() -> List[LogEntry]:
    return _MOCK_LOGS

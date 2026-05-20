from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import asyncio
import logging

from app.core.config import settings
from app.routers import auth, logs, system, health, mappings, databases, sessions
from app.routers.presence import router as presence_router, _evict_stale
from app.middleware.logging_middleware import LoggingMiddleware
from app.db.database import init_db

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="BA Tool API",
    version="1.0.0",
    # ซ่อน docs ใน production
    docs_url="/docs" if settings.ENVIRONMENT != "production" else None,
    redoc_url="/redoc" if settings.ENVIRONMENT != "production" else None,
)

# ── CORS: ใช้ whitelist จาก settings — ไม่เปิด * ──────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_origin_regex=settings.ALLOWED_ORIGIN_REGEX,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

app.add_middleware(LoggingMiddleware)


@app.on_event("startup")
async def on_startup():
    await init_db()
    logger.info("Database tables initialized")
    asyncio.create_task(_evict_stale())
    logger.info("Presence heartbeat monitor started")


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    # ใน production ไม่แสดง error detail ให้ client เห็น
    message = str(exc) if settings.ENVIRONMENT != "production" else "Internal server error"
    return JSONResponse(
        status_code=500,
        content={"success": False, "message": message},
    )


app.include_router(health.router,    prefix="/api")
app.include_router(auth.router,      prefix="/api/auth")
app.include_router(logs.router,      prefix="/api")
app.include_router(system.router,    prefix="/api/system")
app.include_router(mappings.router,  prefix="/api")
app.include_router(databases.router, prefix="/api")
app.include_router(sessions.router,  prefix="/api")
app.include_router(presence_router)

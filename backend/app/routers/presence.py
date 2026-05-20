"""
app/routers/presence.py
───────────────────────
Real-time online user tracking via FastAPI WebSocket.

Connections:
  ws://host/ws/presence          ← user pages connect here
  ws://host/ws/presence/admin    ← admin console connects here
"""

import json
import uuid
import asyncio
from datetime import datetime, timezone
from fastapi import APIRouter, WebSocket, WebSocketDisconnect

router = APIRouter(tags=["Presence"])

# ── In-memory store ───────────────────────────────────────────────────────────
# { client_id: { user_id, page, user_agent, connected_at, last_ping } }
online_users: dict[str, dict] = {}

# Admin WebSocket connections listening for updates
admin_connections: set[WebSocket] = set()

HEARTBEAT_INTERVAL = 30   # seconds — client must ping within this window
HEARTBEAT_TIMEOUT  = 90   # seconds — evict if no ping received


# ── Helpers ───────────────────────────────────────────────────────────────────

def _serialize_users() -> list[dict]:
    now = datetime.now(timezone.utc).timestamp()
    return [
        {**u, "idle_seconds": int(now - u["last_ping"])}
        for u in online_users.values()
    ]


async def _broadcast_to_admins(event: str, payload: dict) -> None:
    dead: set[WebSocket] = set()
    message = json.dumps({"event": event, **payload})
    for ws in admin_connections:
        try:
            await ws.send_text(message)
        except Exception:
            dead.add(ws)
    admin_connections.difference_update(dead)


async def _evict_stale() -> None:
    """Background task: remove users whose last_ping is too old."""
    while True:
        await asyncio.sleep(HEARTBEAT_INTERVAL)
        now = datetime.now(timezone.utc).timestamp()
        stale = [
            cid for cid, u in online_users.items()
            if now - u["last_ping"] > HEARTBEAT_TIMEOUT
        ]
        for cid in stale:
            online_users.pop(cid, None)
        if stale:
            await _broadcast_to_admins(
                "update_online_users",
                {"users": _serialize_users(), "total": len(online_users)},
            )


# ── User WebSocket endpoint ───────────────────────────────────────────────────

@router.websocket("/ws/presence")
async def user_presence(ws: WebSocket):
    await ws.accept()
    client_id = str(uuid.uuid4())

    try:
        # First message must be "user_online" with user info
        raw = await asyncio.wait_for(ws.receive_text(), timeout=10)
        data = json.loads(raw)

        if data.get("event") != "user_online":
            await ws.close(code=4000)
            return

        now = datetime.now(timezone.utc)
        online_users[client_id] = {
            "client_id":    client_id,
            "user_id":      data.get("user_id"),          # null for guests
            "page":         data.get("page", "/"),
            "user_agent":   data.get("user_agent", ""),
            "connected_at": now.isoformat(),
            "last_ping":    now.timestamp(),
        }

        await _broadcast_to_admins(
            "update_online_users",
            {"users": _serialize_users(), "total": len(online_users)},
        )

        # Keep connection alive — handle pings and page changes
        while True:
            raw = await ws.receive_text()
            msg = json.loads(raw)
            event = msg.get("event")

            if event == "ping":
                online_users[client_id]["last_ping"] = datetime.now(timezone.utc).timestamp()
                await ws.send_text(json.dumps({"event": "pong"}))

            elif event == "page_change":
                online_users[client_id]["page"] = msg.get("page", "/")
                online_users[client_id]["last_ping"] = datetime.now(timezone.utc).timestamp()
                await _broadcast_to_admins(
                    "update_online_users",
                    {"users": _serialize_users(), "total": len(online_users)},
                )

    except (WebSocketDisconnect, asyncio.TimeoutError):
        pass
    except Exception:
        pass
    finally:
        online_users.pop(client_id, None)
        await _broadcast_to_admins(
            "update_online_users",
            {"users": _serialize_users(), "total": len(online_users)},
        )


# ── Admin WebSocket endpoint ──────────────────────────────────────────────────

@router.websocket("/ws/presence/admin")
async def admin_presence(ws: WebSocket):
    await ws.accept()
    admin_connections.add(ws)

    # Send current snapshot immediately on connect
    await ws.send_text(json.dumps({
        "event": "update_online_users",
        "users": _serialize_users(),
        "total": len(online_users),
    }))

    try:
        while True:
            # Keep connection alive; admin can send "ping"
            raw = await ws.receive_text()
            if json.loads(raw).get("event") == "ping":
                await ws.send_text(json.dumps({"event": "pong"}))
    except (WebSocketDisconnect, Exception):
        pass
    finally:
        admin_connections.discard(ws)


# ── REST: snapshot for non-WS consumers ──────────────────────────────────────

@router.get("/api/presence")
async def get_presence():
    return {
        "success": True,
        "total":   len(online_users),
        "users":   _serialize_users(),
    }
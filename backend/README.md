# BA Tool — Backend API

FastAPI backend for the BA Tool Admin Console. Deployable on [Render](https://render.com) out of the box.

---

## Project Structure

```
backend/
├── app/
│   ├── main.py              # App entry point, middleware, routers
│   ├── core/
│   │   ├── config.py        # Settings from .env
│   │   └── security.py      # JWT + password hashing
│   ├── routers/             # Route handlers
│   ├── services/            # Business logic
│   ├── schemas/             # Pydantic request/response models
│   ├── database/            # SQLAlchemy session
│   └── middleware/          # Logging middleware
├── requirements.txt
├── .env.example
└── render.yaml
```

---

## Local Setup

**1. Clone and enter the backend folder**
```bash
cd backend
```

**2. Create a virtual environment**
```bash
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
```

**3. Install dependencies**
```bash
pip install -r requirements.txt
```

**4. Configure environment**
```bash
cp .env.example .env
# Edit .env with your values
```

**5. Run the server**
```bash
uvicorn app.main:app --reload
```

API will be available at: `http://localhost:8000`  
Interactive docs: `http://localhost:8000/docs`

---

## Deploy on Render

1. Push this repo to GitHub
2. Go to [render.com](https://render.com) → **New** → **Blueprint**
3. Connect your repo — Render will detect `render.yaml` automatically
4. Set `SECRET_KEY` in the Render dashboard (Environment tab)
5. Deploy ✓

The `render.yaml` provisions a PostgreSQL database and links `DATABASE_URL` automatically.

---

## API Reference

### Health Check
```
GET /api/health
```
```json
{ "success": true, "message": "API is running" }
```

### Login
```
POST /api/auth/login
Content-Type: application/json

{ "username": "admin", "password": "admin123" }
```
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "<jwt>",
    "token_type": "bearer",
    "expires_in": 3600
  }
}
```

### Get Logs *(requires token)*
```
GET /api/logs
Authorization: Bearer <token>
```

### System Control *(requires token)*
```
GET  /api/system/status
POST /api/system/start
POST /api/system/stop
Authorization: Bearer <token>
```

---

## Connecting from Frontend (fetch)

```javascript
// 1. Login
const res = await fetch("https://your-api.onrender.com/api/auth/login", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ username: "admin", password: "admin123" }),
});
const { data } = await res.json();
const token = data.access_token;
localStorage.setItem("token", token);

// 2. Authenticated request
const logs = await fetch("https://your-api.onrender.com/api/logs", {
  headers: { Authorization: `Bearer ${token}` },
}).then((r) => r.json());
```

---

## Adding Your Vercel Frontend to CORS

In `app/core/config.py`, add your Vercel URL to `ALLOWED_ORIGINS`:

```python
ALLOWED_ORIGINS: List[str] = [
    "http://localhost:3000",
    "https://your-app.vercel.app",  # ← add this
]
```

---

## Default Credentials

| Username | Password  |
|----------|-----------|
| admin    | admin123  |

> ⚠️ Change these before going to production by updating `RS` in `services/auth_service.py` or switching to a database-backed user model.

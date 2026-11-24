# AtClam backend

FastAPI service for the Flutter app. It owns the PostgreSQL database, accounts, classes, attendance sessions, face recognition and blink liveness.

## Start

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # optional
python3 -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

- Health: `GET /health`
- Swagger UI: `http://localhost:8000/docs`
- CORS is open so a phone/browser client can call the API.

The SFace ONNX model lives in `models/`. If missing, it is downloaded from OpenCV Zoo during startup.

## Configuration

Copy `.env.example` to `.env` to override:

| Variable | Purpose |
| --- | --- |
| `JWT_SECRET` | HMAC signing secret; generated once in `data/.jwt_secret` if omitted |
| `TOKEN_HOURS` | Login token lifetime (default 168) |
| `HOST`, `PORT` | Uvicorn bind address |
| `DB_HOST`, `DB_PORT` | PostgreSQL host/port (default `localhost:5432`) |
| `DB_NAME` | Database name (default `AtClam`) |
| `DB_USER`, `DB_PASSWORD` | PostgreSQL credentials |

Recognition, voting and liveness thresholds are in `config.py`.

## Authentication

- `POST /auth/login` accepts email or username. Legacy Flask password hashes still work.
- `POST /auth/register` creates student or instructor accounts (`role` field, optional `username`); this is the old signup form.
- `POST /admin/instructors` creates instructor accounts (admin only). `POST /admin/users` creates either role with a chosen username (admin only).
- Send the returned token as `Authorization: Bearer <access_token>`.
- `python3 seed_admin.py "Name" admin@school.edu "password"` creates another admin.

## Main endpoints

| Area | Endpoints |
| --- | --- |
| Auth | `/auth/login`, `/auth/register`, `/auth/me`, `/auth/profile`, `/auth/change-password`, `/auth/photos`, `/auth/avatar` |
| Admin | `/admin/users`, `/admin/users/{id}/active`, `/admin/instructors`, `/admin/classes` |
| Classes | `/classes`, `/classes/join`, `/classes/{id}/students`, `/classes/{id}/announcements` |
| Attendance | `/attendance/session`, `/attendance/session/start`, `/attendance/session/end`, `/attendance/frame`, `/attendance/class/{id}`, `/attendance/export/{sid}` |
| Notifications | `/notifications` |

Two binary payloads use base64 JSON because `python-multipart` is not required:

```json
{"image": "data:image/jpeg;base64,...."}
```
for `POST /auth/avatar` and `POST /attendance/frame`, and:

```json
{"photos": ["data:image/jpeg;base64,...", "...", "..."]}
```
for `POST /auth/photos` (exactly 3 face photos).

## Scanning flow

1. `POST /attendance/session/start` with `{"class_id": "..."}`.
2. The phone posts JPEG frames every ~550 ms to `POST /attendance/frame`.
3. MediaPipe finds faces, SFace embeddings identify enrolled students, a 3-of-5 vote stabilises identity and a blink check blocks still photos.
4. `POST /attendance/session/end` finalises the session; unseen students become absent unless excused.

Recognition is tracked per instructor id, so two phones can scan independently.

## Storage

All attendance data lives in **PostgreSQL** (database `AtClam` by default). `init_db()` in `db.py` creates the tables on startup and seeds an admin if none exists. `db.py` presents the old SQLite-style `?` placeholders / `lastrowid` interface to the rest of the code, backed by `psycopg` 3.

To move the old SQLite data into PostgreSQL once:

```bash
python3 tools/migrate_sqlite_to_pg.py
```

The old `data/attendance.db` is left untouched; the migration clears and refills the Postgres tables from it, so it is safe to re-run. Face crops and avatars are still written to `data/faces/` and `data/avatars/`.

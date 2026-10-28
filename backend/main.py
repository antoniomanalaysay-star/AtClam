from datetime import date
from typing import Optional

import bcrypt
import psycopg
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from db import get_connection

app = FastAPI(title="AtClam - Camera-based Classroom Attendance and Management System")


# ---------- helpers ----------
def rows_to_dicts(cur):
    cols = [c.name for c in cur.description]
    return [dict(zip(cols, row)) for row in cur.fetchall()]


def one_to_dict(cur):
    row = cur.fetchone()
    if row is None:
        return None
    return dict(zip([c.name for c in cur.description], row))


# ---------- request models ----------
class RegisterIn(BaseModel):
    name: str
    email: str
    password: str
    role: str = "student"
    school_id: Optional[str] = None


class LoginIn(BaseModel):
    email: str
    password: str


class SessionIn(BaseModel):
    class_id: int
    opened_by: int
    schedule_id: Optional[int] = None
    session_date: Optional[date] = None


class RecordIn(BaseModel):
    session_id: int
    student_id: int
    status: str = "present"
    method: str = "manual"
    confidence: Optional[float] = None


# ---------- F01: health ----------
@app.get("/health")
def health_check():
    return {"status": "ok"}


# ---------- F02, F03: users ----------
@app.get("/users")
def get_users():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, email, role FROM users ORDER BY id")
            return rows_to_dicts(cur)


@app.get("/users/{email}")
def get_user_by_email(email: str):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name, email, role FROM users WHERE email = %s",
                (email,),
            )
            user = one_to_dict(cur)
            if user is None:
                raise HTTPException(status_code=404, detail="User not found")
            return user


# ---------- F04: register ----------
@app.post("/register", status_code=201)
def register(data: RegisterIn):
    if data.role not in ("student", "instructor"):
        raise HTTPException(status_code=400, detail="Role must be student or instructor")

    hashed = bcrypt.hashpw(data.password.encode(), bcrypt.gensalt()).decode()

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM users WHERE email = %s", (data.email,))
            if cur.fetchone():
                raise HTTPException(status_code=409, detail="Email already registered")
            cur.execute(
                """
                INSERT INTO users
                    (school_id, name, email, password_hash, role, is_active, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, TRUE, now(), now())
                RETURNING id, name, email, role
                """,
                (data.school_id, data.name, data.email, hashed, data.role),
            )
            return one_to_dict(cur)


# ---------- F05: login ----------
@app.post("/login")
def login(data: LoginIn):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name, email, role, password_hash, is_active FROM users WHERE email = %s",
                (data.email,),
            )
            user = one_to_dict(cur)

    if user is None or not bcrypt.checkpw(
        data.password.encode(), user["password_hash"].encode()
    ):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if not user["is_active"]:
        raise HTTPException(status_code=403, detail="Account is inactive")

    return {
        "message": "Login successful",
        "user": {
            "id": user["id"],
            "name": user["name"],
            "email": user["email"],
            "role": user["role"],
        },
    }


# ---------- F06: classes ----------
@app.get("/classes")
def get_classes():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT c.id, c.code, c.name, c.section, c.school_year, c.semester,
                       u.name AS instructor
                FROM classes c
                JOIN users u ON u.id = c.instructor_id
                ORDER BY c.code
                """
            )
            return rows_to_dicts(cur)


# ---------- F07: open attendance session (instructor) ----------
@app.post("/attendance-sessions", status_code=201)
def open_attendance_session(data: SessionIn):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM classes WHERE id = %s", (data.class_id,))
            if cur.fetchone() is None:
                raise HTTPException(status_code=404, detail="Class not found")

            cur.execute("SELECT role FROM users WHERE id = %s", (data.opened_by,))
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status_code=404, detail="User not found")
            if row[0] not in ("instructor", "admin"):
                raise HTTPException(status_code=403, detail="Only instructors can open a session")

            cur.execute(
                """
                INSERT INTO attendance_sessions
                    (class_id, schedule_id, opened_by, session_date, opened_at, status)
                VALUES (%s, %s, %s, %s, now(), 'open')
                RETURNING id, class_id, schedule_id, opened_by, session_date, status
                """,
                (
                    data.class_id,
                    data.schedule_id,
                    data.opened_by,
                    data.session_date or date.today(),
                ),
            )
            return one_to_dict(cur)


# ---------- F08: record attendance (student) ----------
@app.post("/attendance-records", status_code=201)
def record_attendance(data: RecordIn):
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT 1 FROM attendance_sessions WHERE id = %s", (data.session_id,)
                )
                if cur.fetchone() is None:
                    raise HTTPException(status_code=404, detail="Session not found")

                cur.execute("SELECT role FROM users WHERE id = %s", (data.student_id,))
                row = cur.fetchone()
                if row is None:
                    raise HTTPException(status_code=404, detail="Student not found")
                if row[0] != "student":
                    raise HTTPException(status_code=403, detail="Only students can be marked")

                cur.execute(
                    """
                    INSERT INTO attendance_records
                        (session_id, student_id, status, method, confidence, marked_at)
                    VALUES (%s, %s, %s, %s, %s, now())
                    RETURNING id, session_id, student_id, status, method, confidence, marked_at
                    """,
                    (
                        data.session_id,
                        data.student_id,
                        data.status,
                        data.method,
                        data.confidence,
                    ),
                )
                return one_to_dict(cur)
    except psycopg.errors.UniqueViolation:
        raise HTTPException(status_code=409, detail="Attendance already recorded")
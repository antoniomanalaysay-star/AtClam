"""Administrator endpoints: accounts and classes."""
import time
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, field_validator

from auth import hash_password, require_role, validate_email, validate_password
from db import get_connection, get_user, user_public
from routes.classes import (ClassIn, class_public, create_class_record,
                            delete_class_record, update_class_record)

router = APIRouter(prefix="/admin", tags=["admin"])


class InstructorIn(BaseModel):
    name: str
    email: str
    password: str
    school_id: Optional[str] = None
    section: str = ""

    @field_validator("name")
    @classmethod
    def _name(cls, v):
        v = (v or "").strip()
        if not v:
            raise ValueError("Name is required")
        return v[:60]

    @field_validator("email")
    @classmethod
    def _email(cls, v):
        return validate_email(v)

    @field_validator("password")
    @classmethod
    def _password(cls, v):
        return validate_password(v)


class ActiveIn(BaseModel):
    is_active: bool


class UserIn(BaseModel):
    """Old admin form: create a student or instructor with a username."""
    full_name: str
    email: str
    role: str = "student"
    username: Optional[str] = None
    section: str = ""
    school_id: Optional[str] = None
    password: Optional[str] = None

    @field_validator("full_name")
    @classmethod
    def _name(cls, v):
        v = (v or "").strip()
        if not v:
            raise ValueError("Name is required")
        return v[:60]

    @field_validator("email")
    @classmethod
    def _email(cls, v):
        return validate_email(v)

    @field_validator("role")
    @classmethod
    def _role(cls, v):
        v = (v or "student").strip().lower()
        if v not in ("student", "instructor"):
            raise ValueError("Choose Student or Instructor")
        return v

    @field_validator("username")
    @classmethod
    def _username(cls, v):
        return (v or "").strip()[:40] or None

    @field_validator("password")
    @classmethod
    def _password(cls, v):
        if v and v.strip():
            return validate_password(v)
        return "Attendance123"   # same default as the old Flask admin form


class UserUpdateIn(BaseModel):
    name: str
    email: str
    role: str
    username: Optional[str] = None
    school_id: Optional[str] = None
    section: Optional[str] = None
    password: Optional[str] = None


@router.post("/instructors", status_code=201)
def create_instructor(data: InstructorIn, admin: dict = Depends(require_role("admin"))):
    try:
        with get_connection() as con, con:
            cur = con.execute(
                """INSERT INTO users(full_name,username,email,password_hash,role,
                                     school_id,section,created_at)
                   VALUES(?,?,?,?,'instructor',?,?,?)""",
                (data.name, uuid.uuid4().hex[:12], data.email,
                 hash_password(data.password), data.school_id or "",
                 data.section or "", time.time()),
            )
            row = con.execute("SELECT * FROM users WHERE id=?", (cur.lastrowid,)).fetchone()
    except Exception as e:
        if "UNIQUE" in str(e).upper():
            raise HTTPException(status_code=409, detail="That email is already registered.")
        raise
    return user_public(row)


@router.post("/users", status_code=201)
def create_user(data: UserIn, admin: dict = Depends(require_role("admin"))):
    username = data.username or data.email.split("@", 1)[0]
    password = data.password or "Attendance123"
    try:
        with get_connection() as con, con:
            if con.execute("SELECT 1 FROM users WHERE username=? COLLATE NOCASE",
                           (username,)).fetchone():
                raise HTTPException(status_code=409, detail="That username is already taken.")
            cur = con.execute(
                """INSERT INTO users(full_name,username,email,password_hash,role,
                                     school_id,section,created_at)
                   VALUES(?,?,?,?,?,?,?,?)""",
                (data.full_name, username, data.email, hash_password(password),
                 data.role, data.school_id or "", data.section or "", time.time()),
            )
            row = con.execute("SELECT * FROM users WHERE id=?", (cur.lastrowid,)).fetchone()
    except HTTPException:
        raise
    except Exception as e:
        if "UNIQUE" in str(e).upper():
            raise HTTPException(status_code=409, detail="That email is already registered.")
        raise
    return user_public(row)


@router.get("/users")
def list_users(
    role: Optional[str] = Query(None, pattern="^(admin|instructor|student)$"),
    admin: dict = Depends(require_role("admin")),
):
    with get_connection() as con:
        if role:
            rows = con.execute(
                "SELECT * FROM users WHERE role=? ORDER BY full_name", (role,)
            ).fetchall()
        else:
            rows = con.execute(
                "SELECT * FROM users WHERE role!='admin' ORDER BY role, full_name"
            ).fetchall()
    return [user_public(dict(r)) for r in rows]


@router.patch("/users/{user_id}/active")
def set_user_active(user_id: int, data: ActiveIn, admin: dict = Depends(require_role("admin"))):
    if user_id == admin["id"]:
        raise HTTPException(status_code=400, detail="You cannot deactivate your own account")
    target = get_user(user_id)
    if not target or target["role"] == "admin":
        raise HTTPException(status_code=404, detail="User not found")
    with get_connection() as con, con:
        con.execute("UPDATE users SET is_active=? WHERE id=?", (int(data.is_active), user_id))
    return user_public({**target, "is_active": int(data.is_active)})


@router.put("/users/{user_id}")
def update_user(user_id: int, data: UserUpdateIn, admin: dict = Depends(require_role("admin"))):
    target = get_user(user_id)
    if not target or target["role"] == "admin":
        raise HTTPException(status_code=404, detail="User not found")
    if data.role not in ("instructor", "student"):
        raise HTTPException(status_code=400, detail="Invalid role.")
    try:
        with get_connection() as con, con:
            username = (data.username or "").strip() or target["username"]
            con.execute(
                """UPDATE users SET full_name=?,username=?,email=?,role=?,school_id=?,section=?
                   WHERE id=?""",
                (data.name.strip()[:60], username[:40], data.email.strip().lower(),
                 data.role, data.school_id or "", data.section or "", user_id),
            )
            if data.password:
                con.execute("UPDATE users SET password_hash=? WHERE id=?",
                            (hash_password(validate_password(data.password)), user_id))
            if target.get("student_id"):
                con.execute("UPDATE students SET name=? WHERE id=?",
                            (data.name.strip()[:60], target["student_id"]))
    except Exception as e:
        if "UNIQUE" in str(e).upper():
            raise HTTPException(status_code=409, detail="That email is already registered.")
        if isinstance(e, ValueError):
            raise HTTPException(status_code=400, detail=str(e))
        raise
    from scanner import scanner
    scanner.refresh_people()
    return user_public(get_user(user_id))


@router.delete("/users/{user_id}")
def delete_user(user_id: int, admin: dict = Depends(require_role("admin"))):
    target = get_user(user_id)
    if not target or target["role"] == "admin":
        raise HTTPException(status_code=404, detail="User not found")
    with get_connection() as con, con:
        con.execute("DELETE FROM enrollments WHERE user_id=?", (user_id,))
        con.execute("DELETE FROM excuses WHERE user_id=?", (user_id,))
        con.execute("DELETE FROM announcements WHERE instructor_id=?", (user_id,))
        con.execute("DELETE FROM notifications WHERE user_id=?", (user_id,))
        if target.get("student_id"):
            pid = target["student_id"]
            con.execute("DELETE FROM attendance WHERE student_id=?", (pid,))
            con.execute("DELETE FROM students WHERE id=?", (pid,))
            from config import FACES
            (FACES / f"{pid}.jpg").unlink(missing_ok=True)
        con.execute("UPDATE classes SET instructor_id=NULL WHERE instructor_id=?", (user_id,))
        con.execute("DELETE FROM users WHERE id=?", (user_id,))
    from scanner import scanner
    scanner.refresh_people()
    return {"ok": True}


# ------------------------------------------------------------------- classes
@router.get("/classes")
def admin_classes(admin: dict = Depends(require_role("admin"))):
    with get_connection() as con:
        rows = con.execute(
            """SELECT c.*, u.full_name AS instructor_name FROM classes c
               LEFT JOIN users u ON u.id=c.instructor_id ORDER BY c.created_at DESC"""
        ).fetchall()
    return [class_public(dict(r)) for r in rows]


@router.post("/classes", status_code=201)
def admin_create_class(data: ClassIn, admin: dict = Depends(require_role("admin"))):
    return create_class_record(data, admin)


@router.put("/classes/{cid}")
def admin_update_class(cid: str, data: ClassIn, admin: dict = Depends(require_role("admin"))):
    return update_class_record(cid, data, admin)


@router.delete("/classes/{cid}")
def admin_delete_class(cid: str, admin: dict = Depends(require_role("admin"))):
    return delete_class_record(cid, admin)

"""Classes, enrollment, schedules and announcements."""
import re
import secrets
import time
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from auth import get_current_user, require_role
from attendance_state import can_manage, can_view
from db import get_class, get_connection, get_user, user_public
from notifications import notify

router = APIRouter(prefix="/classes", tags=["classes"])
TIME_RE = re.compile(r"^([01]?\d|2[0-3]):([0-5]\d)$")


def _time(value):
    value = (value or "").strip()
    return value if TIME_RE.fullmatch(value) else ""


def _code():
    with get_connection() as con:
        while True:
            code = secrets.token_hex(3).upper()
            if not con.execute("SELECT 1 FROM classes WHERE code=?", (code,)).fetchone():
                return code


def class_public(c):
    with get_connection() as con:
        count = con.execute(
            "SELECT COUNT(*) n FROM enrollments WHERE class_id=?", (c["id"],)
        ).fetchone()["n"]
    keys = ("id", "code", "name", "description", "section", "instructor_id",
            "instructor_name", "present_time", "late_time", "end_time", "created_at")
    return {k: c.get(k) for k in keys} | {"student_count": count}


class ClassIn(BaseModel):
    name: str
    description: str = ""
    section: str = "General"
    instructor_id: Optional[int] = None
    present_time: str = ""
    late_time: str = ""
    end_time: str = ""


class JoinIn(BaseModel):
    code: str


class AnnouncementIn(BaseModel):
    title: str
    body: str


def create_class_record(data: ClassIn, user):
    name = (data.name or "").strip()[:80]
    if not name:
        raise HTTPException(status_code=400, detail="Give the class a name.")
    instructor_id = data.instructor_id if user["role"] == "admin" else user["id"]
    if instructor_id:
        target = get_user(instructor_id)
        if not target or target["role"] != "instructor":
            raise HTTPException(status_code=400, detail="Choose a valid instructor.")
    times = (_time(data.present_time), _time(data.late_time), _time(data.end_time))
    if user["role"] == "instructor" and not all(times):
        raise HTTPException(
            status_code=400,
            detail="Set the Present, Late and End times for this class (HH:MM).",
        )
    cid = uuid.uuid4().hex[:8]
    with get_connection() as con, con:
        con.execute(
            """INSERT INTO classes(id,code,name,description,section,instructor_id,
                                    present_time,late_time,end_time,created_at)
               VALUES(?,?,?,?,?,?,?,?,?,?)""",
            (cid, _code(), name, (data.description or "").strip()[:500],
             (data.section or "General").strip()[:60], instructor_id,
             *times, time.time()),
        )
    return class_public(get_class(cid))


def update_class_record(cid, data: ClassIn, user):
    c = get_class(cid)
    if not c:
        raise HTTPException(status_code=404, detail="No such class.")
    if not can_manage(user, c):
        raise HTTPException(status_code=403, detail="You don't manage this class.")
    instructor_id = data.instructor_id if user["role"] == "admin" else c["instructor_id"]
    if instructor_id:
        target = get_user(instructor_id)
        if not target or target["role"] != "instructor":
            raise HTTPException(status_code=400, detail="Choose a valid instructor.")
    with get_connection() as con, con:
        con.execute(
            """UPDATE classes SET name=?,description=?,section=?,instructor_id=?,
                                  present_time=?,late_time=?,end_time=? WHERE id=?""",
            ((data.name or c["name"]).strip()[:80], (data.description or "").strip()[:500],
             (data.section or "General").strip()[:60], instructor_id,
             _time(data.present_time or c["present_time"]),
             _time(data.late_time or c["late_time"]),
             _time(data.end_time or c["end_time"]), cid),
        )
    return class_public(get_class(cid))


def delete_class_record(cid, user):
    c = get_class(cid)
    if not c:
        raise HTTPException(status_code=404, detail="No such class.")
    if not can_manage(user, c):
        raise HTTPException(status_code=403, detail="You don't manage this class.")
    with get_connection() as con, con:
        sids = [r["id"] for r in con.execute("SELECT id FROM sessions WHERE class_id=?", (cid,))]
        for sid in sids:
            con.execute("DELETE FROM attendance WHERE session_id=?", (sid,))
        for table in ("sessions", "enrollments", "announcements", "excuses", "notifications"):
            con.execute(f"DELETE FROM {table} WHERE class_id=?", (cid,))
        con.execute("DELETE FROM classes WHERE id=?", (cid,))
    import attendance_state as A
    if A.active and A.active.get("class_id") == cid:
        A.end(cid)
    return {"ok": True}


# ------------------------------------------------------------------ endpoints
@router.get("")
def list_classes(user: dict = Depends(get_current_user)):
    with get_connection() as con:
        if user["role"] == "instructor":
            rows = con.execute(
                """SELECT c.*, u.full_name AS instructor_name FROM classes c
                   LEFT JOIN users u ON u.id=c.instructor_id
                   WHERE c.instructor_id=? ORDER BY c.created_at DESC""", (user["id"],)
            ).fetchall()
        elif user["role"] == "student":
            rows = con.execute(
                """SELECT c.*, u.full_name AS instructor_name FROM enrollments e
                   JOIN classes c ON c.id=e.class_id LEFT JOIN users u ON u.id=c.instructor_id
                   WHERE e.user_id=? ORDER BY c.created_at DESC""", (user["id"],)
            ).fetchall()
        else:
            rows = con.execute(
                """SELECT c.*, u.full_name AS instructor_name FROM classes c
                   LEFT JOIN users u ON u.id=c.instructor_id ORDER BY c.created_at DESC"""
            ).fetchall()
    return [class_public(dict(r)) for r in rows]


@router.post("", status_code=201)
def create_class(data: ClassIn, user: dict = Depends(get_current_user)):
    if user["role"] not in ("instructor", "admin"):
        raise HTTPException(status_code=403, detail="Only instructors can create classes.")
    return create_class_record(data, user)


@router.get("/{cid}")
def get_one_class(cid: str, user: dict = Depends(get_current_user)):
    c = get_class(cid)
    if not can_view(user, c):
        raise HTTPException(status_code=403, detail="You don't have access to this class.")
    return class_public(c)


@router.put("/{cid}")
def update_class(cid: str, data: ClassIn, user: dict = Depends(get_current_user)):
    return update_class_record(cid, data, user)


@router.delete("/{cid}")
def delete_class(cid: str, user: dict = Depends(get_current_user)):
    return delete_class_record(cid, user)


@router.post("/join")
def join_class(data: JoinIn, user: dict = Depends(get_current_user)):
    if user["role"] != "student":
        raise HTTPException(status_code=403, detail="Only students join classes.")
    code = (data.code or "").strip().upper()
    with get_connection() as con, con:
        c = con.execute("SELECT * FROM classes WHERE code=?", (code,)).fetchone()
        if not c:
            raise HTTPException(status_code=404, detail="No class has that code.")
        if con.execute("SELECT 1 FROM enrollments WHERE class_id=? AND user_id=?",
                       (c["id"], user["id"])).fetchone():
            raise HTTPException(status_code=409, detail="You're already in this class.")
        con.execute("INSERT INTO enrollments VALUES(?,?,?)", (c["id"], user["id"], time.time()))
    return {"ok": True, "class_id": c["id"], "name": c["name"]}


@router.post("/{cid}/leave")
def leave_class(cid: str, user: dict = Depends(get_current_user)):
    with get_connection() as con, con:
        con.execute("DELETE FROM enrollments WHERE class_id=? AND user_id=?", (cid, user["id"]))
        con.execute("DELETE FROM excuses WHERE class_id=? AND user_id=?", (cid, user["id"]))
    return {"ok": True}


@router.get("/{cid}/students")
def class_students(cid: str, user: dict = Depends(get_current_user)):
    c = get_class(cid)
    if not can_manage(user, c):
        raise HTTPException(status_code=403, detail="You don't manage this class.")
    with get_connection() as con:
        rows = con.execute(
            """SELECT u.* FROM enrollments e JOIN users u ON u.id=e.user_id
               WHERE e.class_id=? ORDER BY u.full_name""", (cid,)
        ).fetchall()
    return [user_public(dict(r)) for r in rows]


@router.delete("/{cid}/students/{uid}")
def remove_student(cid: str, uid: int, user: dict = Depends(get_current_user)):
    c = get_class(cid)
    if not can_manage(user, c):
        raise HTTPException(status_code=403, detail="You don't manage this class.")
    with get_connection() as con, con:
        con.execute("DELETE FROM enrollments WHERE class_id=? AND user_id=?", (cid, uid))
        con.execute("DELETE FROM excuses WHERE class_id=? AND user_id=?", (cid, uid))
    return {"ok": True}


# -------------------------------------------------------------- announcements
@router.get("/{cid}/announcements")
def announcements(cid: str, user: dict = Depends(get_current_user)):
    c = get_class(cid)
    if not can_view(user, c):
        raise HTTPException(status_code=403, detail="You don't have access to this class.")
    with get_connection() as con:
        rows = con.execute(
            """SELECT a.*, COALESCE(u.full_name,'Administrator') AS author
               FROM announcements a LEFT JOIN users u ON u.id=a.instructor_id
               WHERE a.class_id=? ORDER BY a.created_at DESC""", (cid,)
        ).fetchall()
    return [{"id": r["id"], "title": r["title"], "body": r["body"], "author": r["author"],
             "date": time.strftime("%b %d, %Y %H:%M", time.localtime(r["created_at"]))}
            for r in rows]


@router.post("/{cid}/announcements", status_code=201)
def post_announcement(cid: str, data: AnnouncementIn, user: dict = Depends(get_current_user)):
    c = get_class(cid)
    if not can_manage(user, c):
        raise HTTPException(status_code=403, detail="You don't manage this class.")
    title, body = (data.title or "").strip()[:120], (data.body or "").strip()[:1000]
    if not title or not body:
        raise HTTPException(status_code=400, detail="Add a title and a message.")
    with get_connection() as con, con:
        con.execute(
            """INSERT INTO announcements(class_id,instructor_id,title,body,created_at)
               VALUES(?,?,?,?,?)""", (cid, user["id"], title, body, time.time())
        )
        audience = [r["user_id"] for r in con.execute(
            "SELECT user_id FROM enrollments WHERE class_id=?", (cid,))]
    for uid in audience:
        notify(uid, "announcement", title, body, cid)
    return {"ok": True}


@router.delete("/{cid}/announcements/{aid}")
def delete_announcement(cid: str, aid: int, user: dict = Depends(get_current_user)):
    c = get_class(cid)
    if not can_manage(user, c):
        raise HTTPException(status_code=403, detail="You don't manage this class.")
    with get_connection() as con, con:
        con.execute("DELETE FROM announcements WHERE id=? AND class_id=?", (aid, cid))
    return {"ok": True}

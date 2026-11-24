"""Live scanning, class sessions, records, corrections and excuse letters."""
import base64
import csv
import io
import time
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel

import attendance_state as A
from auth import get_current_user, require_role
from db import get_class, get_connection, get_user, user_public
from scanner import scanner

router = APIRouter(prefix="/attendance", tags=["attendance"])


class StartIn(BaseModel):
    class_id: str


class FrameIn(BaseModel):
    image: str   # base64 JPEG frame from the phone camera


class ExcuseIn(BaseModel):
    class_id: str
    date: str
    note: str


class StatusIn(BaseModel):
    status: str
    date: str = ""


def _b64(value: str) -> bytes:
    try:
        return base64.b64decode(value.split(",", 1)[-1], validate=True)
    except Exception:
        raise HTTPException(status_code=400, detail="That frame could not be read.")


def _manage(cid, user):
    c = get_class(cid)
    if not A.can_manage(user, c):
        raise HTTPException(status_code=403, detail="You don't manage this class.")
    return c


# ------------------------------------------------------------ live scanning
@router.get("/session")
def session_status(user: dict = Depends(get_current_user)):
    return A.status()


@router.post("/session/start")
def start_session(data: StartIn, user: dict = Depends(require_role("instructor", "admin"))):
    _manage(data.class_id, user)
    try:
        session = A.start(data.class_id, user["id"])
    except ValueError as e:
        raise HTTPException(status_code=409, detail=str(e))
    scanner.reset(user["id"])
    return {"ok": True, "session": session}


@router.post("/session/end")
def end_session(user: dict = Depends(require_role("instructor", "admin"))):
    A.end(owner_id=user["id"])
    scanner.reset(user["id"])
    return {"ok": True, "session": A.status()["session"]}


@router.post("/frame")
def upload_frame(data: FrameIn, user: dict = Depends(require_role("instructor", "admin"))):
    """Send one camera frame; get back recognised faces and the updated roster."""
    raw = _b64(data.image)
    if not scanner.ready:
        raise HTTPException(status_code=503, detail="The face model is still loading.")
    try:
        return scanner.process(user["id"], raw)
    except ValueError as e:
        raise HTTPException(status_code=409, detail=str(e))


@router.post("/frame/reset")
def reset_tracking(user: dict = Depends(require_role("instructor", "admin"))):
    scanner.reset(user["id"])
    return {"ok": True}


# ------------------------------------------------------------ class records
@router.get("/class/{cid}")
def class_attendance(
    cid: str,
    month: str = "",
    status: str = "",
    student_id: int = 0,
    user: dict = Depends(get_current_user),
):
    c = get_class(cid)
    if not A.can_view(user, c):
        raise HTTPException(status_code=403, detail="You don't have access to this class.")
    month = month or datetime.now().strftime("%Y-%m")
    if user["role"] == "student":
        target = user["id"]
    elif student_id:
        target = student_id
        student = get_user(target)
        if not student or student["role"] != "student":
            raise HTTPException(status_code=404, detail="That student was not found.")
        with get_connection() as con:
            if not con.execute("SELECT 1 FROM enrollments WHERE class_id=? AND user_id=?",
                               (cid, target)).fetchone():
                raise HTTPException(status_code=404, detail="That student is not in this class.")
    else:
        # No student selected (e.g. an admin opening the calendar): use the first
        # enrolled student, or return an empty calendar if the class has none.
        with get_connection() as con:
            first = con.execute(
                """SELECT u.id FROM enrollments e JOIN users u ON u.id=e.user_id
                   WHERE e.class_id=? AND u.role='student' ORDER BY u.full_name LIMIT 1""",
                (cid,),
            ).fetchone()
        target = first["id"] if first else None
    if not target:
        return {"month": month, "days": {}, "summary": {
            s: 0 for s in ("present", "late", "absent", "excused")},
            "matches": {}, "excuses": [], "student": None}
    result = A.attendance_data(cid, target, month, status or None)
    if result is None:
        raise HTTPException(status_code=404, detail="Student not found.")
    result["student"] = user_public(get_user(target))
    return result


@router.get("/class/{cid}/sessions")
def class_sessions(cid: str, user: dict = Depends(get_current_user)):
    _manage(cid, user)
    with get_connection() as con:
        rows = con.execute(
            """SELECT s.*, (SELECT COUNT(*) FROM attendance a WHERE a.session_id=s.id) present
               FROM sessions s WHERE s.class_id=? ORDER BY s.id DESC LIMIT 30""", (cid,)
        ).fetchall()
    return [{"id": r["id"], "name": r["name"],
             "date": datetime.fromtimestamp(r["started_at"]).strftime("%b %d, %Y %H:%M"),
             "present": r["present"], "ended": r["ended_at"] is not None} for r in rows]


@router.post("/class/{cid}/students/{uid}/status")
def manual_status(cid: str, uid: int, data: StatusIn,
                  user: dict = Depends(require_role("instructor", "admin"))):
    _manage(cid, user)
    try:
        return {"ok": True, "status": A.set_manual_status(cid, uid, data.status, data.date)}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/export/{sid}")
def export_csv(sid: int, user: dict = Depends(get_current_user)):
    with get_connection() as con:
        s = con.execute("SELECT * FROM sessions WHERE id=?", (sid,)).fetchone()
        if not s:
            raise HTTPException(status_code=404, detail="No such class.")
        c = get_class(s["class_id"]) if s["class_id"] else None
        if not A.can_view(user, c) and user["role"] != "admin":
            raise HTTPException(status_code=403, detail="You don't have access to this class.")
        rows = con.execute(
            """SELECT st.name, a.status, a.seen_at FROM students st
               LEFT JOIN attendance a ON a.student_id=st.id AND a.session_id=?
               ORDER BY st.name""", (sid,)
        ).fetchall()
    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(["Class", "Date", "Student", "Status", "Time seen"])
    day = datetime.fromtimestamp(s["started_at"]).strftime("%Y-%m-%d")
    for r in rows:
        writer.writerow([s["name"], day, r["name"], r["status"] or "absent",
                         datetime.fromtimestamp(r["seen_at"]).strftime("%H:%M:%S")
                         if r["seen_at"] else ""])
    return Response(out.getvalue(), media_type="text/csv",
                    headers={"Content-Disposition": f'attachment; filename="attendance_{sid}.csv"'})


# ------------------------------------------------------------------- excuses
@router.post("/excuse")
def add_excuse(data: ExcuseIn, user: dict = Depends(require_role("student"))):
    c = get_class(data.class_id)
    if not A.can_view(user, c):
        raise HTTPException(status_code=403, detail="You're not enrolled in this class.")
    try:
        datetime.strptime(data.date, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Pick a valid date.")
    note = (data.note or "").strip()[:400]
    if not note:
        raise HTTPException(status_code=400, detail="Write a short note for your excuse.")
    with get_connection() as con, con:
        con.execute(
            """INSERT INTO excuses(class_id,user_id,date,note,created_at) VALUES(?,?,?,?,?)
               ON CONFLICT(class_id,user_id,date) DO UPDATE SET note=excluded.note,
               created_at=excluded.created_at""",
            (data.class_id, user["id"], data.date, note, time.time()),
        )
    from notifications import notify
    notify(c.get("instructor_id"), "excuse", f"Excuse letter · {user['name']}",
           f"{data.date}: {note}", data.class_id)
    with get_connection() as con:
        admins = [r["id"] for r in con.execute("SELECT id FROM users WHERE role='admin'")]
    for admin_id in admins:
        notify(admin_id, "excuse", f"Excuse letter · {user['name']}",
               f"{c['name']} · {data.date}: {note}", data.class_id)
    return {"ok": True, "date": data.date, "note": note}


@router.get("/excuses/{cid}")
def list_excuses(cid: str, user: dict = Depends(get_current_user)):
    c = get_class(cid)
    if not A.can_view(user, c):
        raise HTTPException(status_code=403, detail="You don't have access to this class.")
    with get_connection() as con:
        rows = con.execute(
            """SELECT e.date, e.note, u.id AS user_id, u.full_name AS name
               FROM excuses e JOIN users u ON u.id=e.user_id WHERE e.class_id=? ORDER BY e.date""",
            (cid,),
        ).fetchall()
    return [dict(r) for r in rows]


@router.delete("/excuse/{cid}/{day}")
def delete_excuse(cid: str, day: str, user: dict = Depends(require_role("student"))):
    with get_connection() as con, con:
        con.execute("DELETE FROM excuses WHERE class_id=? AND user_id=? AND date=?",
                    (cid, user["id"], day))
    return {"ok": True}

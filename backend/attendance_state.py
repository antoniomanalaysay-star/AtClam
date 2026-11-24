"""The live class session: start/end, rosters, marking and monthly records."""
import threading
import time
from collections import Counter
from datetime import date, datetime
from functools import wraps

import faceid as F
from db import get_connection
import config as C

active = None   # {"id","name","class_id","started_at","marked","owner_id"}
lock = threading.RLock()


# ------------------------------------------------------------------ helpers
def _clock(ts):
    return datetime.fromtimestamp(ts).strftime("%H:%M:%S") if ts else ""


def _month_of(ts):
    return datetime.fromtimestamp(ts).strftime("%Y-%m")


def _time_today(hhmm, ts=None):
    if not hhmm:
        return None
    dt = datetime.fromtimestamp(ts if ts is not None else time.time())
    h, m = (int(x) for x in hhmm.split(":"))
    return dt.replace(hour=h, minute=m, second=0, microsecond=0).timestamp()


def class_status(cid, now=None):
    """Present/Late from the instructor's class times, with a safe fallback."""
    now = now if now is not None else time.time()
    from db import get_class
    c = get_class(cid) if cid else None
    if c and c.get("present_time") and c.get("late_time"):
        late = _time_today(c["late_time"], now)
        end = _time_today(c["end_time"], now)
        if end and now > end:
            return "absent"
        return "late" if late and now >= late else "present"
    start = active["started_at"] if active else now
    return "late" if now - start > C.LATE_AFTER_MIN * 60 else "present"


def can_manage(user, c):
    return bool(c) and (
        user["role"] == "admin"
        or (user["role"] == "instructor" and c["instructor_id"] == user["id"])
    )


def can_view(user, c):
    if not c:
        return False
    if user["role"] in ("admin", "instructor"):
        return can_manage(user, c)
    with get_connection() as con:
        return bool(con.execute(
            "SELECT 1 FROM enrollments WHERE class_id=? AND user_id=?",
            (c["id"], user["id"]),
        ).fetchone())


# --------------------------------------------------------------- live session
def eligible_ids():
    """Face-profile ids that may be marked in the running class."""
    if not active:
        return set()
    if not active.get("class_id"):
        with get_connection() as con:
            return {r["id"] for r in con.execute("SELECT id FROM students")}
    with get_connection() as con:
        return {
            r["student_id"] for r in con.execute(
                """SELECT u.student_id FROM enrollments e JOIN users u ON u.id=e.user_id
                   WHERE e.class_id=? AND u.student_id IS NOT NULL""",
                (active["class_id"],),
            )
        }


def mark_present(student_id):
    s = active
    if not s or student_id in s["marked"] or student_id not in eligible_ids():
        return None
    now = time.time()
    status = class_status(s.get("class_id"), now)
    if status == "absent":
        return None
    with lock, get_connection() as con, con:
        con.execute(
            "INSERT OR IGNORE INTO attendance VALUES(?,?,?,?)",
            (s["id"], student_id, now, status),
        )
    s["marked"].add(student_id)
    return status


def start(cid, owner_id):
    global active
    from db import get_class
    c = get_class(cid)
    if not c:
        raise ValueError("No such class.")
    with lock:
        if active:
            raise ValueError("A class is already running.")
        now = time.time()
        with get_connection() as con, con:
            cur = con.execute(
                "INSERT INTO sessions(name,started_at,class_id) VALUES(?,?,?)",
                (c["name"], now, cid),
            )
        active = {"id": cur.lastrowid, "name": c["name"], "class_id": cid,
                  "started_at": now, "marked": set(), "owner_id": owner_id}
    return dict(active, marked=len(active["marked"]))


def end(cid=None, owner_id=None):
    global active
    if not active:
        return
    if cid and active.get("class_id") != cid:
        return
    sid, class_id = active["id"], active.get("class_id")
    started, marked = active["started_at"], set(active["marked"])
    with lock:
        if class_id:
            _finalize(sid, class_id, started, marked)
        with get_connection() as con, con:
            con.execute("UPDATE sessions SET ended_at=? WHERE id=?", (time.time(), sid))
        active = None


def _finalize(sid, cid, started_at, marked):
    """No face by class end means Absent — except students with an excuse."""
    day = datetime.fromtimestamp(started_at).strftime("%Y-%m-%d")
    with lock, get_connection() as con, con:
        excused = {
            r["user_id"] for r in con.execute(
                "SELECT user_id FROM excuses WHERE class_id=? AND date=?", (cid, day)
            )
        }
        rows = con.execute(
            """SELECT u.student_id, u.id AS user_id FROM enrollments e
               JOIN users u ON u.id=e.user_id WHERE e.class_id=?
               AND u.student_id IS NOT NULL""", (cid,)
        ).fetchall()
        for r in rows:
            if r["student_id"] in marked or r["user_id"] in excused:
                continue
            con.execute(
                "INSERT OR IGNORE INTO attendance VALUES(?,?,?,?)",
                (sid, r["student_id"], None, "absent"),
            )


def resume():
    """Recover a session that was running before a server restart."""
    global active
    with lock, get_connection() as con:
        r = con.execute(
            "SELECT * FROM sessions WHERE ended_at IS NULL ORDER BY id DESC LIMIT 1"
        ).fetchone()
        if r:
            marked = {
                x["student_id"] for x in con.execute(
                    "SELECT student_id FROM attendance WHERE session_id=?", (r["id"],)
                )
            }
            active = {"id": r["id"], "name": r["name"], "class_id": r["class_id"],
                      "started_at": r["started_at"], "marked": marked, "owner_id": None}


def roster():
    if not active:
        return []
    with get_connection() as con:
        rows = {
            r["student_id"]: r for r in con.execute(
                "SELECT * FROM attendance WHERE session_id=?", (active["id"],)
            )
        }
        if active.get("class_id"):
            members = con.execute(
                """SELECT u.student_id, u.full_name FROM enrollments e
                   JOIN users u ON u.id=e.user_id WHERE e.class_id=?
                   ORDER BY u.full_name""", (active["class_id"],)
            ).fetchall()
        else:
            members = con.execute(
                "SELECT id AS student_id, name AS full_name FROM students ORDER BY name"
            ).fetchall()
    out = []
    for p in members:
        pid, name = p["student_id"], p["full_name"]
        if not pid:
            continue
        row = rows.get(pid)
        out.append({"id": pid, "name": name,
                    "status": row["status"] if row else "absent",
                    "time": _clock(row["seen_at"]) if row else ""})
    return out


def status():
    session = None
    if active:
        session = {"id": active["id"], "name": active["name"],
                   "class_id": active.get("class_id"),
                   "started": _clock(active["started_at"]),
                   "student_count": len(roster())}
    return {"active": bool(active), "session": session, "roster": roster(),
            "model_ready": F.ready()}


# ------------------------------------------------------------ monthly records
_STATUS_RANK = {"absent": 1, "late": 2, "present": 3, "excused": 4}


def attendance_data(cid, uid, month, wanted=None):
    with get_connection() as con:
        u = con.execute("SELECT student_id FROM users WHERE id=?", (uid,)).fetchone()
        if not u:
            return None
        face_id = u["student_id"]
        sessions = con.execute(
            """SELECT id, started_at FROM sessions
               WHERE class_id=? AND ended_at IS NOT NULL ORDER BY started_at""", (cid,)
        ).fetchall()
        days = {}
        for s in sessions:
            if _month_of(s["started_at"]) != month:
                continue
            d = datetime.fromtimestamp(s["started_at"]).strftime("%Y-%m-%d")
            row = None
            if face_id:
                row = con.execute(
                    "SELECT status, seen_at FROM attendance WHERE session_id=? AND student_id=?",
                    (s["id"], face_id),
                ).fetchone()
            state = row["status"] if row else "absent"
            old = days.get(d, {"status": "absent", "times": []})
            if row and row["seen_at"]:
                old["times"].append(_clock(row["seen_at"]))
            if _STATUS_RANK[state] > _STATUS_RANK[old["status"]]:
                old["status"] = state
            days[d] = old

        excuses = con.execute(
            """SELECT date, note FROM excuses
               WHERE class_id=? AND user_id=? AND substr(date,1,7)=? ORDER BY date""",
            (cid, uid, month),
        ).fetchall()
        result, notes = {}, []
        for r in excuses:
            entry = days.setdefault(r["date"], {"status": "absent", "times": []})
            entry["status"] = "excused"
            notes.append({"date": r["date"], "note": r["note"]})
        for d, entry in days.items():
            result[d] = {"status": entry["status"],
                         "time": entry["times"][0] if entry["times"] else ""}
            ex = next((n for n in notes if n["date"] == d), None)
            if ex:
                result[d]["note"] = ex["note"]

    summary = {s: sum(1 for v in result.values() if v["status"] == s)
               for s in ("present", "late", "absent", "excused")}
    matches = {d: v for d, v in result.items() if not wanted or v["status"] == wanted}
    return {"month": month, "days": result, "summary": summary,
            "matches": matches, "excuses": notes}


def set_manual_status(cid, user_id, status, day=None):
    """Instructor correction: write/overwrite a student's status for a class day."""
    if status not in ("present", "late", "absent", "excused"):
        raise ValueError("Invalid status.")
    day = day or date.today().isoformat()
    with lock, get_connection() as con, con:
        u = con.execute("SELECT student_id FROM users WHERE id=?", (user_id,)).fetchone()
        if not u or not u["student_id"]:
            raise ValueError("That student has no face profile.")
        session = con.execute(
            """SELECT id FROM sessions WHERE class_id=?
               AND to_timestamp(started_at)::date = to_date(?, 'YYYY-MM-DD')
               ORDER BY id DESC LIMIT 1""", (cid, day)
        ).fetchone()
        if not session:
            cur = con.execute(
                "INSERT INTO sessions(name,started_at,ended_at,class_id) VALUES(?,?,?,?)",
                ("Manual", time.time(), time.time(), cid),
            )
            sid = cur.lastrowid
        else:
            sid = session["id"]
        con.execute(
            """INSERT INTO attendance(session_id,student_id,seen_at,status) VALUES(?,?,?,?)
               ON CONFLICT(session_id,student_id) DO UPDATE SET status=excluded.status""",
            (sid, u["student_id"], time.time() if status in ("present", "late") else None, status),
        )
    return status

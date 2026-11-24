"""Notification inbox (announcements and excuse letters)."""
import time
from datetime import datetime

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from auth import get_current_user
from db import get_connection

router = APIRouter(prefix="/notifications", tags=["notifications"])


class ReadIn(BaseModel):
    all: bool = False
    id: int = 0


@router.get("")
def list_notifications(user: dict = Depends(get_current_user)):
    with get_connection() as con:
        rows = con.execute(
            """SELECT n.*, c.name AS class_name FROM notifications n
               LEFT JOIN classes c ON c.id=n.class_id
               WHERE n.user_id=? ORDER BY n.id DESC LIMIT 40""", (user["id"],)
        ).fetchall()
        unread = con.execute(
            "SELECT COUNT(*) n FROM notifications WHERE user_id=? AND read_at IS NULL",
            (user["id"],),
        ).fetchone()["n"]
    return {
        "unread": unread,
        "items": [{
            "id": r["id"], "kind": r["kind"], "title": r["title"], "body": r["body"],
            "class_id": r["class_id"], "class_name": r["class_name"] or "Class",
            "time": datetime.fromtimestamp(r["created_at"]).strftime("%b %d, %H:%M"),
            "read": r["read_at"] is not None,
        } for r in rows],
    }


@router.post("/read")
def mark_read(data: ReadIn, user: dict = Depends(get_current_user)):
    with get_connection() as con, con:
        if data.all:
            con.execute(
                "UPDATE notifications SET read_at=? WHERE user_id=? AND read_at IS NULL",
                (time.time(), user["id"]),
            )
        elif data.id:
            con.execute(
                "UPDATE notifications SET read_at=? WHERE id=? AND user_id=?",
                (time.time(), data.id, user["id"]),
            )
    return {"ok": True}

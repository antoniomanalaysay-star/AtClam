"""Small helper for the right-side notifications shown in the app."""
import time

from db import get_connection


def notify(user_id, kind: str, title: str, body: str, class_id: str) -> None:
    if not user_id:
        return
    with get_connection() as con, con:
        con.execute(
            """INSERT INTO notifications(user_id,kind,title,body,class_id,created_at)
               VALUES(?,?,?,?,?,?)""",
            (int(user_id), kind, title[:120], body[:400], class_id, time.time()),
        )

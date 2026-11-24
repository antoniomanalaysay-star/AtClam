"""One-time migration: old SQLite attendance.db -> PostgreSQL (backend/.env).

Safe to re-run: all target tables are cleared first, so the SQLite file remains
the source of truth until you are happy with the Postgres database.
"""
import sqlite3
import sys
from contextlib import closing
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE))

import db  # noqa: E402  (needs sys.path set above)

SQLITE_DB = BASE / "data" / "attendance.db"

# (table, columns) in foreign-key-safe order.
TABLES = [
    ("students", ["id", "name", "embeddings"]),
    ("users", ["id", "full_name", "username", "email", "password_hash", "role",
               "student_id", "created_at", "section", "school_id", "is_active"]),
    ("classes", ["id", "code", "name", "description", "section", "instructor_id",
                 "created_at", "present_time", "late_time", "end_time"]),
    ("sessions", ["id", "name", "started_at", "ended_at", "class_id"]),
    ("attendance", ["session_id", "student_id", "seen_at", "status"]),
    ("enrollments", ["class_id", "user_id", "joined_at"]),
    ("announcements", ["id", "class_id", "instructor_id", "title", "body", "created_at"]),
    ("excuses", ["id", "class_id", "user_id", "date", "note", "created_at"]),
    ("notifications", ["id", "user_id", "kind", "title", "body", "class_id",
                       "created_at", "read_at"]),
]

SEQUENCE_TABLES = {
    "users": "id", "sessions": "id", "announcements": "id",
    "excuses": "id", "notifications": "id",
}


def main():
    if not SQLITE_DB.exists():
        raise SystemExit(f"Old SQLite database not found: {SQLITE_DB}")

    print(f"Migrating {SQLITE_DB} -> PostgreSQL database '{db.DB_NAME}' ...")
    src = sqlite3.connect(SQLITE_DB)
    src.row_factory = sqlite3.Row

    db.init_db()

    with closing(db.get_connection()) as con, con:
        # Wipe target tables (reverse order so FKs never block).
        for table, _ in reversed(TABLES):
            con.execute(f"TRUNCATE TABLE {table} RESTART IDENTITY CASCADE")

        counts = {}
        for table, cols in TABLES:
            rows = [tuple(r[c] for c in cols) for r in src.execute(
                f"SELECT {','.join(cols)} FROM {table}")]
            if rows:
                placeholders = ",".join(["?"] * len(cols))
                con.executemany(
                    f"INSERT INTO {table}({','.join(cols)}) VALUES({placeholders})",
                    rows,
                )
            counts[table] = len(rows)

        # Advance identity sequences past the imported ids.
        for table, col in SEQUENCE_TABLES.items():
            # Identifiers come from the hardcoded SEQUENCE_TABLES map above.
            con.execute(
                f"SELECT setval(pg_get_serial_sequence('{table}','{col}'), "
                f"COALESCE((SELECT MAX({col}) FROM {table}), 1), "
                f"(SELECT COUNT(*)>0 FROM {table}))"
            )

    src.close()
    for table, n in counts.items():
        print(f"  {table:14s} {n:5d} rows")
    print("Migration complete. PostgreSQL now holds the attendance data.")


if __name__ == "__main__":
    main()

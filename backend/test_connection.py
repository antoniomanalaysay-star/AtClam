"""Quick check that the backend database and face model are usable."""
from db import get_connection, init_db
from scanner import scanner


def main():
    init_db()
    with get_connection() as con:
        counts = {
            table: con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()["count"]
            for table in ("users", "students", "classes", "sessions", "attendance")
        }
    print("Database:", counts)
    print("Face model ready:", scanner.load())
    print("Backend is ready.")


if __name__ == "__main__":
    main()

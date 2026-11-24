"""Create the first admin account (nobody can create one from the app).

Usage (from the backend folder):
    python3 seed_admin.py "Admin Name" admin@school.edu "a-strong-password"
"""
import sys
import time
import uuid

from auth import hash_password, validate_email, validate_password
from db import get_connection, init_db


def main():
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)
    name, email, password = sys.argv[1], sys.argv[2], sys.argv[3]
    try:
        email = validate_email(email)
        validate_password(password)
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)

    init_db()
    try:
        with get_connection() as con, con:
            cur = con.execute(
                """INSERT INTO users(full_name,username,email,password_hash,role,
                                     school_id,section,created_at)
                   VALUES(?,?,?,?,'admin','','',?)""",
                (name.strip(), uuid.uuid4().hex[:12], email, hash_password(password), time.time()),
            )
    except Exception as e:
        if "UNIQUE" in str(e).upper():
            print("Error: that email is already registered")
            sys.exit(1)
        raise
    print(f"Admin created with id {cur.lastrowid}")


if __name__ == "__main__":
    main()

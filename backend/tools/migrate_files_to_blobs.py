"""One-time migration: local face/avatar images and JWT secret -> Postgres.

Run from the backend folder on the computer that still has backend/data/:
    python tools/migrate_files_to_blobs.py

Safe to run more than once. Requires the same DB_* env vars as the backend.
"""
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND))

import config as C  # noqa: E402
from db import (get_setting, init_db, load_blob, save_blob, set_setting)  # noqa: E402


def main() -> None:
    init_db()
    moved = 0
    for kind, folder in (("face", C.FACES), ("avatar", C.AVATARS)):
        if not folder.exists():
            continue
        for path in folder.glob("*.jpg"):
            key = path.stem
            if load_blob(kind, key) is not None:
                continue
            save_blob(kind, key, path.read_bytes())
            moved += 1
            print(f"migrated {kind}: {key}")

    if not get_setting("jwt_secret") and C.SECRET_PATH.exists():
        set_setting("jwt_secret", C.SECRET_PATH.read_text().strip())
        print("migrated jwt_secret")

    print(f"done — {moved} image(s) migrated")


if __name__ == "__main__":
    main()

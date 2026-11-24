"""Passwords, phone-friendly bearer tokens and role checks."""
import base64
import hashlib
import hmac
import json
import os
import re
import time
from typing import Optional

import bcrypt
from fastapi import Depends, Header, HTTPException

import config as C
from db import get_connection, user_public

_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
TOKEN_HOURS = int(os.getenv("TOKEN_HOURS", "168"))  # 7 days by default
_bearer_prefix = "bearer "


def _secret() -> bytes:
    env = os.getenv("JWT_SECRET")
    if env:
        return env.encode()
    C.DATA.mkdir(parents=True, exist_ok=True)
    if not C.SECRET_PATH.exists():
        C.SECRET_PATH.write_text(os.urandom(32).hex())
    return C.SECRET_PATH.read_text().strip().encode()


# ---------------------------------------------------------------- passwords
def validate_password(password: str) -> str:
    if len(password) < 8:
        raise ValueError("Password must be at least 8 characters")
    if len(password.encode()) > 72:
        raise ValueError("Password is too long (max 72 bytes)")
    return password


def validate_email(email: str) -> str:
    email = (email or "").strip().lower()
    if not _EMAIL_RE.match(email):
        raise ValueError("Invalid email address")
    return email


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def _check_legacy_hash(password: str, stored: str) -> bool:
    """Old accounts were created by Flask with werkzeug pbkdf2 hashes."""
    try:
        if stored.startswith("pbkdf2:"):
            method, salt, expected = stored.split("$", 2)
            _, algorithm, rounds = method.split(":")
            computed = hashlib.pbkdf2_hmac(
                algorithm, password.encode(), salt.encode(), int(rounds)
            ).hex()
            return hmac.compare_digest(computed, expected)
        from werkzeug.security import check_password_hash
        return check_password_hash(stored, password)
    except Exception:
        return False


def check_password(password: str, stored: str) -> bool:
    if not stored:
        return False
    if stored.startswith(("$2a$", "$2b$", "$2y$")):
        try:
            return bcrypt.checkpw(password.encode(), stored.encode())
        except ValueError:
            return False
    return _check_legacy_hash(password, stored)


# ------------------------------------------------------------------- tokens
def _b64e(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


def _b64d(text: str) -> bytes:
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))


def create_token(user_id: int) -> str:
    payload = {"sub": str(user_id), "exp": int(time.time()) + TOKEN_HOURS * 3600}
    body = _b64e(json.dumps(payload, separators=(",", ":")).encode())
    signature = _b64e(hmac.new(_secret(), body.encode(), hashlib.sha256).digest())
    return f"{body}.{signature}"


def _token_user_id(token: str) -> int:
    try:
        body, signature = token.split(".", 1)
        expected = _b64e(hmac.new(_secret(), body.encode(), hashlib.sha256).digest())
        if not hmac.compare_digest(signature, expected):
            raise ValueError
        payload = json.loads(_b64d(body))
        if int(payload["exp"]) < int(time.time()):
            raise ValueError
        return int(payload["sub"])
    except (ValueError, KeyError, TypeError, json.JSONDecodeError):
        raise HTTPException(status_code=401, detail="Invalid or expired token")


# --------------------------------------------------------------- dependencies
def get_current_user(authorization: Optional[str] = Header(default=None)) -> dict:
    if not authorization or not authorization.lower().startswith(_bearer_prefix):
        raise HTTPException(status_code=401, detail="Not logged in")
    user_id = _token_user_id(authorization[len(_bearer_prefix):].strip())
    with get_connection() as con:
        row = con.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
    user = dict(row) if row else None
    if user is None or not user.get("is_active", 1):
        raise HTTPException(status_code=401, detail="Account not found or inactive")
    return user_public(user)


def require_role(*roles: str):
    def checker(user: dict = Depends(get_current_user)) -> dict:
        if user["role"] not in roles:
            raise HTTPException(status_code=403, detail="You are not allowed to do this")
        return user
    return checker

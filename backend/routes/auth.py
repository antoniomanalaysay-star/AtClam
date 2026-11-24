"""Accounts: register, log in, profile, face enrollment and avatars."""
import base64
import re
import time
import uuid
from typing import List, Optional

import cv2
import numpy as np
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator

import config as C
from auth import (check_password, create_token, get_current_user, hash_password,
                  validate_email, validate_password)
from db import get_connection, user_public
from face_utils import decode_image, process_photos, save_face
from scanner import scanner

router = APIRouter(prefix="/auth", tags=["auth"])


class RegisterIn(BaseModel):
    name: str
    email: str
    password: str
    role: str = "student"          # old signup let people pick Student or Instructor
    username: Optional[str] = None
    school_id: Optional[str] = None

    @field_validator("role")
    @classmethod
    def _role(cls, v):
        v = (v or "student").strip().lower()
        if v not in ("student", "instructor"):
            raise ValueError("Choose Student or Instructor")
        return v

    @field_validator("username")
    @classmethod
    def _username(cls, v):
        v = (v or "").strip()
        return v[:40] or None

    @field_validator("name")
    @classmethod
    def _name(cls, v):
        v = (v or "").strip()
        if not v:
            raise ValueError("Name is required")
        return v[:60]

    @field_validator("email")
    @classmethod
    def _email(cls, v):
        return validate_email(v)

    @field_validator("password")
    @classmethod
    def _password(cls, v):
        return validate_password(v)

    @field_validator("school_id")
    @classmethod
    def _school_id(cls, v):
        return (v or "").strip()[:40] or None


class LoginIn(BaseModel):
    email: str            # email or username, for compatibility with older accounts
    password: str


class PasswordIn(BaseModel):
    old_password: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def _new(cls, v):
        return validate_password(v)


class ProfileIn(BaseModel):
    name: str
    school_id: Optional[str] = None
    section: Optional[str] = None

    @field_validator("name")
    @classmethod
    def _name(cls, v):
        v = (v or "").strip()
        if not v:
            raise ValueError("Name is required")
        return v[:60]


class PhotosIn(BaseModel):
    photos: List[str]     # base64-encoded JPEG/PNG images, exactly 3


class AvatarIn(BaseModel):
    image: str            # base64-encoded image


def _decode_b64(value: str) -> bytes:
    try:
        return base64.b64decode(value.split(",", 1)[-1], validate=True)
    except Exception:
        raise HTTPException(status_code=400, detail="That image could not be read.")


def _token_for(row) -> dict:
    user = user_public(row)
    return {"user": user, "access_token": create_token(user["id"]), "token_type": "bearer"}


# ---------------------------------------------------------------- register
@router.post("/register", status_code=201)
def register(data: RegisterIn):
    """Old-style signup: students or instructors create their own account."""
    try:
        with get_connection() as con, con:
            cur = con.execute(
                """INSERT INTO users(full_name,username,email,password_hash,role,
                                     school_id,section,created_at)
                   VALUES(?,?,?,?,?,?,'',?)""",
                (data.name, data.username or uuid.uuid4().hex[:12], data.email,
                 hash_password(data.password), data.role, data.school_id or "", time.time()),
            )
            row = con.execute("SELECT * FROM users WHERE id=?", (cur.lastrowid,)).fetchone()
    except Exception as e:
        if "UNIQUE" in str(e).upper():
            raise HTTPException(status_code=409, detail="That email is already registered.")
        raise
    return _token_for(row)


# -------------------------------------------------------------------- login
@router.post("/login")
def login(data: LoginIn):
    identity = (data.email or "").strip().lower()
    with get_connection() as con:
        row = con.execute(
            """SELECT * FROM users
               WHERE email=? COLLATE NOCASE OR username=? COLLATE NOCASE LIMIT 1""",
            (identity, identity),
        ).fetchone()
    user = dict(row) if row else None
    if user is None or not check_password(data.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if not user.get("is_active", 1):
        raise HTTPException(status_code=403, detail="Account is inactive. Ask your admin.")
    return _token_for(user)


@router.get("/me")
def me(user: dict = Depends(get_current_user)):
    return user


@router.post("/change-password")
def change_password(data: PasswordIn, user: dict = Depends(get_current_user)):
    with get_connection() as con, con:
        row = con.execute("SELECT password_hash FROM users WHERE id=?", (user["id"],)).fetchone()
        if not row or not check_password(data.old_password, row["password_hash"]):
            raise HTTPException(status_code=400, detail="Old password is incorrect")
        con.execute(
            "UPDATE users SET password_hash=? WHERE id=?",
            (hash_password(data.new_password), user["id"]),
        )
    return {"message": "Password changed"}


@router.post("/profile")
def update_profile(data: ProfileIn, user: dict = Depends(get_current_user)):
    with get_connection() as con, con:
        con.execute(
            "UPDATE users SET full_name=?, school_id=?, section=? WHERE id=?",
            (data.name, data.school_id or "", data.section or "", user["id"]),
        )
        if user.get("student_id"):
            con.execute("UPDATE students SET name=? WHERE id=?", (data.name, user["student_id"]))
    scanner.refresh_people()
    return {"user": user_public({**user, "full_name": data.name,
                                 "school_id": data.school_id or ""})}


# ----------------------------------------------------------- face enrollment
@router.post("/photos")
def upload_photos(data: PhotosIn, user: dict = Depends(get_current_user)):
    """Students upload 3 face photos; the camera can then recognise them."""
    if user["role"] != "student":
        raise HTTPException(status_code=403, detail="Only students register a face.")
    blobs = [_decode_b64(p) for p in data.photos]
    feats, crop, err = process_photos(blobs)
    if err:
        raise HTTPException(status_code=400, detail=err)
    pid = user.get("student_id") or uuid.uuid4().hex[:8]
    with get_connection() as con, con:
        con.execute(
            """INSERT INTO students(id,name,embeddings) VALUES(?,?,?)
               ON CONFLICT(id) DO UPDATE SET name=excluded.name, embeddings=excluded.embeddings""",
            (pid, user["name"], save_face(pid, feats, crop)),
        )
        con.execute("UPDATE users SET student_id=? WHERE id=?", (pid, user["id"]))
    scanner.refresh_people()
    return {"ok": True, "message": "Your 3 photos were saved.", "student_id": pid}


@router.post("/avatar")
def upload_avatar(data: AvatarIn, user: dict = Depends(get_current_user)):
    img = decode_image(_decode_b64(data.image))
    if img is None:
        raise HTTPException(status_code=400, detail="That image isn't readable.")
    h, w = img.shape[:2]
    side = min(h, w)
    x, y = (w - side) // 2, (h - side) // 2
    square = cv2.resize(img[y:y + side, x:x + side], (256, 256), interpolation=cv2.INTER_AREA)
    cv2.imwrite(str(C.AVATARS / f"{user['id']}.jpg"), square)
    return {"ok": True}


# --------------------------------------------------------- image endpoints
def _placeholder(kind):
    if kind == "face":
        return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80">'
                '<rect width="80" height="80" rx="12" fill="#dcf2df"/>'
                '<text x="40" y="54" font-size="34" text-anchor="middle" fill="#1f7a43">?</text></svg>')
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80">'
            '<rect width="80" height="80" rx="40" fill="#123d25"/>'
            '<text x="40" y="53" font-size="34" text-anchor="middle" '
            'fill="#a8e063" font-family="Arial, sans-serif">A</text></svg>')


def _serve_image(folder, uid, kind):
    from fastapi.responses import FileResponse, Response
    if not re.fullmatch(r"[A-Za-z0-9_-]+", uid):
        raise HTTPException(status_code=400, detail="Invalid id.")
    path = folder / f"{uid}.jpg"
    if path.exists():
        return FileResponse(path, media_type="image/jpeg")
    return Response(_placeholder(kind), media_type="image/svg+xml")


router_files = APIRouter(tags=["files"])


@router_files.get("/faces/{uid}.jpg")
def face_image(uid: str):
    return _serve_image(C.FACES, uid, "face")


@router_files.get("/avatars/{uid}.jpg")
def avatar_image(uid: str):
    return _serve_image(C.AVATARS, uid, "avatar")

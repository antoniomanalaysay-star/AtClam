"""AtClam API — FastAPI backend for the Flutter app (phone + web)."""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import attendance_state as A
from db import init_db
from scanner import scanner
from routes import admin as admin_routes
from routes import attendance as attendance_routes
from routes import auth as auth_routes
from routes import classes as class_routes
from routes import notifications as notification_routes
from routes.auth import router_files


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    A.resume()
    try:
        scanner.load()
        print("AtClam: face model ready.")
    except Exception as e:
        print(f"AtClam: face model could not load yet ({e}).")
    yield


app = FastAPI(
    title="AtClam - Camera-based Classroom Attendance and Management System",
    version="1.0.0",
    lifespan=lifespan,
)

# The Flutter app runs on a phone or in a browser, so allow cross-origin calls.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_routes.router)
app.include_router(router_files)
app.include_router(admin_routes.router)
app.include_router(class_routes.router)
app.include_router(attendance_routes.router)
app.include_router(notification_routes.router)


@app.get("/health")
def health_check():
    return {"status": "ok", "model_ready": scanner.ready,
            "class_active": bool(A.active)}


@app.get("/")
def root():
    return {"name": "AtClam API", "docs": "/docs", "health": "/health"}

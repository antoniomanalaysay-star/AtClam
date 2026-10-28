from fastapi import FastAPI
from db import get_connection

app = FastAPI()

@app.get("/users")
def get_users():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, email FROM users")
            columns = [col.name for col in cur.description]
            return [dict(zip(columns, row)) for row in cur.fetchall()]

@app.get("/users/{email}")
def get_user_by_email(email: str):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name, email FROM users WHERE email = %s",
                (email,),
            )
            row = cur.fetchone()
            return dict(zip([c.name for c in cur.description], row)) if row else None
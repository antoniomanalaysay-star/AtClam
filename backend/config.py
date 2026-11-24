"""Settings for the AtClam backend (face recognition, camera and attendance)."""
from pathlib import Path

BASE = Path(__file__).resolve().parent
DATA = BASE / "data"
FACES = DATA / "faces"
AVATARS = DATA / "avatars"
DB_PATH = DATA / "attendance.db"
SECRET_PATH = DATA / ".jwt_secret"

# ---- recognition (evaluate.py helps you choose these) ----
MATCH_THRESHOLD = 0.40   # cosine similarity needed to call it a known person
MATCH_MARGIN = 0.05      # best match must beat 2nd best (protects against lookalikes)
SAME_PERSON_MIN = 0.30   # the 3 enrollment photos must agree with each other

# ---- stability ----
RECOGNIZE_EVERY = 2      # run recognition on every Nth frame of a tracked face
VOTE_WINDOW = 4          # look at the last N recognition results...
VOTES_NEEDED = 2         # ...and require this many to agree before trusting it

# ---- liveness (blocks still photos / faces held up on a phone screen) ----
REQUIRE_BLINK = True
BLINK_DROP = 0.72
BLINK_HISTORY_FRAMES = 5  # enough baseline without making the first scan slow
LIVE_SECONDS = 14        # a blink counts as "live" for this many seconds
REQUIRE_FACE_MOTION = True
MOTION_FRAMES = 2        # real faces shift slightly; static screen faces do not
MOTION_SECONDS = 2.5
MIN_REL_MOTION = 0.002   # 0.2% of the face height between frames

# ---- camera / detection ----
CAMERA_W, CAMERA_H = 1280, 720
MAX_FRAME_WIDTH = 720    # web frames already arrive at this size; keep models light
DETECTION_CONF = 0.5     # lower so mid-back / darker faces are still detected
MIN_TRACK_CONF = 0.5
MIN_FACE_PX = 32         # same face/height ratio as 42px at 960, but cheaper
MAX_FACES = 10           # a classroom row, not the whole room
FRAMES_TO_LOSE = 12      # frames a face may vanish before the track is dropped

# ---- low-light enhancement ----
ENHANCE_DARK_FRAMES = True
DARK_LAB_MEAN = 120      # LAB L channel below this is treated as low light
VERY_DARK_LAB_MEAN = 78
CLAHE_CLIP = 2.5
CLAHE_GRID = (8, 8)

# ---- attendance ----
LATE_AFTER_MIN = 15      # fallback when a class has no configured times

# ---- server ----
HOST = "0.0.0.0"
PORT = 8000

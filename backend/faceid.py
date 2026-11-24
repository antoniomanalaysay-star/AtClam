"""Face models and helpers shared by app.py and evaluate.py."""
import threading
import urllib.request
from collections import deque
from pathlib import Path

import cv2
import mediapipe as mp
import numpy as np

import config as C

BASE = Path(__file__).parent
MODEL_PATH = BASE / "models" / "face_recognition_sface_2021dec.onnx"
MODEL_URL = ("https://github.com/opencv/opencv_zoo/raw/main/models/"
             "face_recognition_sface/face_recognition_sface_2021dec.onnx")

# Face Mesh point numbers
FOREHEAD, CHIN, NOSE = 10, 152, 1
MOUTH_TOP, MOUTH_BOTTOM = 13, 14
MOUTH_CORNER_R, MOUTH_CORNER_L = 61, 291
EYE_OUTER_R, EYE_OUTER_L = 33, 263
RIGHT_EYE = [33, 160, 158, 133, 153, 144]
LEFT_EYE = [362, 385, 387, 263, 373, 380]

# Kept for the basic face checks; the app now draws the full dense mesh.
LANDMARK_IDS = [10, 152, 1, 33, 133, 362, 263, 13, 14, 61, 291, 234, 454]
LANDMARK_COUNT = len(LANDMARK_IDS)

# Same contour/iris sets used by face-check's draw_mesh(). Sent once with each
# frame so the Flutter overlay traces the real face shape instead of 13 dots.
_MESH = mp.solutions.face_mesh
MESH_CONTOURS_FLAT = [i for edge in _MESH.FACEMESH_CONTOURS for i in edge]
MESH_IRISES_FLAT = [i for edge in _MESH.FACEMESH_IRISES for i in edge]

_rec = None
_lock = threading.Lock()


def load_model():
    """Load SFace (downloads it once if models/ doesn't have it). Returns True if ready."""
    global _rec
    if not MODEL_PATH.exists():
        MODEL_PATH.parent.mkdir(exist_ok=True)
        try:
            print("Downloading face recognition model (~37 MB)...")
            urllib.request.urlretrieve(MODEL_URL, MODEL_PATH)
        except Exception as e:
            MODEL_PATH.unlink(missing_ok=True)
            print(f"Could not download the model ({e}).\nSave it manually from:\n  {MODEL_URL}\nto:\n  {MODEL_PATH}")
            return False
    _rec = cv2.FaceRecognizerSF.create(str(MODEL_PATH), "")
    return True


def ready():
    return _rec is not None


def unit(v):
    v = np.asarray(v, dtype=np.float32).flatten()
    return v / (np.linalg.norm(v) + 1e-9)


def points(landmarks, w, h):
    return np.array([[p.x * w, p.y * h] for p in landmarks.landmark])


def enhance_frame(bgr):
    """Downscale for speed and lift dark frames before detection/recognition."""
    if bgr is None:
        return None
    h, w = bgr.shape[:2]
    if C.MAX_FRAME_WIDTH and w > C.MAX_FRAME_WIDTH:
        scale = C.MAX_FRAME_WIDTH / float(w)
        bgr = cv2.resize(
            bgr, None, fx=scale, fy=scale, interpolation=cv2.INTER_AREA
        )
    if not C.ENHANCE_DARK_FRAMES:
        return bgr

    lab = cv2.cvtColor(bgr, cv2.COLOR_BGR2LAB)
    light, a, b = cv2.split(lab)
    mean_light = float(light.mean())
    if mean_light < C.DARK_LAB_MEAN:
        clahe = cv2.createCLAHE(
            clipLimit=C.CLAHE_CLIP, tileGridSize=C.CLAHE_GRID
        )
        light = clahe.apply(light)
        if mean_light < C.VERY_DARK_LAB_MEAN:
            light = cv2.convertScaleAbs(light, alpha=1.25, beta=8)
        bgr = cv2.cvtColor(cv2.merge([light, a, b]), cv2.COLOR_LAB2BGR)
    return bgr


def mesh_layout():
    """Connection indices for the dense face overlay."""
    return {"contours": MESH_CONTOURS_FLAT, "irises": MESH_IRISES_FLAT}


def overlay_landmarks(pts, w, h):
    """All FaceMesh points as flat normalized pairs: [x0, y0, x1, y1, ...]."""
    out = []
    for x, y in pts[:, :2]:
        out.append(round(float(x / w), 4))
        out.append(round(float(y / h), 4))
    return out


def plausible_face(pts):
    """Rejects things that aren't arranged like a face: chin < mouth < nose < eyes < forehead."""
    up = pts[FOREHEAD] - pts[CHIN]
    height = np.linalg.norm(up)
    if height < C.MIN_FACE_PX:
        return False
    u = up / height

    def t(i):
        return float(np.dot(pts[i] - pts[CHIN], u) / height)

    mouth = (t(MOUTH_TOP) + t(MOUTH_BOTTOM)) / 2
    eyes = (t(EYE_OUTER_R) + t(EYE_OUTER_L)) / 2
    if not (0.0 < mouth < t(NOSE) < eyes < 1.2):
        return False
    ratio = np.linalg.norm(pts[EYE_OUTER_R] - pts[EYE_OUTER_L]) / height
    return 0.3 <= ratio <= 1.1


def eye_openness(pts, idx):
    p = [pts[i] for i in idx]
    horizontal = np.linalg.norm(p[0] - p[3])
    if horizontal < 1e-6:
        return 0.0
    return (np.linalg.norm(p[1] - p[5]) + np.linalg.norm(p[2] - p[4])) / (2 * horizontal)


def openness(pts):
    return (eye_openness(pts, RIGHT_EYE) + eye_openness(pts, LEFT_EYE)) / 2


class BlinkTracker:
    """Notices when the eyes close and reopen (a blink)."""

    def __init__(self):
        self.history = deque(maxlen=90)
        self.closed = False
        self.last_blink = None

    def update(self, value, now):
        self.history.append(value)
        if len(self.history) < C.BLINK_HISTORY_FRAMES:
            return
        baseline = float(np.percentile(self.history, 90))
        if baseline < 0.15:
            return
        if value < baseline * C.BLINK_DROP:
            self.closed = True
        elif self.closed and value > baseline * 0.88:
            self.closed = False
            self.last_blink = now

    def is_live(self, now):
        return self.last_blink is not None and now - self.last_blink <= C.LIVE_SECONDS


def face_row(pts):
    x0, y0 = pts.min(axis=0)
    x1, y1 = pts.max(axis=0)
    row = [x0, y0, x1 - x0, y1 - y0,
           *pts[RIGHT_EYE].mean(axis=0), *pts[LEFT_EYE].mean(axis=0),
           *pts[NOSE], *pts[MOUTH_CORNER_R], *pts[MOUTH_CORNER_L], 1.0]
    return np.array([row], dtype=np.float32)


def embed(bgr, pts):
    """Turn one face into 128 numbers (the 'embedding'). Returns (unit_vector, aligned_crop)."""
    with _lock:
        aligned = _rec.alignCrop(bgr, face_row(pts))
        return unit(_rec.feature(aligned)), aligned


def embed_photo(img, mesh):
    """Embedding for one enrollment/test photo. Returns (embedding, crop, error_or_None)."""
    h, w = img.shape[:2]
    scale = 1280 / max(h, w)
    if scale < 1:
        img = cv2.resize(img, None, fx=scale, fy=scale, interpolation=cv2.INTER_AREA)
        h, w = img.shape[:2]
    res = mesh.process(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    if not res.multi_face_landmarks:
        return None, None, "no face found"
    if len(res.multi_face_landmarks) > 1:
        return None, None, "more than one face in the photo"
    pts = points(res.multi_face_landmarks[0], w, h)
    if not plausible_face(pts):
        return None, None, "face is too small or unclear"
    feat, crop = embed(img, pts)
    return feat, crop, None


def identify(feat, people):
    """Best-matching student id, or None if nobody matches (or two students match too closely)."""
    scores = sorted(((max(float(np.dot(feat, e)) for e in p["embeddings"]), p["id"]) for p in people),
                    reverse=True)
    if not scores or scores[0][0] < C.MATCH_THRESHOLD:
        return None
    if len(scores) > 1 and scores[1][0] >= C.MATCH_THRESHOLD \
            and scores[0][0] - scores[1][0] < C.MATCH_MARGIN:
        return None   # lookalike / twin: don't guess
    return scores[0][1]

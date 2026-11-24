"""Live camera scanning: receives phone frames, recognises students, marks attendance."""
import threading
import time
from collections import Counter, deque

import cv2
import mediapipe as mp
import numpy as np

import attendance_state as A
import config as C
import faceid as F
from face_utils import decode_image, load_people


class Track:
    def __init__(self):
        self.c = None
        self.prev_c = None
        self.motion = deque(maxlen=C.MOTION_FRAMES)
        self.blink = F.BlinkTracker()
        self.votes = deque(maxlen=C.VOTE_WINDOW)
        self.who = None
        self.n = 0
        self.missed = 0

    def update_motion(self, centre, size, now):
        """A real face moves slightly; a photo held on a phone screen usually doesn't."""
        if self.prev_c is not None:
            shift = float(np.linalg.norm(centre - self.prev_c)) / max(float(size), 1.0)
            self.motion.append((now, shift))
        self.prev_c = np.asarray(centre, dtype=np.float32).copy()

    def has_motion(self, now):
        if not C.REQUIRE_FACE_MOTION:
            return True
        recent = [shift for t, shift in self.motion
                  if now - t <= C.MOTION_SECONDS]
        return (len(recent) >= C.MOTION_FRAMES and
                sum(recent) >= C.MIN_REL_MOTION * C.MOTION_FRAMES)


class Scanner:
    """One scanner per server; tracks are separated by the instructor's id."""

    def __init__(self):
        self._mesh = None
        self._mesh_lock = threading.RLock()
        self._people = []
        self._people_at = 0.0
        self._tracks = {}
        self._next_id = 0

    def load(self) -> bool:
        ok = F.load_model()
        if ok:
            self.refresh_people()
        return ok

    def refresh_people(self):
        self._people = load_people()

    def reset(self, owner_id):
        """Forget tracked faces when a class starts or ends."""
        self._tracks.pop(owner_id, None)

    @property
    def ready(self) -> bool:
        return F.ready()

    def _people_now(self):
        if time.time() - self._people_at > 5 or not self._people:
            self.refresh_people()
            self._people_at = time.time()
        return self._people

    def _ensure_mesh(self):
        if self._mesh is None:
            self._mesh = mp.solutions.face_mesh.FaceMesh(
                max_num_faces=C.MAX_FACES,
                refine_landmarks=True,
                min_detection_confidence=C.DETECTION_CONF,
                min_tracking_confidence=C.MIN_TRACK_CONF,
            )
        return self._mesh

    def process(self, owner_id, raw):
        """Analyse one JPEG frame and return faces + the current roster."""
        if not A.active:
            raise ValueError("Start a class before scanning.")
        raw_frame = decode_image(raw)
        if raw_frame is None:
            raise ValueError("That frame isn't a readable image.")
        frame = F.enhance_frame(raw_frame)

        h, w = frame.shape[:2]
        now = time.time()
        with self._mesh_lock:
            result = self._ensure_mesh().process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))

        found = []
        for lm in result.multi_face_landmarks or []:
            pts = F.points(lm, w, h)
            if F.plausible_face(pts):
                found.append(pts)

        tracks = self._tracks.setdefault(owner_id, {})
        used, faces, announced = set(), [], []
        people = self._people_now()
        names = {p["id"]: p["name"] for p in people}
        ids = A.eligible_ids()

        for pts in found:
            centre = pts[F.NOSE]
            size = np.linalg.norm(pts[F.FOREHEAD] - pts[F.CHIN])
            near = [(np.linalg.norm(t.c - centre), k)
                    for k, t in tracks.items() if k not in used]
            best = min(near, default=None)
            if best and best[0] < size * 0.6:
                key = best[1]
            else:
                key = self._next_id
                self._next_id += 1
                tracks[key] = Track()
            track = tracks[key]
            used.add(key)
            track.c, track.missed, track.n = centre, 0, track.n + 1
            track.update_motion(centre, size, now)
            track.blink.update(F.openness(pts), now)

            if F.ready() and people and track.n % C.RECOGNIZE_EVERY == 0:
                track.votes.append(F.identify(F.embed(frame, pts)[0], people))
                top, count = Counter(track.votes).most_common(1)[0]
                track.who = None if count < C.VOTES_NEEDED else (top or "unknown")

            live_ok = ((not C.REQUIRE_BLINK) or track.blink.is_live(now)) \
                and track.has_motion(now)
            if track.who is None:
                label, state = "Checking...", "checking"
            elif track.who == "unknown" or track.who not in ids:
                label, state = "Unknown", "unknown"
            elif live_ok:
                name = names.get(track.who, "?")
                label, state = name, "present"
                # Only the first successful mark is announced; mark_present
                # returns None when this student is already in the roster.
                if A.mark_present(track.who) is not None:
                    first = name.split()[0] if name.split() else name
                    announced.append({
                        "id": track.who,
                        "name": name,
                        "first_name": first,
                        "status": "present",
                    })
            else:
                label, state = names.get(track.who, "?") + " · blink", "blink"

            x0, y0 = pts.min(axis=0).astype(int)
            x1, y1 = pts.max(axis=0).astype(int)
            faces.append({
                "name": label,
                "state": state,
                "box": [round(float(x0 / w), 4), round(float(y0 / h), 4),
                        round(float(x1 / w), 4), round(float(y1 / h), 4)],
                "landmarks": F.overlay_landmarks(pts, w, h),
            })

        for key in list(tracks):
            if key not in used:
                tracks[key].missed += 1
                if tracks[key].missed > C.FRAMES_TO_LOSE:
                    del tracks[key]

        snapshot = A.status()
        return {"faces": faces, "roster": snapshot["roster"],
                "session": snapshot["session"], "model_ready": F.ready(),
                "announcements": announced, "mesh_layout": F.mesh_layout()}


scanner = Scanner()

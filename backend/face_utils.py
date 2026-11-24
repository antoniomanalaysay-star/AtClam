"""Face enrollment helpers shared by the auth and scanner modules."""
import json

import cv2
import mediapipe as mp
import numpy as np

import config as C
import faceid as F


def decode_image(raw: bytes):
    return cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)


def process_photos(blobs: list):
    """Turn 3 uploaded photos into embeddings + one crop. Returns (feats, crop, error)."""
    if not F.ready():
        return None, None, "The face model isn't loaded. Check the server console."
    blobs = list(blobs)
    if len(blobs) != 3:
        return None, None, "Please upload exactly 3 photos."
    feats, crops = [], []
    with mp.solutions.face_mesh.FaceMesh(
        static_image_mode=True, max_num_faces=2, min_detection_confidence=0.5
    ) as mesh:
        for i, raw in enumerate(blobs, 1):
            img = decode_image(raw)
            if img is None:
                return None, None, f"Photo {i} isn't a readable image."
            feat, crop, err = F.embed_photo(img, mesh)
            if err:
                return None, None, f"Photo {i}: {err}."
            feats.append(feat)
            crops.append(crop)
    for a in range(3):
        for b in range(a + 1, 3):
            if float(np.dot(feats[a], feats[b])) < C.SAME_PERSON_MIN:
                return None, None, f"Photos {a + 1} and {b + 1} don't look like the same person."
    return feats, crops[0], None


def save_face(pid: str, feats, crop) -> str:
    cv2.imwrite(str(C.FACES / f"{pid}.jpg"), crop)
    return json.dumps([f.tolist() for f in feats])


def load_people():
    """Refresh the in-memory face profiles used by the live scanner."""
    from db import get_connection

    with get_connection() as con:
        return [
            {"id": r["id"], "name": r["name"],
             "embeddings": [F.unit(e) for e in json.loads(r["embeddings"])]}
            for r in con.execute("SELECT * FROM students ORDER BY name")
        ]

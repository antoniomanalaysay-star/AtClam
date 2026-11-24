"""Measure how accurate the recognition is on YOUR classmates and pick a good MATCH_THRESHOLD.

Folder layout (make it with collect_dataset.py, or by hand):
    dataset/Maria/001.jpg 002.jpg 003.jpg 004.jpg ...
    dataset/Juan/001.jpg  ...
Run:  python evaluate.py            (or: python evaluate.py path/to/dataset)

For each person, the first 3 photos play the role of 'enrollment'. All remaining photos are tests."""
import csv
import sys
from pathlib import Path

import cv2
import mediapipe as mp
import numpy as np

import config as C
import faceid as F

ENROLL_N = 3
EXT = {".jpg", ".jpeg", ".png"}


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dataset")
    if not root.is_dir():
        sys.exit(f"Folder '{root}' not found. Run collect_dataset.py first.")
    if not F.load_model():
        sys.exit("Face model missing.")

    data = {}
    with mp.solutions.face_mesh.FaceMesh(static_image_mode=True, max_num_faces=2,
                                         min_detection_confidence=0.5) as mesh:
        for d in sorted(p for p in root.iterdir() if p.is_dir()):
            for f in sorted(d.iterdir()):
                if f.suffix.lower() not in EXT:
                    continue
                img = cv2.imread(str(f))
                feat, _, err = F.embed_photo(img, mesh) if img is not None else (None, None, "unreadable")
                if err:
                    print(f"  skipped {d.name}/{f.name}: {err}")
                else:
                    data.setdefault(d.name, []).append(feat)
    data = {k: v for k, v in data.items() if len(v) > ENROLL_N}
    if len(data) < 2:
        sys.exit(f"Need at least 2 people with {ENROLL_N + 1}+ usable photos each.")

    enrolled = {p: v[:ENROLL_N] for p, v in data.items()}
    genuine, best_other, impostor = [], [], []   # impostor: (score, tested person, other person)
    for p, v in data.items():
        for e in v[ENROLL_N:]:
            sc = {q: max(float(e @ x) for x in enrolled[q]) for q in enrolled}
            others = {q: s for q, s in sc.items() if q != p}
            genuine.append(sc[p])
            best_other.append(max(others.values()))
            impostor += [(s, p, q) for q, s in others.items()]
    gen, oth = np.array(genuine), np.array(best_other)
    imp = np.array([i[0] for i in impostor])

    rows = []
    for t in np.arange(0.10, 0.801, 0.01):
        rows.append((round(float(t), 2),
                     float((imp >= t).mean()),                        # FAR: wrong person accepted
                     float((gen < t).mean()),                         # FRR: right person rejected
                     float(((gen >= t) & (gen > oth)).mean()),        # identified correctly
                     float(((oth >= t) & (oth >= gen)).mean())))      # identified as the wrong person

    print(f"\nPeople: {len(data)}   test photos: {len(gen)}   impostor comparisons: {len(imp)}")
    print("\n thr    FAR     FRR    correct  wrong-person  missed")
    for r in rows:
        if round(r[0] * 100) % 5 == 0:
            print(f" {r[0]:.2f}  {r[1]:6.1%}  {r[2]:6.1%}  {r[3]:7.1%}  {r[4]:11.1%}  {1 - r[3] - r[4]:6.1%}")

    ok = [r for r in rows if r[1] <= 0.01]
    rec = ok[0] if ok else min(rows, key=lambda r: abs(r[1] - r[2]))
    print(f"\nRecommended MATCH_THRESHOLD = {rec[0]:.2f}  (FAR {rec[1]:.1%}, FRR {rec[2]:.1%})")
    print(f"Your config.py currently uses {C.MATCH_THRESHOLD:.2f}")
    print("\nMost similar different-people pairs (lookalikes/twins show up here):")
    seen = set()
    for s, a, b in sorted(impostor, reverse=True):
        if frozenset((a, b)) not in seen and len(seen) < 5:
            seen.add(frozenset((a, b)))
            print(f"  {a} vs {b}: {s:.2f}")
    if len(gen) < 30:
        print("\nNote: very few test photos, so treat these numbers as rough. More photos = more trustworthy.")

    with open("evaluation_report.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["threshold", "FAR", "FRR", "correct", "wrong_person"])
        w.writerows(rows)
    print("\nFull table saved to evaluation_report.csv (open in Excel to make a graph for your paper).")


if __name__ == "__main__":
    main()

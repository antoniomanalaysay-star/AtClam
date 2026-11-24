"""Take test photos of a person with the webcam.  Run:  python collect_dataset.py
SPACE saves a photo, Q quits.  Photos go to dataset/<name>/001.jpg, 002.jpg, ...
Take 8-10 photos per person: different angles, lighting, with/without glasses, distance."""
from pathlib import Path

import cv2

name = input("Person's name: ").strip()
out = Path("dataset") / name
out.mkdir(parents=True, exist_ok=True)
n = len(list(out.glob("*.jpg")))
cap = cv2.VideoCapture(0)
while True:
    ok, frame = cap.read()
    if not ok:
        break
    show = frame.copy()
    cv2.putText(show, f"{name}: {n} saved   SPACE=save  Q=quit", (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
    cv2.imshow("collect", show)
    k = cv2.waitKey(1) & 0xFF
    if k == 32:
        n += 1
        cv2.imwrite(str(out / f"{n:03d}.jpg"), frame)
    elif k in (ord("q"), 27):
        break
cap.release()
cv2.destroyAllWindows()

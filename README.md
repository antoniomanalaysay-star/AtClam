# AtClam — Classroom Attendance and Management

AtClam is now a **Flutter app + Python API**:

- `lib/` — Flutter UI (admin, instructor, student) and camera scanner
- `backend/` — FastAPI server, SQLite database, face recognition and liveness
- `backend/data/` — existing attendance data, face profiles and avatars (preserved from the old Flask app)

The old Flask HTML pages were removed, but their **desktop layout and flows were rebuilt in Flutter**:
a top bar and side navigation, class cards, Announcements / Students & Attendance / Attendance times /
Live camera tabs, monthly calendars, and the original Student/Instructor signup (no school ID field).
The same Flutter app runs on the phone, where the instructor uses the camera scanner.

---

## 1. Run the backend

Use Python 3.10+ from the `backend/` folder:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env               # optional
python3 -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Check it:

```bash
curl http://127.0.0.1:8000/health
# {"status":"ok","model_ready":true,"class_active":false}
```

Interactive API docs are at <http://localhost:8000/docs>.

The SFace model in `backend/models/` is used automatically. If it is missing, the server downloads it on first start (needs internet).

### Admin login

The preserved database already has:

```
Username: ThirdyAdmin
Password: Admin123
```

A brand-new database seeds `admin@classroom.local / Admin123`. Create more admins with:

```bash
python3 seed_admin.py "Admin Name" admin@school.edu "a-strong-password"
```

---

## 2. Run the Flutter app

From the project root:

```bash
flutter pub get
```

### Web

```bash
flutter run -d chrome
# or
flutter build web --no-tree-shake-icons
```

The web build defaults to `http://localhost:8000` and is verified. Management screens work in the browser; live attendance scanning is intended for the instructor's phone.

### Phone / emulator

```bash
flutter run
```

Defaults:

| Target | Backend URL used |
| --- | --- |
| Web browser | `http://localhost:8000` |
| Android emulator | `http://10.0.2.2:8000` |
| iOS simulator | `http://localhost:8000` |

For a **real phone**, `localhost` means the phone itself, so point it at the computer running the backend:

1. Start uvicorn with `--host 0.0.0.0` and make sure port `8000` is allowed through the computer's firewall.
2. Connect the phone and computer to the same Wi-Fi.
3. Find the computer's LAN IP, e.g. `192.168.1.10` (`ipconfig getifaddr en0` on macOS).
4. In the app, open the **account menu → Server address** and enter `http://192.168.1.10:8000`.
5. Log in again to refresh the session.

You can also bake the address in at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

The camera permission is requested by the `camera` plugin when the scanner opens.

---

## 3. Take attendance

1. **Sign up**: choose **Student** or **Instructor**, enter name / username / email / password. Only students add 3 face photos; there is no school ID field. Instructors can also be created by an admin from **People & classes → Add new**.
2. **Instructor**: on **My classes**, click **New class**, set **Start / Present / Late / End** times (`HH:MM`) and share the class code.
3. **Student**: on **My classes**, click **Join a class** and enter the code. Students who skipped photos can add them from the face-registration card.
4. **Instructor**: open a class → **Live camera** tab → **Start class & detection**, then **Open phone scanner** on the instructor's phone.
5. Hold the phone so the whole group is visible. Students are recognised and each student blinks once to confirm liveness.
6. Tap **End class**. Anyone not seen is saved as **Absent** (unless they have an approved excuse). **Students & Attendance** shows each student's calendar; **Announcements** and excuse notes work as before.

Present/Late is decided from the class times; without configured times the legacy 15-minute fallback is used.

---

## 4. Data and recovery

- Database: `backend/data/attendance.db` (SQLite, WAL enabled)
- Face photos: `backend/data/faces/`
- Avatars: `backend/data/avatars/`
- Reference schema: `backend/database/schema.sql` (regenerated after migrations)

Back up the whole `backend/data/` folder. Schema changes and the `school_id` / `is_active` columns are applied automatically at startup; no manual migration is required.

See `backend/README.md` for API details.

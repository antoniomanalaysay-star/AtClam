-- One database role per system role (no direct login)
CREATE ROLE app_admin NOLOGIN;
CREATE ROLE app_instructor NOLOGIN;
CREATE ROLE app_student NOLOGIN;

GRANT USAGE ON SCHEMA public TO app_admin, app_instructor, app_student;

-- Admin: full control
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_admin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_admin;

-- Instructor: manage sessions, read/correct attendance
GRANT SELECT ON users, classes, class_schedules, enrollments TO app_instructor;
GRANT SELECT, INSERT, UPDATE ON attendance_sessions TO app_instructor;
GRANT SELECT, UPDATE ON attendance_records TO app_instructor;

-- Student: read own context, record attendance
GRANT SELECT ON classes, class_schedules, enrollments, attendance_sessions TO app_student;
GRANT SELECT, INSERT ON attendance_records TO app_student;

-- Face templates: sensitive, so tightly limited
GRANT SELECT, INSERT ON face_templates TO app_student;
REVOKE ALL ON face_templates FROM app_instructor;
REVOKE DELETE ON attendance_records FROM app_instructor;
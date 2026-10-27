
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final String role;

  const DashboardScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'Admin';
    final isInstructor = role == 'Instructor';

    final title = isAdmin
        ? 'Admin Dashboard'
        : isInstructor
            ? 'Instructor Dashboard'
            : 'Student Dashboard';

    final subtitle = isAdmin
        ? 'Manage users, classes, and system settings.'
        : isInstructor
            ? 'Manage your classes and attendance sessions.'
            : 'View your classes and attendance records.';

    final items = isAdmin
        ? [
            _DashboardItem(Icons.people_outline, 'Manage Users',
                'View and manage student and instructor accounts.'),
            _DashboardItem(Icons.class_outlined, 'Manage Classes',
                'Organize subjects and class assignments.'),
            _DashboardItem(Icons.analytics_outlined, 'Reports',
                'Review attendance summaries and reports.'),
          ]
        : isInstructor
            ? [
                _DashboardItem(Icons.menu_book_outlined, 'My Classes',
                    'View your assigned subjects.'),
                _DashboardItem(Icons.camera_alt_outlined, 'Attendance Session',
                    'Start or end a classroom attendance session.'),
                _DashboardItem(Icons.people_outline, 'Enrolled Students',
                    'View students enrolled in your classes.'),
              ]
            : [
                _DashboardItem(Icons.class_outlined, 'My Classes',
                    'View your enrolled subjects.'),
                _DashboardItem(Icons.fact_check_outlined, 'My Attendance',
                    'Review your attendance history.'),
                _DashboardItem(Icons.face_outlined, 'Face Verification',
                    'Prepare your face profile for recognition.'),
              ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AT CLAM'),
        backgroundColor: const Color(0xFF167D56),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Welcome, $role!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 28),
            const Text(
              'OVERVIEW',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Color(0xFF167D56),
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 14),
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE5F3EC),
                    child: Icon(item.icon, color: const Color(0xFF167D56)),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(item.description),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.title} will be implemented next.'),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF167D56)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is a UI prototype. Live attendance and '
                        'database features are not connected yet.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardItem {
  final IconData icon;
  final String title;
  final String description;

  const _DashboardItem(this.icon, this.title, this.description);
}

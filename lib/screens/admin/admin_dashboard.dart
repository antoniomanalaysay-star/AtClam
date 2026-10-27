import 'package:flutter/material.dart';

import '../auth/login_screen.dart';

/// Admin dashboard. All numbers below are SAMPLE DATA for the design.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      roleLabel: 'Admin',
      username: username,
      mainMenu: const [
        NavEntry(Icons.home_outlined, 'Dashboard'),
        NavEntry(Icons.people_outline, 'Users'),
        NavEntry(Icons.menu_book_outlined, 'Classes'),
        NavEntry(Icons.fact_check_outlined, 'Attendance Records'),
        NavEntry(Icons.bar_chart_outlined, 'Reports'),
      ],
      pageTitle: 'Dashboard',
      pageSubtitle: "Welcome back! Here's an overview of the system.",
      children: [
        WelcomeCard(
          title: 'Welcome back, $username! 👋',
          message: 'Manage users and system information from here.',
        ),
        const SizedBox(height: 25),
        const ResponsiveGrid(
          minItemWidth: 220,
          children: [
            StatCard(
                icon: Icons.people_outline, label: 'Total Users', value: '248'),
            StatCard(
                icon: Icons.menu_book_outlined,
                label: 'Instructors',
                value: '12'),
            StatCard(
                icon: Icons.school_outlined, label: 'Students', value: '235'),
            StatCard(
                icon: Icons.play_circle_outline,
                label: 'Active Sessions',
                value: '2'),
          ],
        ),
        const SizedBox(height: 30),
        const SectionHeader(title: 'Management', actionLabel: 'View All →'),
        const SizedBox(height: 15),
        const ResponsiveGrid(
          minItemWidth: 260,
          children: [
            InfoCard(
              tone: 0,
              code: 'US',
              title: 'Users',
              subtitle: 'Add, edit, and remove accounts',
              footer: '248 accounts',
              buttonLabel: 'Manage',
            ),
            InfoCard(
              tone: 1,
              code: 'CL',
              title: 'Classes',
              subtitle: 'View all classes and schedules',
              footer: '18 classes',
              buttonLabel: 'Manage',
            ),
            InfoCard(
              tone: 2,
              code: 'RP',
              title: 'Reports',
              subtitle: 'Attendance summaries by class',
              footer: 'Updated daily',
              buttonLabel: 'Open',
            ),
          ],
        ),
        const SizedBox(height: 30),
        const TwoColumn(
          left: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Recent Users', actionLabel: 'View All'),
                SizedBox(height: 8),
                TagTile(
                  tag: 'Student',
                  title: 'Maria Santos',
                  subtitle: 'Registered today',
                ),
                TagTile(
                  tag: 'Instructor',
                  title: 'Juan Dela Cruz',
                  subtitle: 'Registered yesterday',
                ),
                TagTile(
                  tag: 'Student',
                  title: 'Ana Reyes',
                  subtitle: 'Registered 2 days ago',
                  last: true,
                ),
              ],
            ),
          ),
          right: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Activity', actionLabel: 'View All'),
                SizedBox(height: 8),
                TagTile(
                  tag: 'System',
                  title: 'New class added: DB 210',
                  subtitle: 'Today',
                ),
                TagTile(
                  tag: 'System',
                  title: 'Instructor account created',
                  subtitle: 'Yesterday',
                  last: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
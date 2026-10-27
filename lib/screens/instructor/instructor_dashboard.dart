import 'package:flutter/material.dart';

import '../auth/login_screen.dart';

/// Instructor dashboard. All numbers below are SAMPLE DATA for the design.
class InstructorDashboard extends StatelessWidget {
  const InstructorDashboard({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      roleLabel: 'Instructor',
      username: username,
      mainMenu: const [
        NavEntry(Icons.home_outlined, 'Dashboard'),
        NavEntry(Icons.menu_book_outlined, 'My Classes'),
        NavEntry(Icons.play_circle_outline, 'Attendance Sessions'),
        NavEntry(Icons.fact_check_outlined, 'Attendance Records'),
        NavEntry(Icons.calendar_month_outlined, 'Schedule'),
      ],
      pageTitle: 'Dashboard',
      pageSubtitle: "Welcome back! Here's what's happening in your classes.",
      children: [
        WelcomeCard(
          title: 'Welcome back, $username! 👋',
          message: 'Manage your classes, sessions, and attendance records.',
        ),
        const SizedBox(height: 25),
        const ResponsiveGrid(
          minItemWidth: 220,
          children: [
            StatCard(
                icon: Icons.menu_book_outlined,
                label: 'My Classes',
                value: '4'),
            StatCard(
                icon: Icons.play_circle_outline,
                label: 'Sessions Today',
                value: '2'),
            StatCard(
                icon: Icons.groups_outlined,
                label: 'Enrolled Students',
                value: '112'),
            StatCard(
                icon: Icons.percent, label: 'Avg. Attendance', value: '91%'),
          ],
        ),
        const SizedBox(height: 30),
        const SectionHeader(title: 'My Classes', actionLabel: 'View All →'),
        const SizedBox(height: 15),
        const ResponsiveGrid(
          minItemWidth: 260,
          children: [
            InfoCard(
              tone: 0,
              code: 'IT',
              title: 'IT 101 – Programming 1',
              subtitle: 'Mon & Wed • 8:00 AM • Room 204',
              footer: '32 students',
              buttonLabel: 'Open',
            ),
            InfoCard(
              tone: 1,
              code: 'NT',
              title: 'NET 201 – Networking',
              subtitle: 'Tue & Thu • 10:00 AM • Lab 2',
              footer: '28 students',
              buttonLabel: 'Open',
            ),
            InfoCard(
              tone: 2,
              code: 'DB',
              title: 'DB 210 – Databases',
              subtitle: 'Wed & Fri • 1:00 PM • Lab 1',
              footer: '30 students',
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
                SectionHeader(title: "Today's Sessions", actionLabel: 'View All'),
                SizedBox(height: 8),
                DateTile(
                  day: '28',
                  month: 'Oct',
                  title: 'IT 101 – Programming 1',
                  subtitle: '8:00 AM • Room 204 • Not started',
                ),
                DateTile(
                  day: '28',
                  month: 'Oct',
                  title: 'DB 210 – Databases',
                  subtitle: '1:00 PM • Lab 1 • Not started',
                  last: true,
                ),
              ],
            ),
          ),
          right: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                    title: 'Recent Attendance', actionLabel: 'View All'),
                SizedBox(height: 8),
                TagTile(
                  tag: 'Oct 27',
                  title: 'NET 201 – 26 present, 1 late, 1 absent',
                  subtitle: 'Session closed',
                ),
                TagTile(
                  tag: 'Oct 26',
                  title: 'IT 101 – 29 present, 2 late, 1 absent',
                  subtitle: 'Session closed',
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
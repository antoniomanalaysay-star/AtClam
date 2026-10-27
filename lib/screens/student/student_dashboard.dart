import 'package:flutter/material.dart';

import '../auth/login_screen.dart';

/// Student dashboard. All numbers below are SAMPLE DATA for the design.
class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      roleLabel: 'Student',
      username: username,
      mainMenu: const [
        NavEntry(Icons.home_outlined, 'Dashboard'),
        NavEntry(Icons.menu_book_outlined, 'My Classes'),
        NavEntry(Icons.fact_check_outlined, 'My Attendance'),
        NavEntry(Icons.calendar_month_outlined, 'Schedule'),
        NavEntry(Icons.campaign_outlined, 'Announcements'),
      ],
      pageTitle: 'Dashboard',
      pageSubtitle: "Welcome back! Here's your attendance at a glance.",
      children: [
        WelcomeCard(
          title: 'Welcome back, $username! 👋',
          message: 'Check your classes and keep track of your attendance.',
        ),
        const SizedBox(height: 25),
        const ResponsiveGrid(
          minItemWidth: 220,
          children: [
            StatCard(
                icon: Icons.menu_book_outlined,
                label: 'Enrolled Classes',
                value: '5'),
            StatCard(
                icon: Icons.check_circle_outline,
                label: 'Present',
                value: '18'),
            StatCard(
                icon: Icons.schedule, label: 'Late', value: '2'),
            StatCard(
                icon: Icons.cancel_outlined, label: 'Absent', value: '1'),
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
              footer: 'Enrolled',
              buttonLabel: 'View',
            ),
            InfoCard(
              tone: 1,
              code: 'NT',
              title: 'NET 201 – Networking',
              subtitle: 'Tue & Thu • 10:00 AM • Lab 2',
              footer: 'Enrolled',
              buttonLabel: 'View',
            ),
            InfoCard(
              tone: 2,
              code: 'MA',
              title: 'MATH 110 – Discrete Math',
              subtitle: 'Fri • 1:00 PM • Room 105',
              footer: 'Enrolled',
              buttonLabel: 'View',
            ),
          ],
        ),
        const SizedBox(height: 30),
        TwoColumn(
          left: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                    title: 'Recent Attendance', actionLabel: 'View All'),
                const SizedBox(height: 8),
                TagTile(
                  tag: 'Present',
                  tagBackground: TagTile.present.$1,
                  tagForeground: TagTile.present.$2,
                  title: 'IT 101 – Programming 1',
                  subtitle: 'Oct 27 • 8:02 AM',
                ),
                TagTile(
                  tag: 'Late',
                  tagBackground: TagTile.late.$1,
                  tagForeground: TagTile.late.$2,
                  title: 'NET 201 – Networking',
                  subtitle: 'Oct 26 • 10:14 AM',
                ),
                TagTile(
                  tag: 'Absent',
                  tagBackground: TagTile.absent.$1,
                  tagForeground: TagTile.absent.$2,
                  title: 'MATH 110 – Discrete Math',
                  subtitle: 'Oct 23',
                  last: true,
                ),
              ],
            ),
          ),
          right: const Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Announcements', actionLabel: 'View All'),
                SizedBox(height: 8),
                TagTile(
                  tag: 'IT 101',
                  title: 'Quiz moved to Friday',
                  subtitle: 'Posted today',
                ),
                TagTile(
                  tag: 'NET 201',
                  title: 'Bring your laptops to the lab',
                  subtitle: 'Posted yesterday',
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
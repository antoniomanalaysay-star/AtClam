import 'package:flutter/material.dart';

import '../services/session.dart';
import '../theme/app_colors.dart';
import '../theme/app_style.dart';
import '../widgets/clam_logo.dart';
import 'admin/admin_dashboard.dart';
import 'auth/login_screen.dart';
import 'instructor/instructor_dashboard.dart';
import 'student/student_dashboard.dart';

/// Decides which screen to show: login, or the dashboard for the user's role.
class HomeGate extends StatelessWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        final session = Session.instance;
        if (!session.ready) return const _Splash();

        final user = session.user;
        if (user == null) return const LoginScreen();

        switch (user.role) {
          case 'admin':
            return const AdminDashboard();
          case 'instructor':
            return const InstructorDashboard();
          default:
            return const StudentDashboard();
        }
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: GlassCard(
          padding: EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClamLogo(size: 96),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppColors.lime),
            ],
          ),
        ),
      ),
    );
  }
}

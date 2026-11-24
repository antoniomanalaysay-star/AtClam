import 'package:flutter/material.dart';

import 'config.dart';
import 'screens/home_gate.dart';
import 'theme/app_colors.dart';
import 'theme/app_style.dart';
import 'services/navigation.dart';
import 'services/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  Session.instance.restore(); // checks for a saved login in the background
  runApp(const AtClamApp());
}

class AtClamApp extends StatelessWidget {
  const AtClamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AT CLAM',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: buildAppTheme(),
      // Paint the background photo once, behind every route and dialog.
      builder: (context, child) =>
          AppBackground(child: child ?? const SizedBox.shrink()),
      home: const HomeGate(),
    );
  }
}

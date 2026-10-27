
import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const AtClamApp());
}

class AtClamApp extends StatelessWidget {
  const AtClamApp({super.key});

  static const green = Color(0xFF167D56);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AT CLAM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E5E2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E5E2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: green, width: 1.5),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

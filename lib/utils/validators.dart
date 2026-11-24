import 'dart:convert';

String? requiredField(String? value, String label) {
  if (value == null || value.trim().isEmpty) return '$label is required';
  return null;
}

String? emailField(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Email is required';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
    return 'Enter a valid email';
  }
  return null;
}

String? passwordField(String? value) {
  final v = value ?? '';
  if (v.length < 8) return 'At least 8 characters';
  if (utf8.encode(v).length > 72) return 'Too long (max 72 bytes)';
  return null;
}

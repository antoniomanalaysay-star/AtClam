import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'api_client.dart';
import 'navigation.dart';

/// Who is logged in. Screens listen to this and switch automatically.
class Session extends ChangeNotifier {
  Session._();

  static final Session instance = Session._();

  static const String _tokenKey = 'access_token';

  final ApiClient _api = ApiClient.instance;

  AppUser? user;
  bool ready = false;

  Future<void> restore() async {
    _api.onUnauthorized = _onTokenRejected;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);

    if (saved != null) {
      _api.token = saved;
      try {
        final data = await _api.get('/auth/me');
        user = AppUser.fromJson(data as Map<String, dynamic>);
      } on ApiException catch (e) {
        _api.token = null;
        if (e.statusCode == 401) await prefs.remove(_tokenKey);
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    await _start(data as Map<String, dynamic>);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? username,
    String? schoolId,
  }) async {
    final data = await _api.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'username': username,
      'school_id': schoolId,
    });
    await _start(data as Map<String, dynamic>);
  }

  /// Re-fetch the account after a profile / face-photo change.
  Future<void> refresh() async {
    final data = await _api.get('/auth/me');
    user = AppUser.fromJson(data as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> logout() async {
    rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    _api.token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
  }

  Future<void> _start(Map<String, dynamic> data) async {
    final token = data['access_token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _api.token = token;
    user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  void _onTokenRejected() => logout();
}

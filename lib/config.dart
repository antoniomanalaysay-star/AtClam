import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the Flutter app finds the Python backend.
///
/// Defaults work for the web browser and the Android/iOS simulators. On a real
/// phone, open the account menu -> "Server address" and enter the computer's
/// LAN address, e.g. http://192.168.1.10:8000
/// You can also build with: --dart-define=API_BASE_URL=http://192.168.1.10:8000
class AppConfig {
  AppConfig._();

  static const String _urlKey = 'api_base_url';
  static const String _compiled = String.fromEnvironment('API_BASE_URL');
  static String? _saved;

  static String get defaultUrl {
    if (_compiled.isNotEmpty) return _compiled;
    if (kIsWeb) return 'http://localhost:8000';
    // Android emulator maps the host machine to 10.0.2.2; iOS uses localhost.
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://localhost:8000';
  }

  static String get apiBaseUrl {
    final url = _saved ?? defaultUrl;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _saved = prefs.getString(_urlKey);
  }

  static Future<void> setBaseUrl(String url) async {
    var clean = url.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    clean = clean.replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, clean);
    _saved = clean;
  }
}

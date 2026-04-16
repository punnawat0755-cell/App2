import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionMarker {
  AuthSessionMarker._();

  static const String _explicitLoginKey = 'auth_explicit_login_completed';

  static Future<void> markExplicitLoginCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_explicitLoginKey, true);
  }

  static Future<void> clearExplicitLoginMarker() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_explicitLoginKey);
  }

  static Future<bool> canReusePersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_explicitLoginKey) ?? false;
  }
}

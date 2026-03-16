import 'package:shared_preferences/shared_preferences.dart';

class PrivacyService {
  static const _privateProfileKey = 'settings.private_profile';
  static const _analyticsKey = 'settings.analytics_opt_in';
  static const _biometricLockKey = 'settings.biometric_lock';

  Future<Map<String, bool>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'privateProfile': prefs.getBool(_privateProfileKey) ?? false,
      'analyticsEnabled': prefs.getBool(_analyticsKey) ?? true,
      'biometricLockEnabled': prefs.getBool(_biometricLockKey) ?? false,
    };
  }

  Future<void> save({
    required bool privateProfile,
    required bool analyticsEnabled,
    required bool biometricLockEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privateProfileKey, privateProfile);
    await prefs.setBool(_analyticsKey, analyticsEnabled);
    await prefs.setBool(_biometricLockKey, biometricLockEnabled);
  }
}

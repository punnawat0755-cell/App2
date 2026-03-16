import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService {
  static const _pushEnabledKey = 'settings.push_notifications';
  static const _messageEnabledKey = 'settings.message_notifications';
  static const _dailyReminderKey = 'settings.daily_reminder_notifications';

  Future<Map<String, bool>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'pushEnabled': prefs.getBool(_pushEnabledKey) ?? true,
      'messageEnabled': prefs.getBool(_messageEnabledKey) ?? true,
      'dailyReminderEnabled': prefs.getBool(_dailyReminderKey) ?? false,
    };
  }

  Future<void> save({
    required bool pushEnabled,
    required bool messageEnabled,
    required bool dailyReminderEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushEnabledKey, pushEnabled);
    await prefs.setBool(_messageEnabledKey, messageEnabled);
    await prefs.setBool(_dailyReminderKey, dailyReminderEnabled);
  }
}

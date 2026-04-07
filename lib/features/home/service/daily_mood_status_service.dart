import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyMoodStatusService {
  static const String dateKey = 'daily_mood_last_date';
  static const String scoreKey = 'daily_mood_last_score';
  static const String labelKey = 'daily_mood_last_label';
  static const String editUsedDateKey = 'daily_mood_edit_used_date';

  static const List<_MoodCacheEntry> _moodCacheEntries = [
    _MoodCacheEntry(label: 'แย่มาก', score: 0),
    _MoodCacheEntry(label: 'แย่', score: 25),
    _MoodCacheEntry(label: 'เฉยๆ', score: 50),
    _MoodCacheEntry(label: 'ดี', score: 75),
    _MoodCacheEntry(label: 'ดีมาก', score: 100),
  ];

  static String todayAsKey() {
    var now = DateTime.now();
    if (now.hour < 5) {
      now = now.subtract(const Duration(days: 1));
    }

    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static Future<bool> hasAnsweredToday() async {
    final client = Supabase.instance.client;
    final prefs = await SharedPreferences.getInstance();
    final today = todayAsKey();
    if (client.auth.currentUser == null) {
      final savedDate = prefs.getString(dateKey);
      return savedDate == today;
    }

    try {
      final response = await client
          .from('v_my_mood_today')
          .select('mood_level')
          .maybeSingle();
      final moodLevel = response?['mood_level'] as int?;
      if (moodLevel == null) {
        await clearLocalCache();
        return false;
      }

      final cacheEntry = _cacheEntryFromMoodLevel(moodLevel);
      await prefs.setString(dateKey, today);
      await prefs.setInt(scoreKey, cacheEntry.score);
      await prefs.setString(labelKey, cacheEntry.label);
      return true;
    } catch (e) {
      debugPrint('Error checking daily mood status from Supabase: $e');
      await clearLocalCache();
      return false;
    }
  }

  static Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(dateKey);
    await prefs.remove(scoreKey);
    await prefs.remove(labelKey);
    await prefs.remove(editUsedDateKey);
  }

  static _MoodCacheEntry _cacheEntryFromMoodLevel(int moodLevel) {
    final idx = (moodLevel - 1).clamp(0, _moodCacheEntries.length - 1);
    return _moodCacheEntries[idx];
  }
}

class _MoodCacheEntry {
  const _MoodCacheEntry({
    required this.label,
    required this.score,
  });

  final String label;
  final int score;
}

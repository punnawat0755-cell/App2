import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_application_1/features/home/service/daily_mood_status_service.dart';

class DailyMoodStreakService {
  static const int _maxLookBackDays = 730;

  static Future<int> fetchCurrentStreakDays() async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) {
      return 0;
    }

    final effectiveTodayKey = DailyMoodStatusService.todayAsKey();
    final effectiveTodayDate = _parseDateKey(effectiveTodayKey);
    if (effectiveTodayDate == null) {
      return 0;
    }

    final completedDayKeys = <String>{};
    final loadedMonthKeys = <String>{};

    Future<void> loadMonth(DateTime monthDate) async {
      final monthKey = '${monthDate.year}-${monthDate.month}';
      if (loadedMonthKeys.contains(monthKey)) {
        return;
      }

      loadedMonthKeys.add(monthKey);
      try {
        final response = await client.rpc(
          'get_monthly_calendar_data',
          params: {
            'p_year': monthDate.year,
            'p_month': monthDate.month,
          },
        );

        if (response is! List) {
          return;
        }

        for (final row in response) {
          if (row is! Map) {
            continue;
          }

          final rowMap = Map<String, dynamic>.from(row);
          final moodLevel = _tryParseInt(rowMap['mood_level']);
          if (moodLevel == null) {
            continue;
          }

          final dayKey = _normalizeCalendarDateKey(rowMap['calendar_date']);
          if (dayKey.isEmpty || dayKey.compareTo(effectiveTodayKey) > 0) {
            continue;
          }

          completedDayKeys.add(dayKey);
        }
      } catch (e) {
        debugPrint('Error loading monthly mood data for streak: $e');
      }
    }

    await loadMonth(effectiveTodayDate);

    String? latestCompletedDayKey;
    for (final dayKey in completedDayKeys) {
      if (latestCompletedDayKey == null ||
          dayKey.compareTo(latestCompletedDayKey) > 0) {
        latestCompletedDayKey = dayKey;
      }
    }

    if (latestCompletedDayKey == null) {
      return 0;
    }

    final latestCompletedDate = _parseDateKey(latestCompletedDayKey);
    if (latestCompletedDate == null) {
      return 0;
    }

    final daysSinceLatest =
        effectiveTodayDate.difference(latestCompletedDate).inDays;
    if (daysSinceLatest > 1) {
      return 0;
    }

    var streakDays = 0;
    var currentDate = latestCompletedDate;
    while (streakDays < _maxLookBackDays) {
      await loadMonth(currentDate);
      final currentKey = _toDateKey(currentDate);
      if (!completedDayKeys.contains(currentKey)) {
        break;
      }

      streakDays += 1;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streakDays;
  }

  static String _normalizeCalendarDateKey(dynamic rawValue) {
    final parsedDate = _tryParseDate(rawValue);
    if (parsedDate != null) {
      return _toDateKey(parsedDate);
    }

    final rawText = rawValue?.toString().trim() ?? '';
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawText)) {
      return rawText;
    }

    return '';
  }

  static int? _tryParseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _tryParseDate(dynamic rawValue) {
    if (rawValue == null) {
      return null;
    }

    if (rawValue is DateTime) {
      return DateTime(rawValue.year, rawValue.month, rawValue.day);
    }

    final rawText = rawValue.toString().trim();
    if (rawText.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(rawText);
    if (parsed == null) {
      return null;
    }

    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime? _parseDateKey(String key) {
    final parsed = DateTime.tryParse(key);
    if (parsed == null) {
      return null;
    }

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String _toDateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'daily_mood_status_service.dart';

class DailyMissionStreakService {
  static const Duration _cacheTtl = Duration(minutes: 2);
  static DateTime? _lastLoadedAt;
  static String? _lastUserId;
  static int? _cachedStreakDays;
  static Future<int>? _inFlightRequest;

  DailyMissionStreakService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<int> getCurrentStreakDays() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _resetCache();
      return 0;
    }

    final now = DateTime.now();
    final isCacheValid = _lastUserId == user.id &&
        _cachedStreakDays != null &&
        _lastLoadedAt != null &&
        now.difference(_lastLoadedAt!) <= _cacheTtl;
    if (isCacheValid) {
      return _cachedStreakDays!;
    }

    final currentRequest = _inFlightRequest;
    if (currentRequest != null && _lastUserId == user.id) {
      return currentRequest;
    }

    final request = _fetchCurrentStreakDays(user.id);
    _lastUserId = user.id;
    _inFlightRequest = request;
    return request;
  }

  Future<int> _fetchCurrentStreakDays(String userId) async {
    try {
      final today =
          _dateOnly(_parseDateKey(DailyMoodStatusService.todayAsKey()));
      final activeDays = await _loadActiveMoodDays(
        anchor: today,
        monthWindow: 12,
      );
      final answeredToday = await DailyMoodStatusService.hasAnsweredToday();
      if (answeredToday) {
        activeDays.add(today);
      }

      if (activeDays.isEmpty) {
        return _storeCache(userId, 0);
      }

      final yesterday = today.subtract(const Duration(days: 1));
      final anchorDay = activeDays.contains(today)
          ? today
          : (activeDays.contains(yesterday) ? yesterday : null);
      if (anchorDay == null) {
        return _storeCache(userId, 0);
      }

      var streak = 0;
      var cursor = anchorDay;
      while (activeDays.contains(cursor)) {
        streak += 1;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      return _storeCache(userId, streak);
    } catch (error) {
      debugPrint(
          'DailyMissionStreakService.getCurrentStreakDays error: $error');
      return 0;
    } finally {
      if (_lastUserId == userId) {
        _inFlightRequest = null;
      }
    }
  }

  int _storeCache(String userId, int value) {
    _lastUserId = userId;
    _cachedStreakDays = value;
    _lastLoadedAt = DateTime.now();
    return value;
  }

  void _resetCache() {
    _lastUserId = null;
    _cachedStreakDays = null;
    _lastLoadedAt = null;
    _inFlightRequest = null;
  }

  Future<Set<DateTime>> _loadActiveMoodDays({
    required DateTime anchor,
    required int monthWindow,
  }) async {
    final activeDays = <DateTime>{};
    for (var offset = 0; offset < monthWindow; offset++) {
      final targetMonth = DateTime(anchor.year, anchor.month - offset, 1);
      final response = await _client.rpc(
        'get_monthly_calendar_data',
        params: {
          'p_year': targetMonth.year,
          'p_month': targetMonth.month,
        },
      );

      if (response is! List) {
        continue;
      }

      for (final row in response) {
        if (row is! Map<String, dynamic>) {
          continue;
        }

        final moodLevel = _toInt(row['mood_level']);
        if (moodLevel == null) {
          continue;
        }

        final date = _readCalendarDate(row['calendar_date']);
        if (date == null) {
          continue;
        }

        activeDays.add(_dateOnly(date));
      }
    }

    return activeDays;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  DateTime? _readCalendarDate(dynamic value) {
    if (value is DateTime) {
      return value.toLocal();
    }

    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed?.toLocal();
  }

  DateTime _parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      return DateTime.now();
    }

    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final day = int.tryParse(parts[2]) ?? DateTime.now().day;
    return DateTime(year, month, day);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

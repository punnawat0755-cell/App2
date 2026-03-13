import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserModeStatusService {
  static const String dateKey = 'user_mode_last_date';
  static const String modeKey = 'user_mode_current_mode';
  static const String _tableName = 'user_modes';
  static const String _listenerCapabilityTable = 'listener_capability';

  static String todayAsKey() {
    var now = DateTime.now();
    if (now.hour < 5) {
      now = now.subtract(const Duration(days: 1));
    }

    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static Future<bool> hasSelectedModeToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = todayAsKey();
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user != null) {
      try {
        final row = await _fetchModeRow(client, user.id);
        final currentMode = row?['current_mode']?.toString().trim();
        final updatedAt = _readRowDate(row);

        if (currentMode == null || currentMode.isEmpty) {
          await clearLocalCache();
          return false;
        }

        if (updatedAt != null && _dateTimeToKey(updatedAt.toLocal()) != today) {
          await clearLocalCache();
          return false;
        }

        if (updatedAt == null) {
          final savedDate = prefs.getString(dateKey);
          final savedMode = prefs.getString(modeKey);
          return savedDate == today && savedMode == currentMode;
        }

        await prefs.setString(dateKey, today);
        await prefs.setString(modeKey, currentMode);
        return true;
      } catch (e) {
        debugPrint('Error checking user mode status from Supabase: $e');
      }
    }

    final savedDate = prefs.getString(dateKey);
    final savedMode = prefs.getString(modeKey);
    return savedDate == today && savedMode != null && savedMode.isNotEmpty;
  }

  static Future<String?> getCurrentModeToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = todayAsKey();
    final savedDate = prefs.getString(dateKey);
    final savedMode = prefs.getString(modeKey)?.trim();

    if (savedDate == today && savedMode != null && savedMode.isNotEmpty) {
      return savedMode;
    }

    final hasModeToday = await hasSelectedModeToday();
    if (!hasModeToday) {
      return null;
    }

    return prefs.getString(modeKey)?.trim();
  }

  static Future<void> saveCurrentMode(String currentMode) async {
    final normalizedMode = currentMode.trim();
    if (normalizedMode.isEmpty) {
      throw ArgumentError('currentMode must not be empty');
    }

    final prefs = await SharedPreferences.getInstance();
    final today = todayAsKey();
    await prefs.setString(dateKey, today);
    await prefs.setString(modeKey, normalizedMode);

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      return;
    }

    final timestamp = DateTime.now().toUtc().toIso8601String();

    final payloads = <Map<String, dynamic>>[
      {
        'user_id': user.id,
        'current_mode': normalizedMode,
        'updated_at': timestamp,
      },
      {
        'id': user.id,
        'current_mode': normalizedMode,
        'updated_at': timestamp,
      },
      {
        'user_id': user.id,
        'current_mode': normalizedMode,
      },
      {
        'id': user.id,
        'current_mode': normalizedMode,
      },
    ];

    final conflictTargets = ['user_id', 'id', 'user_id', 'id'];
    Object? lastError;

    for (var i = 0; i < payloads.length; i++) {
      try {
        await client
            .from(_tableName)
            .upsert(payloads[i], onConflict: conflictTargets[i]);
        return;
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception(
      'ไม่สามารถบันทึก current_mode ลง user_modes ได้: $lastError',
    );
  }

  static Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(dateKey);
    await prefs.remove(modeKey);
  }

  static Future<bool> isListenerCapable() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      return true;
    }

    final row = await _fetchListenerCapabilityRow(client, user.id);
    final capability = row?['is_capable'];
    if (capability is bool) {
      return capability;
    }

    return true;
  }

  static Future<Map<String, dynamic>?> _fetchModeRow(
    SupabaseClient client,
    String userId,
  ) async {
    final byUserId =
        await _tryFetchRow(client, column: 'user_id', userId: userId);
    if (byUserId != null) {
      return byUserId;
    }

    return _tryFetchRow(client, column: 'id', userId: userId);
  }

  static Future<Map<String, dynamic>?> _fetchListenerCapabilityRow(
    SupabaseClient client,
    String userId,
  ) async {
    return _tryFetchRowFromTable(
      client,
      tableName: _listenerCapabilityTable,
      column: 'user_id',
      userId: userId,
    );
  }

  static Future<Map<String, dynamic>?> _tryFetchRow(
    SupabaseClient client, {
    required String column,
    required String userId,
  }) async {
    return _tryFetchRowFromTable(
      client,
      tableName: _tableName,
      column: column,
      userId: userId,
    );
  }

  static Future<Map<String, dynamic>?> _tryFetchRowFromTable(
    SupabaseClient client, {
    required String tableName,
    required String column,
    required String userId,
  }) async {
    try {
      return await client
          .from(tableName)
          .select()
          .eq(column, userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('Unable to query $tableName by $column: $e');
      return null;
    }
  }

  static DateTime? _readRowDate(Map<String, dynamic>? row) {
    if (row == null) {
      return null;
    }

    final rawValue =
        row['updated_at'] ?? row['selected_at'] ?? row['created_at'];

    if (rawValue is DateTime) {
      return rawValue;
    }

    if (rawValue is String) {
      return DateTime.tryParse(rawValue);
    }

    return null;
  }

  static String _dateTimeToKey(DateTime value) {
    var normalized = value;
    if (normalized.hour < 5) {
      normalized = normalized.subtract(const Duration(days: 1));
    }

    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}

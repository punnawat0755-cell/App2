import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserModeStatusService {
  static const String dateKey = 'user_mode_last_date';
  static const String modeKey = 'user_mode_current_mode';
  static const String userIdKey = 'user_mode_user_id';
  static const String selectedConfirmedKey = 'user_mode_selected_confirmed';
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
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      await clearLocalCache();
      return false;
    }

    final snapshot = await _fetchModeSnapshot(client, user.id);
    if (snapshot == null) {
      await clearLocalCache();
      return false;
    }

    if (!snapshot.isSelectedToday) {
      await clearLocalCache();
      return false;
    }

    final mode = _normalizeMode(snapshot.currentMode);
    await _saveLocalSelection(
      userId: user.id,
      mode: mode,
    );
    return true;
  }

  static Future<String?> getCurrentModeToday() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      await clearLocalCache();
      return null;
    }

    final snapshot = await _fetchModeSnapshot(client, user.id);
    if (snapshot == null || !snapshot.isSelectedToday) {
      await clearLocalCache();
      return null;
    }

    final mode = _normalizeMode(snapshot.currentMode);
    await _saveLocalSelection(userId: user.id, mode: mode);
    return mode;
  }

  static Future<void> saveCurrentMode(String currentMode) async {
    final normalizedMode = currentMode.trim();
    if (normalizedMode.isEmpty) {
      throw ArgumentError('currentMode must not be empty');
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('กรุณาเข้าสู่ระบบก่อนเลือกบทบาท');
    }

    await _ensureRoleState(client);
    await client.rpc('set_my_mode', params: {'p_mode': normalizedMode});
    await _saveLocalSelection(userId: user.id, mode: normalizedMode);
  }

  static Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(dateKey);
    await prefs.remove(modeKey);
    await prefs.remove(userIdKey);
    await prefs.remove(selectedConfirmedKey);
  }

  static Future<bool> isListenerCapable() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      return false;
    }

    final snapshot = await _fetchModeSnapshot(client, user.id);
    if (snapshot != null && snapshot.canBeListener != null) {
      return snapshot.canBeListener!;
    }

    final statusRow = await getMyModeStatus();
    if (statusRow != null && statusRow['can_be_listener'] is bool) {
      return statusRow['can_be_listener'] == true;
    }

    final row = await _fetchListenerCapabilityRow(client, user.id);
    final capability = row?['is_capable'];
    if (capability is bool) {
      return capability;
    }

    return false;
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

  static Future<void> _ensureRoleState(SupabaseClient client) async {
    try {
      await client.rpc('ensure_my_role_state');
    } catch (e) {
      debugPrint('ensure_my_role_state failed: $e');
    }
  }

  static Future<_ModeSnapshot?> _fetchModeSnapshot(
    SupabaseClient client,
    String userId,
  ) async {
    try {
      await _ensureRoleState(client);
      final raw = await client.rpc('get_my_mode_today');
      final row = _normalizeSingleRow(raw);
      if (row == null) {
        return null;
      }

      final mode = _normalizeMode(row['current_mode']?.toString());
      final hasCanBeListener = row.containsKey('can_be_listener');
      return _ModeSnapshot(
        isSelectedToday: row['is_selected_today'] == true,
        canBeListener: hasCanBeListener
            ? _asBool(row['can_be_listener'], fallback: false)
            : null,
        currentMode: mode,
      );
    } catch (e) {
      debugPrint('get_my_mode_today failed for $userId: $e');
      return null;
    }
  }

  static Map<String, dynamic>? _normalizeSingleRow(dynamic raw) {
    if (raw is List) {
      if (raw.isEmpty) {
        return null;
      }

      final first = raw.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }

      return null;
    }

    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return null;
  }

  static bool _asBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == 't' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == 'f' || normalized == '0') {
        return false;
      }
    }
    return fallback;
  }

  static String _normalizeMode(String? rawMode) {
    final value = (rawMode ?? '').trim().toLowerCase();
    if (value == 'listener') {
      return 'listener';
    }
    return 'seeker';
  }

  static Future<void> _saveLocalSelection({
    required String userId,
    required String mode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(dateKey, todayAsKey());
    await prefs.setString(modeKey, mode);
    await prefs.setString(userIdKey, userId);
    await prefs.setBool(selectedConfirmedKey, true);
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

  static Future<Map<String, dynamic>?> getMyModeStatus() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      await _ensureRoleState(client);
      final raw = await client.rpc('get_my_mode_today');
      return _normalizeSingleRow(raw);
    } catch (e) {
      debugPrint('getMyModeStatus failed for ${user.id}: $e');
      return null;
    }
  }

  static Future<String?> setMyMode(String mode) async {
    final normalizedMode = mode.trim().toLowerCase();
    if (normalizedMode.isEmpty) {
      return null;
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      await _ensureRoleState(client);
      final raw =
          await client.rpc('set_my_mode', params: {'p_mode': normalizedMode});
      final row = _normalizeSingleRow(raw);
      if (row != null) {
        final modeValue = row['current_mode'];
        if (modeValue is String && modeValue.trim().isNotEmpty) {
          final normalized = _normalizeMode(modeValue);
          await _saveLocalSelection(userId: user.id, mode: normalized);
          return normalized;
        }
      }

      // Some deployments define set_my_mode as RETURNS void.
      await _saveLocalSelection(userId: user.id, mode: normalizedMode);
      return _normalizeMode(normalizedMode);
    } catch (e) {
      debugPrint('setMyMode failed for ${user.id}: $e');
      return null;
    }
  }

  static Future<void> resetMyModeToday() async {
    final client = Supabase.instance.client;
    try {
      await client.rpc('reset_my_mode_today');
    } catch (_) {
      // Optional debug helper; ignore if function is not deployed.
    } finally {
      await clearLocalCache();
    }
  }
}

class _ModeSnapshot {
  const _ModeSnapshot({
    required this.isSelectedToday,
    required this.canBeListener,
    required this.currentMode,
  });

  final bool isSelectedToday;
  final bool? canBeListener;
  final String currentMode;
}

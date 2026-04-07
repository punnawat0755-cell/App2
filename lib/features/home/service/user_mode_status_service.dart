import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserModeStatusService {
  static const String dateKey = 'user_mode_last_date';
  static const String modeKey = 'user_mode_current_mode';
  static const String userIdKey = 'user_mode_user_id';
  static const String selectedConfirmedKey = 'user_mode_selected_confirmed';

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

    final state = await _fetchAppEntryState(client);
    if (state == null || !state.hasRoleToday) {
      await clearLocalCache();
      return false;
    }

    await _saveLocalSelection(
      userId: user.id,
      mode: state.currentMode,
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

    final state = await _fetchAppEntryState(client);
    if (state == null || !state.hasRoleToday) {
      await clearLocalCache();
      return null;
    }

    await _saveLocalSelection(
      userId: user.id,
      mode: state.currentMode,
    );
    return state.currentMode;
  }

  static Future<void> saveCurrentMode(String currentMode) async {
    final normalizedMode = _normalizeMode(currentMode);
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
    if (client.auth.currentUser == null) {
      return false;
    }

    final gateState = await _fetchChatGateState(client);
    if (gateState != null) {
      return gateState.assessmentPassed;
    }

    final entryState = await _fetchAppEntryState(client);
    return entryState?.assessmentPassed ?? false;
  }

  static Future<bool> canChatAsListenerToday() async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) {
      return false;
    }

    final gateState = await _fetchChatGateState(client);
    return gateState?.canChatAsListener ?? false;
  }

  static Future<Map<String, dynamic>?> getMyModeStatus() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final appState = await _fetchAppEntryState(client);
    final chatState = await _fetchChatGateState(client);
    if (appState == null && chatState == null) {
      return null;
    }

    final hasRoleToday = chatState?.hasRoleToday ?? appState?.hasRoleToday;
    final currentMode = chatState?.currentMode ?? appState?.currentMode;
    final selectedForDay =
        chatState?.selectedForDay ?? appState?.selectedForDay;
    final assessmentPassed =
        chatState?.assessmentPassed ?? appState?.assessmentPassed;

    return {
      'has_role_today': hasRoleToday ?? false,
      'is_selected_today': hasRoleToday ?? false,
      'current_mode': currentMode,
      'selected_for_day': selectedForDay,
      'assessment_passed': assessmentPassed ?? false,
      'can_chat_as_listener': chatState?.canChatAsListener ?? false,
      'latest_assessment_result': appState?.latestAssessmentResult,
    };
  }

  static Future<Map<String, dynamic>?> getMyChatGateState() async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) {
      return null;
    }

    final state = await _fetchChatGateState(client);
    if (state == null) {
      return null;
    }

    return {
      'has_role_today': state.hasRoleToday,
      'current_mode': state.currentMode,
      'selected_for_day': state.selectedForDay,
      'can_chat_as_listener': state.canChatAsListener,
      'assessment_passed': state.assessmentPassed,
    };
  }

  static Future<String?> setMyMode(String mode) async {
    final normalizedMode = _normalizeMode(mode);
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
      final savedMode = _normalizeMode(row?['current_mode']?.toString());
      await _saveLocalSelection(userId: user.id, mode: savedMode);
      return savedMode;
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

  static Future<void> _ensureRoleState(SupabaseClient client) async {
    try {
      await client.rpc('ensure_my_role_state');
    } catch (e) {
      debugPrint('ensure_my_role_state failed: $e');
    }
  }

  static Future<_AppEntryState?> _fetchAppEntryState(
    SupabaseClient client,
  ) async {
    try {
      final raw = await client.rpc('get_my_app_entry_state');
      final row = _normalizeSingleRow(raw);
      if (row == null) {
        return null;
      }

      return _AppEntryState(
        hasRoleToday: _asBool(row['has_role_today']),
        currentMode: _normalizeMode(row['current_mode']?.toString()),
        selectedForDay: row['selected_for_day']?.toString(),
        assessmentPassed: _asBool(row['assessment_passed']),
        latestAssessmentResult: row['latest_assessment_result']?.toString(),
      );
    } catch (e) {
      debugPrint('get_my_app_entry_state failed: $e');
      return null;
    }
  }

  static Future<_ChatGateState?> _fetchChatGateState(
    SupabaseClient client,
  ) async {
    try {
      final raw = await client.rpc('get_my_chat_gate_state');
      final row = _normalizeSingleRow(raw);
      if (row == null) {
        return null;
      }

      return _ChatGateState(
        hasRoleToday: _asBool(row['has_role_today']),
        currentMode: _normalizeMode(row['current_mode']?.toString()),
        selectedForDay: row['selected_for_day']?.toString(),
        canChatAsListener: _asBool(row['can_chat_as_listener']),
        assessmentPassed: _asBool(row['assessment_passed']),
      );
    } catch (e) {
      debugPrint('get_my_chat_gate_state failed: $e');
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
    return value == 'listener' ? 'listener' : 'seeker';
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
}

class _AppEntryState {
  const _AppEntryState({
    required this.hasRoleToday,
    required this.currentMode,
    required this.selectedForDay,
    required this.assessmentPassed,
    required this.latestAssessmentResult,
  });

  final bool hasRoleToday;
  final String currentMode;
  final String? selectedForDay;
  final bool assessmentPassed;
  final String? latestAssessmentResult;
}

class _ChatGateState {
  const _ChatGateState({
    required this.hasRoleToday,
    required this.currentMode,
    required this.selectedForDay,
    required this.canChatAsListener,
    required this.assessmentPassed,
  });

  final bool hasRoleToday;
  final String currentMode;
  final String? selectedForDay;
  final bool canChatAsListener;
  final bool assessmentPassed;
}

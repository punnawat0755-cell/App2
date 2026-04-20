import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TodayAssessmentState {
  const TodayAssessmentState({
    required this.assessmentId,
    required this.attemptId,
    required this.hasAttemptToday,
    required this.completedToday,
    required this.assessmentPassedToday,
    required this.totalScore,
    required this.maxScore,
    required this.result,
  });

  final String? assessmentId;
  final String? attemptId;
  final bool hasAttemptToday;
  final bool completedToday;
  final bool assessmentPassedToday;
  final int? totalScore;
  final int? maxScore;
  final String? result;

  factory TodayAssessmentState.fromMap(Map<String, dynamic> map) {
    return TodayAssessmentState(
      assessmentId: _stringOrNull(map['assessment_id']),
      attemptId: _stringOrNull(map['attempt_id']),
      hasAttemptToday: _toBool(map['has_attempt_today']),
      completedToday: _toBool(map['completed_today']),
      assessmentPassedToday: _toBool(
        map['assessment_passed_today'] ?? map['assessment_passed'],
      ),
      totalScore: _toIntOrNull(map['total_score']),
      maxScore: _toIntOrNull(map['max_score']),
      result: _stringOrNull(map['result']),
    );
  }
}

class ChatGateState {
  const ChatGateState({
    required this.hasRoleToday,
    required this.currentMode,
    required this.selectedForDay,
    required this.assessmentDoneToday,
    required this.assessmentPassedToday,
    required this.canChatAsListenerToday,
  });

  final bool hasRoleToday;
  final String? currentMode;
  final String? selectedForDay;
  final bool assessmentDoneToday;
  final bool assessmentPassedToday;
  final bool canChatAsListenerToday;

  factory ChatGateState.fromMap(Map<String, dynamic> map) {
    return ChatGateState(
      hasRoleToday: _toBool(map['has_role_today']),
      currentMode: _normalizeModeOrNull(map['current_mode']?.toString()),
      selectedForDay: _stringOrNull(map['selected_for_day']),
      assessmentDoneToday: _toBool(map['assessment_done_today']),
      assessmentPassedToday:
          _toBool(map['assessment_passed_today'] ?? map['assessment_passed']),
      canChatAsListenerToday: _toBool(
        map['can_chat_as_listener_today'] ?? map['can_chat_as_listener'],
      ),
    );
  }
}

class UserModeStatusService {
  const UserModeStatusService._();

  static const String _dateKey = 'user_mode_last_date';
  static const String _modeKey = 'user_mode_current_mode';
  static const String _userIdKey = 'user_mode_user_id';
  static const String _selectedConfirmedKey = 'user_mode_selected_confirmed';

  static const String _assessmentStateRpc = 'get_my_assessment_attempt';
  static const String _chatGateStateRpc = 'get_my_chat_gate_state';

  static const String _listenerQuizRetryDateKey =
      'listener_quiz_retry_used_date';
  static const String _listenerQuizRetryUserIdKey =
      'listener_quiz_retry_used_user_id';

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
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      await clearLocalCache();
      return false;
    }

    try {
      final raw = await supabase.rpc('has_selected_mode_today');
      final hasSelected = _toBool(raw);
      if (!hasSelected) {
        await clearLocalCache();
        return false;
      }

      final currentMode = await getCurrentModeToday();
      return currentMode != null;
    } catch (error) {
      if (!_isMissingRpcFunctionError(error)) {
        rethrow;
      }
    }

    final entryState = await _fetchAppEntryState();
    if (entryState != null && entryState.hasRoleToday) {
      await _saveLocalSelection(
        userId: currentUser.id,
        mode: entryState.currentMode ?? 'seeker',
      );
      return true;
    }

    final gateState = await getChatGateState();
    if (gateState.hasRoleToday && gateState.currentMode != null) {
      await _saveLocalSelection(
        userId: currentUser.id,
        mode: gateState.currentMode!,
      );
      return true;
    }

    await clearLocalCache();
    return false;
  }

  static Future<String?> getCurrentModeToday() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      await clearLocalCache();
      return null;
    }

    final gateRow = await _tryGetChatGateRow();
    final gateMode = _normalizeModeOrNull(gateRow?['current_mode']?.toString());
    if (_toBool(gateRow?['has_role_today']) && gateMode != null) {
      await _saveLocalSelection(userId: currentUser.id, mode: gateMode);
      return gateMode;
    }

    final entryState = await _fetchAppEntryState();
    if (entryState != null && entryState.hasRoleToday) {
      final mode = entryState.currentMode ?? 'seeker';
      await _saveLocalSelection(userId: currentUser.id, mode: mode);
      return mode;
    }

    await clearLocalCache();
    return null;
  }

  static Future<void> saveCurrentMode(String currentMode) async {
    final normalizedMode = _normalizeMode(currentMode);
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw StateError('กรุณาเข้าสู่ระบบก่อนเลือกบทบาท');
    }

    await _ensureRoleState();
    try {
      await supabase.rpc(
        'set_my_mode',
        params: {'p_mode': normalizedMode},
      );
    } on PostgrestException catch (error) {
      if (!_isAmbiguousUserIdError(error)) {
        rethrow;
      }
      await _saveCurrentModeFallback(normalizedMode);
    }
    await _saveLocalSelection(userId: currentUser.id, mode: normalizedMode);
  }

  static Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dateKey);
    await prefs.remove(_modeKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_selectedConfirmedKey);
    await prefs.remove(_listenerQuizRetryDateKey);
    await prefs.remove(_listenerQuizRetryUserIdKey);
  }

  static Future<void> clearTodayModeSelection() async {
    try {
      await supabase.rpc('clear_my_mode_selection');
    } catch (error) {
      if (!_isMissingRpcFunctionError(error)) {
        rethrow;
      }
    } finally {
      await clearLocalCache();
    }
  }

  static Future<bool> hasDoneAssessmentToday() async {
    try {
      final raw = await supabase.rpc('has_done_assessment_today');
      return _toBool(raw);
    } catch (error) {
      if (!_isMissingRpcFunctionError(error)) {
        rethrow;
      }
    }

    final assessmentRow = await _tryGetAssessmentStateRow();
    if (assessmentRow != null) {
      return _toBool(
        assessmentRow['completed_today'] ??
            assessmentRow['assessment_done_today'] ??
            assessmentRow['has_attempt_today'],
      );
    }

    final chatGateRow = await _tryGetChatGateRow();
    if (chatGateRow != null) {
      return _toBool(chatGateRow['assessment_done_today']);
    }

    return false;
  }

  static Future<bool> hasPassedAssessmentToday() async {
    try {
      final raw = await supabase.rpc('has_passed_assessment_today');
      return _toBool(raw);
    } catch (error) {
      if (!_isMissingRpcFunctionError(error)) {
        rethrow;
      }
    }

    final assessmentRow = await _tryGetAssessmentStateRow();
    if (assessmentRow != null) {
      return _toBool(
        assessmentRow['assessment_passed_today'] ??
            assessmentRow['assessment_passed'] ??
            (assessmentRow['result']?.toString().toLowerCase() == 'pass'),
      );
    }

    final chatGateRow = await _tryGetChatGateRow();
    if (chatGateRow != null) {
      return _toBool(
        chatGateRow['assessment_passed_today'] ??
            chatGateRow['assessment_passed'],
      );
    }

    final entryState = await _fetchAppEntryState();
    return entryState?.assessmentPassed ?? false;
  }

  static Future<TodayAssessmentState> getTodayAssessmentState() async {
    final row = await _tryGetAssessmentStateRow();
    if (row != null) {
      return TodayAssessmentState.fromMap(row);
    }

    final assessmentId = await _tryGetActiveAssessmentId();
    final chatGateRow = await _tryGetChatGateRow();
    final completedToday = _toBool(chatGateRow?['assessment_done_today']);
    final passedToday = _toBool(
      chatGateRow?['assessment_passed_today'] ??
          chatGateRow?['assessment_passed'],
    );

    return TodayAssessmentState(
      assessmentId: assessmentId,
      attemptId: null,
      hasAttemptToday: completedToday,
      completedToday: completedToday,
      assessmentPassedToday: passedToday,
      totalScore: null,
      maxScore: null,
      result: passedToday ? 'pass' : (completedToday ? 'fail' : null),
    );
  }

  static Future<ChatGateState> getChatGateState() async {
    final row = await _tryGetChatGateRow();
    if (row != null) {
      return ChatGateState.fromMap(row);
    }

    final entryState = await _fetchAppEntryState();
    final hasRoleToday = entryState?.hasRoleToday ?? false;
    final currentMode = entryState?.currentMode;
    final selectedForDay = entryState?.selectedForDay;
    final doneToday = await hasDoneAssessmentToday();
    final passedToday = await hasPassedAssessmentToday();

    return ChatGateState(
      hasRoleToday: hasRoleToday,
      currentMode: currentMode,
      selectedForDay: selectedForDay,
      assessmentDoneToday: doneToday,
      assessmentPassedToday: passedToday,
      canChatAsListenerToday:
          hasRoleToday && currentMode == 'listener' && passedToday,
    );
  }

  static Future<bool> canBeListenerToday() async {
    final state = await getTodayAssessmentState();
    return state.assessmentPassedToday;
  }

  static Future<bool> isListenerCapable() async {
    if (supabase.auth.currentUser == null) {
      return false;
    }

    return hasPassedAssessmentToday();
  }

  static Future<bool> canChatAsListenerToday() async {
    if (supabase.auth.currentUser == null) {
      return false;
    }

    final state = await getChatGateState();
    return state.canChatAsListenerToday;
  }

  static Future<Map<String, dynamic>?> getMyModeStatus() async {
    if (supabase.auth.currentUser == null) {
      return null;
    }

    final chatState = await getChatGateState();
    final entryState = await _fetchAppEntryState();

    return {
      'has_role_today': chatState.hasRoleToday,
      'is_selected_today': chatState.hasRoleToday,
      'current_mode': chatState.currentMode,
      'selected_for_day': chatState.selectedForDay,
      'assessment_passed': chatState.assessmentPassedToday,
      'assessment_done_today': chatState.assessmentDoneToday,
      'can_chat_as_listener': chatState.canChatAsListenerToday,
      'latest_assessment_result': entryState?.latestAssessmentResult,
    };
  }

  static Future<Map<String, dynamic>?> getMyChatGateState() async {
    if (supabase.auth.currentUser == null) {
      return null;
    }

    final state = await getChatGateState();
    return {
      'has_role_today': state.hasRoleToday,
      'current_mode': state.currentMode,
      'selected_for_day': state.selectedForDay,
      'assessment_done_today': state.assessmentDoneToday,
      'assessment_passed': state.assessmentPassedToday,
      'can_chat_as_listener': state.canChatAsListenerToday,
    };
  }

  static Future<String?> setMyMode(String mode) async {
    final normalizedMode = _normalizeMode(mode);
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    try {
      await _ensureRoleState();
      final raw = await supabase.rpc(
        'set_my_mode',
        params: {'p_mode': normalizedMode},
      );
      final row = _normalizeSingleRow(raw);
      final savedMode =
          _normalizeModeOrNull(row?['current_mode']?.toString()) ??
              normalizedMode;
      await _saveLocalSelection(userId: currentUser.id, mode: savedMode);
      return savedMode;
    } catch (error) {
      debugPrint('setMyMode failed for ${currentUser.id}: $error');
      return null;
    }
  }

  static Future<void> resetMyModeToday() async {
    try {
      await supabase.rpc('reset_my_mode_today');
    } catch (_) {
      // Optional debug helper; ignore if function is not deployed.
    } finally {
      await clearLocalCache();
    }
  }

  static Future<bool> canTakeListenerQuizRetryToday() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final usedDate = prefs.getString(_listenerQuizRetryDateKey) ?? '';
    final usedUserId = prefs.getString(_listenerQuizRetryUserIdKey) ?? '';
    final usedToday = usedDate == todayAsKey() && usedUserId == currentUser.id;
    return !usedToday;
  }

  static Future<void> markListenerQuizRetryUsedToday() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listenerQuizRetryDateKey, todayAsKey());
    await prefs.setString(_listenerQuizRetryUserIdKey, currentUser.id);
  }

  static Future<void> _ensureRoleState() async {
    try {
      await supabase.rpc('ensure_my_role_state');
    } catch (error) {
      debugPrint('ensure_my_role_state failed: $error');
    }
  }

  static Future<_AppEntryState?> _fetchAppEntryState() async {
    try {
      final raw = await supabase.rpc('get_my_app_entry_state');
      final row = _normalizeSingleRow(raw);
      if (row == null) {
        return null;
      }

      return _AppEntryState(
        hasRoleToday: _toBool(row['has_role_today']),
        currentMode: _normalizeModeOrNull(row['current_mode']?.toString()),
        selectedForDay: _stringOrNull(row['selected_for_day']),
        assessmentPassed: _toBool(
          row['assessment_passed_today'] ?? row['assessment_passed'],
        ),
        latestAssessmentResult: _stringOrNull(row['latest_assessment_result']),
      );
    } catch (error) {
      if (_isMissingRpcFunctionError(error)) {
        return null;
      }

      debugPrint('get_my_app_entry_state failed: $error');
      return null;
    }
  }

  static Map<String, dynamic> _extractSingleRow(Object? raw) {
    return _normalizeSingleRow(raw) ?? <String, dynamic>{};
  }

  static Map<String, dynamic>? _normalizeSingleRow(Object? raw) {
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

  static Future<String?> _tryGetActiveAssessmentId() async {
    try {
      final row = await supabase
          .from('assessments')
          .select('id')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final id = row?['id']?.toString().trim() ?? '';
      return id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _tryGetAssessmentStateRow() async {
    try {
      final raw = await supabase.rpc(_assessmentStateRpc);
      return _extractSingleRow(raw);
    } catch (error) {
      if (_isMissingRpcFunctionError(error)) {
        return null;
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> _tryGetChatGateRow() async {
    try {
      final raw = await supabase.rpc(_chatGateStateRpc);
      return _extractSingleRow(raw);
    } catch (error) {
      if (_isMissingRpcFunctionError(error)) {
        return null;
      }
      rethrow;
    }
  }

  static Future<void> _saveLocalSelection({
    required String userId,
    required String mode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, todayAsKey());
    await prefs.setString(_modeKey, mode);
    await prefs.setString(_userIdKey, userId);
    await prefs.setBool(_selectedConfirmedKey, true);
  }

  static bool _isMissingRpcFunctionError(Object error) {
    if (error is! PostgrestException) {
      return false;
    }

    final code = (error.code ?? '').toUpperCase();
    if (code == 'PGRST202' || code == '42883') {
      return true;
    }

    final message = error.message.toLowerCase();
    return message.contains('could not find the function');
  }

  static bool _isAmbiguousUserIdError(PostgrestException error) {
    if ((error.code ?? '').trim() != '42702') {
      return false;
    }

    final message = error.message.toLowerCase();
    return message.contains('user_id') && message.contains('ambiguous');
  }

  static Future<void> _saveCurrentModeFallback(String mode) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw StateError('กรุณาเข้าสู่ระบบก่อนเลือกบทบาท');
    }

    if (mode == 'listener') {
      final passedToday = await hasPassedAssessmentToday();
      if (!passedToday) {
        throw StateError('listener mode requires passing assessment today');
      }
    }

    final selectedForDay = await _resolveSelectedDateForDb();
    await supabase.from('user_modes').upsert(
      {
        'user_id': currentUser.id,
        'current_mode': mode,
        'selected_for_day': selectedForDay,
      },
      onConflict: 'user_id',
    );
  }

  static Future<String> _resolveSelectedDateForDb() async {
    try {
      final raw = await supabase.rpc('current_bangkok_date');
      final serverDate = _stringOrNull(raw);
      if (serverDate != null && serverDate.isNotEmpty) {
        return serverDate;
      }
    } catch (_) {}

    return todayAsKey();
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
  final String? currentMode;
  final String? selectedForDay;
  final bool assessmentPassed;
  final String? latestAssessmentResult;
}

bool _toBool(Object? raw) {
  if (raw is bool) {
    return raw;
  }
  if (raw is num) {
    return raw != 0;
  }
  if (raw is String) {
    final value = raw.trim().toLowerCase();
    return value == 'true' || value == '1' || value == 't';
  }
  return false;
}

int? _toIntOrNull(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  return int.tryParse(raw.toString());
}

String _normalizeMode(String? rawMode) {
  final value = (rawMode ?? '').trim().toLowerCase();
  return value == 'listener' ? 'listener' : 'seeker';
}

String? _normalizeModeOrNull(String? rawMode) {
  final value = rawMode?.trim().toLowerCase() ?? '';
  if (value == 'listener' || value == 'seeker') {
    return value;
  }
  return null;
}

String? _stringOrNull(Object? raw) {
  final value = raw?.toString().trim() ?? '';
  return value.isEmpty ? null : value;
}

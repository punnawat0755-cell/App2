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
      assessmentPassedToday: _toBool(map['assessment_passed_today']),
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
      currentMode: _stringOrNull(map['current_mode']),
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

  static const String _assessmentStateRpc = 'get_my_assessment_attempt';
  static const String _chatGateStateRpc = 'get_my_chat_gate_state';

  static const String _listenerQuizRetryDateKey =
      'listener_quiz_retry_used_date';
  static const String _listenerQuizRetryUserIdKey =
      'listener_quiz_retry_used_user_id';

  static Future<void> saveCurrentMode(String mode) async {
    await supabase.rpc(
      'set_my_mode',
      params: {'p_mode': mode},
    );
  }

  static Future<bool> hasSelectedModeToday() async {
    try {
      final raw = await supabase.rpc('has_selected_mode_today');
      return _toBool(raw);
    } catch (error) {
      if (_isMissingRpcFunctionError(error)) {
        return false;
      }
      rethrow;
    }
  }

  static Future<void> clearTodayModeSelection() async {
    try {
      await supabase.rpc('clear_my_mode_selection');
    } catch (error) {
      if (_isMissingRpcFunctionError(error)) {
        return;
      }
      rethrow;
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

    return false;
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

    final hasRoleToday = await hasSelectedModeToday();
    final passedToday = await hasPassedAssessmentToday();
    final doneToday = await hasDoneAssessmentToday();

    return ChatGateState(
      hasRoleToday: hasRoleToday,
      currentMode: null,
      selectedForDay: null,
      assessmentDoneToday: doneToday,
      assessmentPassedToday: passedToday,
      canChatAsListenerToday: hasRoleToday && passedToday,
    );
  }

  static Future<bool> canBeListenerToday() async {
    final state = await getTodayAssessmentState();
    return state.assessmentPassedToday;
  }

  static Future<Map<String, dynamic>?> getMyChatGateState() async {
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

  static String todayAsKey() {
    var now = DateTime.now();
    if (now.hour < 5) {
      now = now.subtract(const Duration(days: 1));
    }

    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static Map<String, dynamic> _extractSingleRow(Object? raw) {
    if (raw == null) {
      return <String, dynamic>{};
    }

    if (raw is List) {
      if (raw.isEmpty) {
        return <String, dynamic>{};
      }
      final first = raw.first;
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
      return <String, dynamic>{};
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return <String, dynamic>{};
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

String? _stringOrNull(Object? raw) {
  final value = raw?.toString().trim() ?? '';
  return value.isEmpty ? null : value;
}

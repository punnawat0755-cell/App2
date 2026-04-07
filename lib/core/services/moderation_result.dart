class ModerationResult {
  const ModerationResult({
    required this.ok,
    required this.status,
    required this.action,
    required this.allowed,
    required this.safeToPost,
    required this.reasonCodes,
    required this.summary,
  });

  factory ModerationResult.fromJson(Map<String, dynamic> json) {
    return ModerationResult(
      ok: _readBool(json['ok']) ?? false,
      status: _readInt(json['status']),
      action: _readSummary(json['action']) ?? '',
      allowed: _readBool(json['allowed']) ?? false,
      safeToPost: _readBool(json['safe_to_post']) ??
          _readBool(json['safeToPost']) ??
          false,
      reasonCodes: _readStringList(json['reason_codes']) ??
          _readStringList(json['reasonCodes']) ??
          const <String>[],
      summary: _readSummary(json['summary']) ?? 'ระบบไม่อนุญาตให้โพสต์',
    );
  }

  factory ModerationResult.blocked({
    required String summary,
    int? status,
    String? reasonCode,
  }) {
    return ModerationResult(
      ok: false,
      status: status,
      action: '',
      allowed: false,
      safeToPost: false,
      reasonCodes: reasonCode == null || reasonCode.isEmpty
          ? const <String>[]
          : <String>[reasonCode],
      summary: summary,
    );
  }

  final bool ok;
  final int? status;
  final String action;
  final bool allowed;
  final bool safeToPost;
  final List<String> reasonCodes;
  final String summary;

  ModerationResult copyWith({
    bool? ok,
    int? status,
    String? action,
    bool? allowed,
    bool? safeToPost,
    List<String>? reasonCodes,
    String? summary,
  }) {
    return ModerationResult(
      ok: ok ?? this.ok,
      status: status ?? this.status,
      action: action ?? this.action,
      allowed: allowed ?? this.allowed,
      safeToPost: safeToPost ?? this.safeToPost,
      reasonCodes: reasonCodes ?? this.reasonCodes,
      summary: summary ?? this.summary,
    );
  }

  static bool? _readBool(dynamic raw) {
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw != 0;
    }
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return null;
  }

  static int? _readInt(dynamic raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  static List<String>? _readStringList(dynamic raw) {
    if (raw is! List) {
      return null;
    }

    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String? _readSummary(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return text;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ContentModerationService {
  ContentModerationService._();

  static final ContentModerationService instance = ContentModerationService._();

  static const String _n8nModerationWebhook = String.fromEnvironment(
    'N8N_MODERATION_WEBHOOK',
    defaultValue: 'https://n8n.tgstack.dev/webhook/HowAreYou',
  );
  static const bool _moderationFailOpen = bool.fromEnvironment(
    'N8N_MODERATION_FAIL_OPEN',
    defaultValue: true,
  );
  static const bool _allowBadCertificate = bool.fromEnvironment(
    'N8N_ALLOW_BAD_CERT',
    defaultValue: true,
  );
  static const String _allowBadCertificateHosts = String.fromEnvironment(
    'N8N_ALLOW_BAD_CERT_HOSTS',
    defaultValue: 'n8n.tgstack.dev',
  );
  static const Duration _moderationTimeout = Duration(seconds: 6);
  static const List<String> _localProfanityTokens = [
    'เหี้ย',
    'ไอ้เหี้ย',
    'อีเหี้ย',
    'ควย',
    'ไอ้ควย',
    'อีควย',
    'หี',
    'หำ',
    'กระหรี่',
    'อีกะหรี่',
    'สัส',
    'ไอ้สัส',
    'อีสัส',
    'ไอสัส',
    'ไอสาด',
    'สัตว์',
    'สัด',
    'ส้นตีน',
    'ตีน',
    'ตรีน',
    'ตายห่า',
    'ห่า',
    'ห่าน',
    'หน้าหี',
    'หน้าควย',
    'เสือก',
    'กู',
    'เย็ด',
    'เย็ดแม่',
    'เย็ดพ่อ',
    'แม่ง',
    'มรึง',
    'มึง',
    'ควาย',
    'ไอ้ควาย',
    'อีควาย',
    'ควายเอ๊ย',
    'โง่สัส',
    'ค-ว-ย',
    'ห-ี',
    'เ-ห-ี้-ย',
    'fuck',
    'f*ck',
    'fuk',
    'fuc',
    'fucking',
    'fk',
    'wtf',
    'shit',
    'sh1t',
    'bullshit',
    'dipshit',
    'bitch',
    'b1tch',
    'son of bitch',
    'son of a bitch',
    'asshole',
    'ass hole',
    'arsehole',
    'jackass',
    'bastard',
    'motherfucker',
    'mother fucker',
    'mf',
    'mfer',
    'dick',
    'd1ck',
    'cock',
    'prick',
    'pussy',
    'pussyhole',
    'cunt',
    'slut',
    'whore',
    'hoe',
    'retard',
    'idiot',
    'stupid',
    'kys',
    'kill yourself',
    'nigga',
    'nigger',
    'faggot',
    'tranny',
    'rape',
    'raped',
    'rapist',
    'porn',
    'xxx',
    'blowjob',
    'handjob',
  ];

  late final http.Client _httpClient = _buildHttpClient();

  Future<ContentModerationResult> moderateText({
    required String source,
    required String text,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _n8nModerationWebhook.trim().isEmpty) {
      return ContentModerationResult.allow(trimmed);
    }

    final webhookUri = Uri.tryParse(_n8nModerationWebhook);
    debugPrint(
      'n8n moderation request source=$source url=$_n8nModerationWebhook host=${webhookUri?.host ?? '-'}',
    );

    final requestPayload = <String, dynamic>{
      'action': 'content_moderate',
      'source': source,
      'message': trimmed,
      'text': trimmed,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      ...metadata,
    };

    try {
      final response = await _httpClient
          .post(
            webhookUri ?? Uri.parse(_n8nModerationWebhook),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(requestPayload),
          )
          .timeout(_moderationTimeout);

      debugPrint(
        'n8n moderation http=${response.statusCode} source=$source body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackOnModerationError(
            trimmed, 'http-${response.statusCode}');
      }

      if (response.body.trim().isEmpty) {
        return _fallbackOnModerationError(trimmed, 'empty-body');
      }

      final responsePayload = _parseModerationPayload(response.body);
      if (responsePayload == null) {
        return _fallbackOnModerationError(trimmed, 'invalid-payload');
      }

      final status =
          (responsePayload['status'] ?? '').toString().trim().toLowerCase();
      final allowed = _readBool(responsePayload, const ['allowed', 'allow']);
      final explicitProfanity = _readBool(
            responsePayload,
            const ['isProfane', 'profanity', 'containsProfanity'],
          ) ==
          true;
      final safeText = _readSafeText(responsePayload, trimmed);

      debugPrint(
        'n8n moderation payload source=$source payload=$responsePayload',
      );

      if (allowed != null) {
        if (allowed) {
          return ContentModerationResult.allow(safeText);
        }
        return const ContentModerationResult.block(
          'moderation-blocked-by-n8n',
        );
      }

      if (explicitProfanity ||
          status == 'block' ||
          status == 'blocked' ||
          status == 'reject') {
        return const ContentModerationResult.block(
          'moderation-blocked-by-n8n',
        );
      }

      if (status == 'mask' ||
          status == 'sanitize' ||
          status == 'sanitized' ||
          status == 'allow' ||
          status == 'allowed' ||
          status == 'ok') {
        return ContentModerationResult.allow(safeText);
      }

      return _fallbackOnModerationError(trimmed, 'unknown-status:$status');
    } on TimeoutException {
      debugPrint('n8n moderation timeout source=$source');
      return _fallbackOnModerationError(trimmed, 'timeout');
    } catch (error) {
      debugPrint('n8n moderation failed source=$source error=$error');
      return _fallbackOnModerationError(trimmed, 'exception');
    }
  }

  ContentModerationResult _fallbackOnModerationError(
    String text,
    String reason,
  ) {
    final blockedByLocal = _containsLocalProfanity(text);
    debugPrint(
      'n8n moderation fallback(local) reason=$reason blocked=$blockedByLocal',
    );

    if (blockedByLocal) {
      return const ContentModerationResult.block(
        'moderation-blocked-local-fallback',
      );
    }

    if (_moderationFailOpen) {
      return ContentModerationResult.allow(text);
    }
    return ContentModerationResult.block('moderation-unavailable:$reason');
  }

  bool _containsLocalProfanity(String input) {
    final lowered = input.toLowerCase();
    final compact = lowered
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u0E00-\u0E7F]'), '');

    for (final token in _localProfanityTokens) {
      final normalizedToken = token.toLowerCase();
      if (lowered.contains(normalizedToken) ||
          compact.contains(normalizedToken.replaceAll(' ', ''))) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic>? _asMapPayload(dynamic decoded) {
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  Map<String, dynamic>? _parseModerationPayload(String body) {
    final trimmed = body.trim();

    try {
      final decoded = jsonDecode(trimmed);
      final payload = _asMapPayload(decoded);
      if (payload != null) {
        return payload;
      }
    } catch (_) {
      // Accept short plain-text responses such as allow/block.
    }

    final normalized = trimmed.toLowerCase();
    if (normalized == 'ok' ||
        normalized == 'allow' ||
        normalized == 'allowed' ||
        normalized == 'true' ||
        normalized == 'pass') {
      return {'allowed': true};
    }
    if (normalized == 'block' ||
        normalized == 'blocked' ||
        normalized == 'false' ||
        normalized == 'reject') {
      return {'allowed': false};
    }

    return null;
  }

  http.Client _buildHttpClient() {
    if (!_allowBadCertificate) {
      return http.Client();
    }

    final configuredHosts = _allowBadCertificateHosts
        .split(',')
        .map((host) => host.trim().toLowerCase())
        .where((host) => host.isNotEmpty)
        .toSet();
    final webhookHost = Uri.tryParse(_n8nModerationWebhook)?.host.toLowerCase();
    if (webhookHost != null && webhookHost.isNotEmpty) {
      configuredHosts.add(webhookHost);
    }

    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        final isAllowed = configuredHosts.contains(host.toLowerCase());
        if (isAllowed) {
          debugPrint(
            'n8n moderation warning: accepting untrusted cert from $host:$port',
          );
        } else {
          debugPrint(
            'n8n moderation blocked untrusted cert from non-allowed host $host:$port',
          );
        }
        return isAllowed;
      };

    return IOClient(ioClient);
  }

  bool? _readBool(Map<String, dynamic> payload, List<String> keys) {
    final keySet = keys.map((key) => key.toLowerCase()).toSet();
    for (final entry in payload.entries) {
      if (!keySet.contains(entry.key.toLowerCase())) continue;
      final parsed = _parseDynamicBool(entry.value);
      if (parsed != null) return parsed;
    }

    return _readBoolRecursive(payload, keySet);
  }

  bool? _readBoolRecursive(dynamic node, Set<String> keys) {
    var foundTrue = false;

    if (node is Map) {
      final map = Map<String, dynamic>.from(node);

      for (final entry in map.entries) {
        final key = entry.key.toLowerCase();
        if (keys.contains(key)) {
          final parsed = _parseDynamicBool(entry.value);
          if (parsed != null) {
            if (!parsed) return false;
            foundTrue = true;
          }
        }
      }

      for (final value in map.values) {
        final nested = _readBoolRecursive(value, keys);
        if (nested != null) {
          if (!nested) return false;
          foundTrue = true;
        }
      }
      return foundTrue ? true : null;
    }

    if (node is List) {
      for (final item in node) {
        final nested = _readBoolRecursive(item, keys);
        if (nested != null) {
          if (!nested) return false;
          foundTrue = true;
        }
      }
    }
    return foundTrue ? true : null;
  }

  bool? _parseDynamicBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final value = raw.trim().toLowerCase();
      if (value == 'true' || value == '1' || value == 'yes') return true;
      if (value == 'false' || value == '0' || value == 'no') return false;
    }
    return null;
  }

  String _readSafeText(Map<String, dynamic> payload, String fallback) {
    const keys = [
      'cleanMessage',
      'sanitizedText',
      'safeText',
      'maskedText',
      'message',
      'text',
    ];

    for (final key in keys) {
      final raw = payload[key];
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }
    return fallback;
  }
}

class ContentModerationResult {
  const ContentModerationResult({
    required this.allow,
    required this.safeText,
    required this.reason,
  });

  factory ContentModerationResult.allow(String text) => ContentModerationResult(
        allow: true,
        safeText: text,
        reason: '',
      );

  const ContentModerationResult.block(String reasonCode)
      : allow = false,
        safeText = '',
        reason = reasonCode;

  final bool allow;
  final String safeText;
  final String reason;
}

class ContentModerationBlockedException implements Exception {
  const ContentModerationBlockedException(this.reason);

  final String reason;

  @override
  String toString() => 'ContentModerationBlockedException($reason)';
}

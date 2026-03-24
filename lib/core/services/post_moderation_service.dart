import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/core/services/moderation_result.dart';
import 'package:http/http.dart' as http;

class PostModerationService {
  PostModerationService._();

  static final PostModerationService instance = PostModerationService._();

  static const String _webhookUrl = String.fromEnvironment(
    'N8N_MODERATION_WEBHOOK',
    defaultValue: 'https://n8n.tgstack.dev/webhook/HowAreYou',
  );
  static const String _token = String.fromEnvironment(
    'N8N_MODERATION_TOKEN',
    defaultValue: 'CHANGE_ME_TOKEN',
  );
  static const Duration _timeout = Duration(seconds: 8);

  final http.Client _httpClient = http.Client();

  Future<ModerationResult> moderateImage({
    required String userId,
    required String caption,
    List<String> imageUrls = const <String>[],
    List<String> imageNotes = const <String>[],
  }) {
    return _moderate(
      payload: <String, dynamic>{
        'action': 'image_moderate',
        'token': _token,
        'user_id': userId,
        'caption': caption,
        'image_urls': imageUrls,
        'image_notes': imageNotes,
      },
      unavailableSummary: 'ระบบตรวจสอบรูปภาพไม่พร้อมใช้งานในขณะนี้',
    );
  }

  Future<ModerationResult> moderateVideo({
    required String userId,
    required String caption,
    String transcript = '',
    List<String> frameNotes = const <String>[],
    List<String> frameUrls = const <String>[],
  }) {
    return _moderate(
      payload: <String, dynamic>{
        'action': 'video_moderate',
        'token': _token,
        'user_id': userId,
        'caption': caption,
        'transcript': transcript,
        'frame_notes': frameNotes,
        'frame_urls': frameUrls,
      },
      unavailableSummary: 'ระบบตรวจสอบวิดีโอไม่พร้อมใช้งานในขณะนี้',
    );
  }

  Future<ModerationResult> _moderate({
    required Map<String, dynamic> payload,
    required String unavailableSummary,
  }) async {
    final uri = Uri.tryParse(_webhookUrl);
    if (uri == null) {
      return ModerationResult.blocked(
        summary: unavailableSummary,
        reasonCode: 'invalid-webhook-url',
      );
    }

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return ModerationResult.blocked(
          summary: unavailableSummary,
          status: response.statusCode,
          reasonCode: 'http-${response.statusCode}',
        );
      }

      final body = response.body.trim();
      if (body.isEmpty) {
        return ModerationResult.blocked(
          summary: unavailableSummary,
          status: response.statusCode,
          reasonCode: 'empty-body',
        );
      }

      final decodedPayload = _decodePayload(body);
      if (decodedPayload == null) {
        return ModerationResult.blocked(
          summary: unavailableSummary,
          status: response.statusCode,
          reasonCode: 'invalid-payload',
        );
      }

      final result = ModerationResult.fromJson(decodedPayload);
      if (result.status != 200) {
        return ModerationResult.blocked(
          summary:
              result.summary.isNotEmpty ? result.summary : unavailableSummary,
          status: result.status,
          reasonCode: 'response-status-${result.status ?? 'unknown'}',
        );
      }

      if (result.allowed != true) {
        return result.copyWith(
          allowed: false,
          safeToPost: false,
          summary: result.summary.isNotEmpty
              ? result.summary
              : 'ระบบไม่อนุญาตให้โพสต์',
        );
      }

      return result;
    } on TimeoutException {
      return ModerationResult.blocked(
        summary: unavailableSummary,
        reasonCode: 'timeout',
      );
    } catch (_) {
      return ModerationResult.blocked(
        summary: unavailableSummary,
        reasonCode: 'exception',
      );
    }
  }

  Map<String, dynamic>? _decodePayload(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return Map<String, dynamic>.from(decoded.first as Map);
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}

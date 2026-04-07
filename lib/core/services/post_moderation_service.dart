import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_application_1/core/config/app_env.dart';
import 'package:flutter_application_1/core/services/moderation_result.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

class PostModerationService {
  PostModerationService._();

  static final PostModerationService instance = PostModerationService._();

  static const String _defaultWebhookUrl =
      'https://n8n.tgstack.dev/webhook/HowAreYouMediaBinary';
  static const String _defaultToken = 'howareyou_moderation_2026_secret';
  static const int _defaultTimeoutSeconds = 90;

  final http.Client _httpClient = http.Client();

  String get _webhookUrl => AppEnv.string(
        'N8N_MEDIA_BINARY_WEBHOOK',
        defaultValue: _defaultWebhookUrl,
        compileTimeValue: const bool.hasEnvironment('N8N_MEDIA_BINARY_WEBHOOK')
            ? const String.fromEnvironment('N8N_MEDIA_BINARY_WEBHOOK')
            : null,
      );

  String get _token => AppEnv.string(
        'N8N_MODERATION_TOKEN',
        defaultValue: _defaultToken,
        compileTimeValue: const bool.hasEnvironment('N8N_MODERATION_TOKEN')
            ? const String.fromEnvironment('N8N_MODERATION_TOKEN')
            : null,
      );

  Duration get _timeout {
    final rawTimeout = AppEnv.string(
      'N8N_MEDIA_MODERATION_TIMEOUT_SECONDS',
      defaultValue: '$_defaultTimeoutSeconds',
      compileTimeValue:
          const bool.hasEnvironment('N8N_MEDIA_MODERATION_TIMEOUT_SECONDS')
              ? const String.fromEnvironment(
                  'N8N_MEDIA_MODERATION_TIMEOUT_SECONDS',
                )
              : null,
    );
    final timeoutSeconds = int.tryParse(rawTimeout.trim());
    if (timeoutSeconds == null || timeoutSeconds <= 0) {
      return const Duration(seconds: _defaultTimeoutSeconds);
    }
    return Duration(seconds: timeoutSeconds);
  }

  Future<ModerationResult> moderateImage({
    required String userId,
    required String caption,
    required Uint8List imageBytes,
    String imageFileName = 'image.jpg',
    List<String> imageUrls = const <String>[],
    List<String> imageNotes = const <String>[],
  }) {
    if (imageBytes.isEmpty) {
      return Future<ModerationResult>.value(
        ModerationResult.blocked(
          summary: 'ไม่พบไฟล์รูปสำหรับตรวจสอบ',
          reasonCode: 'missing-image-bytes',
        ),
      );
    }

    return _moderateBinary(
      mediaBytes: imageBytes,
      mediaFileName: imageFileName,
      fields: <String, String>{
        'action': 'image_moderate',
        'media_type': 'image',
        'moderation_type': 'image',
        'is_video': 'false',
        'token': _token,
        'user_id': userId,
        'caption': caption.trim(),
        'image_urls': imageUrls.join('\n'),
        'image_notes': imageNotes.join('\n'),
      },
      unavailableSummary: 'ระบบตรวจสอบรูปภาพไม่พร้อมใช้งานในขณะนี้',
    );
  }

  Future<ModerationResult> moderateVideo({
    required String userId,
    required String caption,
    required Uint8List videoBytes,
    String videoFileName = 'video.mp4',
    String transcript = '',
    List<String> frameNotes = const <String>[],
    List<String> frameUrls = const <String>[],
  }) {
    if (videoBytes.isEmpty) {
      return Future<ModerationResult>.value(
        ModerationResult.blocked(
          summary: 'ไม่พบไฟล์วิดีโอสำหรับตรวจสอบ',
          reasonCode: 'missing-video-bytes',
        ),
      );
    }

    final normalizedVideoFileName = _normalizedVideoFileName(videoFileName);
    return _moderateBinary(
      mediaBytes: videoBytes,
      mediaFileName: normalizedVideoFileName,
      fields: <String, String>{
        'action': 'video_moderate',
        'media_type': 'video',
        'moderation_type': 'video',
        'is_video': 'true',
        'token': _token,
        'user_id': userId,
        'caption': caption.trim(),
        'transcript': transcript.trim(),
        'frame_notes': frameNotes.join('\n'),
        'frame_urls': frameUrls.join('\n'),
      },
      unavailableSummary: 'ระบบตรวจสอบวิดีโอไม่พร้อมใช้งานในขณะนี้',
    );
  }

  Future<ModerationResult> _moderateBinary({
    required Uint8List mediaBytes,
    required String mediaFileName,
    required Map<String, String> fields,
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
      final request = http.MultipartRequest('POST', uri);
      fields.forEach((key, value) {
        if (value.trim().isNotEmpty) {
          request.fields[key] = value;
        }
      });
      final mediaType = _contentTypeForFileName(mediaFileName);
      request.fields['file_size_bytes'] = mediaBytes.lengthInBytes.toString();
      request.fields['media_mime_type'] = mediaType.mimeType;
      final action = request.fields['action']?.trim().toLowerCase() ?? '';
      if (action == 'video_moderate') {
        request.fields['media_type'] = 'video';
      } else if (action == 'image_moderate') {
        request.fields['media_type'] = 'image';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'media',
          mediaBytes,
          filename: _normalizedFileName(mediaFileName),
          contentType: mediaType,
        ),
      );

      final streamedResponse = await _httpClient.send(request).timeout(_timeout);
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        return ModerationResult.blocked(
          summary: unavailableSummary,
          status: streamedResponse.statusCode,
          reasonCode: 'http-${streamedResponse.statusCode}',
        );
      }

      final body = responseBody.trim();
      if (body.isEmpty) {
        return ModerationResult.blocked(
          summary: unavailableSummary,
          status: streamedResponse.statusCode,
          reasonCode: 'empty-body',
        );
      }

      final decodedPayload = _decodePayload(body);
      if (decodedPayload == null) {
        return ModerationResult.blocked(
          summary: unavailableSummary,
          status: streamedResponse.statusCode,
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

  String _normalizedFileName(String rawFileName) {
    final trimmed = rawFileName.trim();
    if (trimmed.isEmpty) {
      return 'media.bin';
    }
    return trimmed;
  }

  String _normalizedVideoFileName(String rawFileName) {
    final normalized = _normalizedFileName(rawFileName);
    final lowered = normalized.toLowerCase();
    final hasVideoExtension = lowered.endsWith('.mp4') ||
        lowered.endsWith('.mov') ||
        lowered.endsWith('.m4v') ||
        lowered.endsWith('.avi') ||
        lowered.endsWith('.webm') ||
        lowered.endsWith('.mkv');
    if (hasVideoExtension) {
      return normalized;
    }
    if (normalized == 'media.bin') {
      return 'video.mp4';
    }
    return '$normalized.mp4';
  }

  http_parser.MediaType _contentTypeForFileName(String rawFileName) {
    final fileName = rawFileName.trim().toLowerCase();
    if (fileName.endsWith('.png')) {
      return http_parser.MediaType('image', 'png');
    }
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return http_parser.MediaType('image', 'jpeg');
    }
    if (fileName.endsWith('.webp')) {
      return http_parser.MediaType('image', 'webp');
    }
    if (fileName.endsWith('.gif')) {
      return http_parser.MediaType('image', 'gif');
    }
    if (fileName.endsWith('.mov')) {
      return http_parser.MediaType('video', 'quicktime');
    }
    if (fileName.endsWith('.m4v')) {
      return http_parser.MediaType('video', 'x-m4v');
    }
    if (fileName.endsWith('.avi')) {
      return http_parser.MediaType('video', 'x-msvideo');
    }
    if (fileName.endsWith('.webm')) {
      return http_parser.MediaType('video', 'webm');
    }
    if (fileName.endsWith('.mkv')) {
      return http_parser.MediaType('video', 'x-matroska');
    }
    if (fileName.endsWith('.mp4')) {
      return http_parser.MediaType('video', 'mp4');
    }
    return http_parser.MediaType('application', 'octet-stream');
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

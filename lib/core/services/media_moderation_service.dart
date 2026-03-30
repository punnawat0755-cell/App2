import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/core/config/app_env.dart';
import 'package:flutter_application_1/core/services/moderation_result.dart';

class MediaModerationService {
  MediaModerationService._();

  static final MediaModerationService instance = MediaModerationService._();

  static const String _defaultWebhookUrl =
      'https://n8n.tgstack.dev/webhook/HowAreYouMediaBinary';
  static const String _defaultToken = 'howareyou_moderation_2026_secret';
  static const Duration _timeout = Duration(seconds: 25);

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

  Future<ModerationResult> moderateImageBeforePost({
    required String userId,
    required XFile imageFile,
    String caption = '',
  }) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Future<ModerationResult>.value(
        ModerationResult.blocked(
          summary: 'ไม่สามารถยืนยันผู้ใช้เพื่อส่งตรวจสอบรูปภาพได้',
          reasonCode: 'missing-user-id',
        ),
      );
    }

    if (_hasNoReadableFile(imageFile)) {
      return Future<ModerationResult>.value(
        ModerationResult.blocked(
          summary: 'ไม่พบไฟล์รูปสำหรับตรวจสอบ',
          reasonCode: 'missing-image-file',
        ),
      );
    }

    return _moderateMedia(
      mediaFile: imageFile,
      fields: _buildFields(
        userId: normalizedUserId,
        caption: caption,
      ),
      unavailableSummary:
          'ระบบตรวจสอบรูปภาพไม่พร้อมใช้งาน จึงยังไม่อนุญาตให้โพสต์',
    );
  }

  Future<ModerationResult> moderateVideoBeforePost({
    required String userId,
    required XFile videoFile,
    String caption = '',
    String transcript = '',
  }) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Future<ModerationResult>.value(
        ModerationResult.blocked(
          summary: 'ไม่สามารถยืนยันผู้ใช้เพื่อส่งตรวจสอบวิดีโอได้',
          reasonCode: 'missing-user-id',
        ),
      );
    }

    if (_hasNoReadableFile(videoFile)) {
      return Future<ModerationResult>.value(
        ModerationResult.blocked(
          summary: 'ไม่พบไฟล์วิดีโอสำหรับตรวจสอบ',
          reasonCode: 'missing-video-file',
        ),
      );
    }

    return _moderateMedia(
      mediaFile: videoFile,
      fields: _buildFields(
        userId: normalizedUserId,
        caption: caption,
        transcript: transcript,
      ),
      unavailableSummary:
          'ระบบตรวจสอบวิดีโอไม่พร้อมใช้งาน จึงยังไม่อนุญาตให้โพสต์',
    );
  }

  Map<String, String> _buildFields({
    required String userId,
    String caption = '',
    String transcript = '',
  }) {
    final fields = <String, String>{
      'token': _token,
      'user_id': userId,
    };

    final normalizedCaption = caption.trim();
    if (normalizedCaption.isNotEmpty) {
      fields['caption'] = normalizedCaption;
    }

    final normalizedTranscript = transcript.trim();
    if (normalizedTranscript.isNotEmpty) {
      fields['transcript'] = normalizedTranscript;
    }

    return fields;
  }

  Future<ModerationResult> _moderateMedia({
    required XFile mediaFile,
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

    final mimeType = _inferMimeType(mediaFile.name, mediaFile.path);
    final request = http.MultipartRequest('POST', uri);
    request.fields.addAll(fields);

    debugPrint('media moderation request url=${uri.toString()}');
    debugPrint('media moderation file path=${mediaFile.path}');
    debugPrint('media moderation mime type=$mimeType');

    try {
      request.files.add(
        await http.MultipartFile.fromPath(
          'media',
          mediaFile.path,
          filename: _normalizedFileName(mediaFile.name),
        ),
      );
    } catch (_) {
      final bytes = await mediaFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'media',
          bytes,
          filename: _normalizedFileName(mediaFile.name),
        ),
      );
    }

    try {
      final streamedResponse =
          await _httpClient.send(request).timeout(_timeout);
      final responseBody = await streamedResponse.stream.bytesToString();

      debugPrint('media moderation response body=$responseBody');

      if (streamedResponse.statusCode != 200) {
        final normalizedBody = responseBody.trim();
        final decodedPayload = _decodePayload(normalizedBody);
        if (decodedPayload != null) {
          final parsedResult = ModerationResult.fromJson(decodedPayload);
          final parsedReasonCode = _firstReasonCode(parsedResult.reasonCodes);
          return ModerationResult.blocked(
            summary: parsedResult.summary.isNotEmpty
                ? parsedResult.summary
                : unavailableSummary,
            status: streamedResponse.statusCode,
            reasonCode:
                parsedReasonCode ?? 'http-${streamedResponse.statusCode}',
          );
        }
        return ModerationResult.blocked(
          summary: unavailableSummary,
          status: streamedResponse.statusCode,
          reasonCode: 'http-${streamedResponse.statusCode}',
        );
      }

      final trimmedBody = responseBody.trim();
      if (trimmedBody.isEmpty) {
        return ModerationResult.blocked(
          summary: unavailableSummary,
          status: streamedResponse.statusCode,
          reasonCode: 'empty-body',
        );
      }

      final decodedPayload = _decodePayload(trimmedBody);
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
              : 'รูปภาพและวิดีโอไม่เหมาะสมจึงไม่อนุญาตให้โพสต์',
        );
      }

      return result;
    } on TimeoutException {
      debugPrint('media moderation timeout after ${_timeout.inSeconds}s');
      return ModerationResult.blocked(
        summary: 'ระบบตรวจสอบรูป/วิดีโอใช้เวลานานเกินกำหนด กรุณาลองใหม่',
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

  bool _hasNoReadableFile(XFile file) {
    final name = file.name.trim();
    final path = file.path.trim();
    return name.isEmpty && path.isEmpty;
  }

  String _normalizedFileName(String rawFileName) {
    final trimmed = rawFileName.trim();
    if (trimmed.isEmpty) {
      return 'media.bin';
    }
    return trimmed;
  }

  String? _firstReasonCode(List<String> reasonCodes) {
    if (reasonCodes.isEmpty) {
      return null;
    }
    final code = reasonCodes.first.trim();
    if (code.isEmpty) {
      return null;
    }
    return code;
  }

  String _inferMimeType(String fileName, String filePath) {
    final normalizedName = fileName.trim().toLowerCase();
    final normalizedPath = filePath.trim().toLowerCase();
    final source = normalizedName.isNotEmpty ? normalizedName : normalizedPath;

    if (source.endsWith('.png')) return 'image/png';
    if (source.endsWith('.jpg') || source.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (source.endsWith('.webp')) return 'image/webp';
    if (source.endsWith('.gif')) return 'image/gif';
    if (source.endsWith('.heic')) return 'image/heic';
    if (source.endsWith('.heif')) return 'image/heif';
    if (source.endsWith('.mp4')) return 'video/mp4';
    if (source.endsWith('.mov')) return 'video/quicktime';
    if (source.endsWith('.m4v')) return 'video/x-m4v';
    if (source.endsWith('.avi')) return 'video/x-msvideo';
    if (source.endsWith('.webm')) return 'video/webm';
    if (source.endsWith('.mkv')) return 'video/x-matroska';

    return 'application/octet-stream';
  }
}

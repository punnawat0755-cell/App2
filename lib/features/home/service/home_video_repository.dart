import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:flutter_application_1/features/home/model/home_video_clip.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeVideoRepository {
  HomeVideoRepository({SupabaseClient? client}) : _client = client ?? supabase;

  static const _postsTable = 'posts';
  static const _postMediaTable = 'post_media';
  static const _profilesTable = 'profiles';
  static const _approvePostRpc = 'approve_post';
  static const _videoMediaType = 'video';
  static const _signedVideoUrlTtlSeconds = 60 * 60 * 24;
  static const _defaultBucketConfig = String.fromEnvironment(
    'SUPABASE_FEED_IMAGE_BUCKET',
    defaultValue: 'app_media',
  );

  final SupabaseClient _client;
  final int _sessionSeed = DateTime.now().microsecondsSinceEpoch;

  String get _defaultBucket => _normalizeBucketName(_defaultBucketConfig);

  Stream<List<HomeVideoClip>> watchVideoClips() {
    late final StreamController<List<HomeVideoClip>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? postsSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? mediaSubscription;

    List<Map<String, dynamic>> latestPostRows = const [];
    List<Map<String, dynamic>> latestMediaRows = const [];
    var hasLoadedPosts = false;
    var hasLoadedMedia = false;

    Future<void> emitMappedClips() async {
      if (!hasLoadedPosts || !hasLoadedMedia) {
        return;
      }

      try {
        controller.add(await _mapVideoClips(latestPostRows, latestMediaRows));
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
    }

    controller = StreamController<List<HomeVideoClip>>(
      onListen: () {
        postsSubscription = _client
            .from(_postsTable)
            .stream(primaryKey: const ['id'])
            .order('created_at', ascending: false)
            .listen(
              (rows) {
                latestPostRows = rows
                    .map<Map<String, dynamic>>(
                      (row) => Map<String, dynamic>.from(row),
                    )
                    .toList();
                hasLoadedPosts = true;
                unawaited(emitMappedClips());
              },
              onError: controller.addError,
            );

        mediaSubscription = _client
            .from(_postMediaTable)
            .stream(primaryKey: const ['post_id', 'storage_path'])
            .eq('media_type', _videoMediaType)
            .listen(
              (rows) {
                latestMediaRows = rows
                    .map<Map<String, dynamic>>(
                      (row) => Map<String, dynamic>.from(row),
                    )
                    .toList();
                hasLoadedMedia = true;
                unawaited(emitMappedClips());
              },
              onError: controller.addError,
            );
      },
      onCancel: () async {
        await postsSubscription?.cancel();
        await mediaSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> createVideoClip({
    required Uint8List videoBytes,
    required String videoFileName,
    String? videoFilePath,
    required String caption,
  }) async {
    final user = _requireUser();
    final normalizedCaption = caption.trim();

    String? createdPostId;
    String? uploadedVideoPath;
    try {
      final postId = await _insertPost(
        userId: user.id,
        content: normalizedCaption,
      );
      createdPostId = postId;

      final extension = _resolveVideoExtension(
        videoFileName,
        filePath: videoFilePath,
      );
      final fileName = _resolveStorageFileName(videoFileName, extension);
      final storagePath = 'posts/${user.id}/$postId/$fileName';

      try {
        await _client.storage.from(_defaultBucket).uploadBinary(
              storagePath,
              videoBytes,
              fileOptions: FileOptions(
                cacheControl: '3600',
                contentType: _contentTypeForVideoExtension(extension),
              ),
            );
      } on StorageException catch (error) {
        if (_looksLikeMissingBucket(error)) {
          throw HomeVideoBucketNotFoundException(_defaultBucket);
        }
        if (_looksLikeUnauthorizedStorage(error)) {
          throw HomeVideoUploadUnauthorizedException(
            bucketName: _defaultBucket,
            storagePath: storagePath,
          );
        }
        rethrow;
      }
      uploadedVideoPath = storagePath;

      await _client.from(_postMediaTable).insert({
        'post_id': postId,
        'media_type': _videoMediaType,
        'storage_bucket': _defaultBucket,
        'storage_path': storagePath,
        'public_url': _client.storage.from(_defaultBucket).getPublicUrl(
              storagePath,
            ),
        'thumbnail_url': null,
        'width': null,
        'height': null,
        'duration_sec': null,
        'file_size_bytes': videoBytes.lengthInBytes,
        'order_no': 0,
      });

      await _approvePost(
        postId: postId,
        userId: user.id,
      );
    } catch (error) {
      if (uploadedVideoPath != null) {
        await _deleteStorageObject(uploadedVideoPath);
      }
      if (createdPostId != null) {
        await _deletePostRow(postId: createdPostId, userId: user.id);
      }
      rethrow;
    }
  }

  Future<List<HomeVideoClip>> _mapVideoClips(
    List<Map<String, dynamic>> postRows,
    List<Map<String, dynamic>> mediaRows,
  ) async {
    final postsById = <String, Map<String, dynamic>>{};
    final userIds = <String>{};

    for (final row in postRows) {
      final postId = row['id']?.toString() ?? '';
      if (postId.isEmpty) {
        continue;
      }

      postsById[postId] = row;
      final userId = row['user_id']?.toString() ?? '';
      if (userId.isNotEmpty) {
        userIds.add(userId);
      }
    }

    final authorNamesById = await _loadAuthorNames(userIds.toList());
    final clips = <HomeVideoClip>[];

    for (final row in mediaRows) {
      final postId = row['post_id']?.toString() ?? '';
      final post = postsById[postId];
      if (post == null) {
        continue;
      }

      final videoUrl = await _resolveMediaUrl(row);
      if (videoUrl.isEmpty) {
        continue;
      }

      final userId = post['user_id']?.toString() ?? '';
      final orderNo = _toInt(row['order_no']);
      final storagePath = row['storage_path']?.toString().trim() ?? '';
      final publicUrl = row['public_url']?.toString().trim() ?? videoUrl;
      final clipId = storagePath.isNotEmpty
          ? '$postId|$storagePath'
          : '$postId|$orderNo|$publicUrl';

      clips.add(
        HomeVideoClip(
          id: clipId,
          postId: postId,
          authorId: userId,
          authorName: authorNamesById[userId] ?? 'ผู้ใช้',
          caption: post['content_text']?.toString().trim() ?? '',
          videoUrl: videoUrl,
          thumbnailUrl: _toOptionalText(row['thumbnail_url']),
          createdAt: _toDateTime(post['created_at']),
          orderNo: orderNo,
        ),
      );
    }

    clips.sort((a, b) {
      final randomCompare =
          _randomSortKey(a.id).compareTo(_randomSortKey(b.id));
      if (randomCompare != 0) {
        return randomCompare;
      }

      final createdCompare = b.createdAt.compareTo(a.createdAt);
      if (createdCompare != 0) {
        return createdCompare;
      }

      return a.orderNo.compareTo(b.orderNo);
    });

    return clips;
  }

  Future<Map<String, String>> _loadAuthorNames(List<String> userIds) async {
    if (userIds.isEmpty) {
      return const <String, String>{};
    }

    final authorNamesById = <String, String>{};
    try {
      final profiles = await _client
          .from(_profilesTable)
          .select('id, username')
          .inFilter('id', userIds);

      for (final row in profiles) {
        final map = Map<String, dynamic>.from(row);
        final userId = map['id']?.toString() ?? '';
        final username = map['username']?.toString().trim() ?? '';
        if (userId.isEmpty || username.isEmpty) {
          continue;
        }
        authorNamesById[userId] = username;
      }
    } catch (_) {
      // Keep fallback names when profiles cannot be loaded.
    }

    return authorNamesById;
  }

  Future<String> _resolveMediaUrl(Map<String, dynamic> row) async {
    final publicUrl = row['public_url']?.toString().trim() ?? '';
    final storagePath = row['storage_path']?.toString().trim() ?? '';
    final bucket = _normalizeBucketName(
      row['storage_bucket']?.toString() ?? _defaultBucket,
    );

    if (storagePath.isNotEmpty) {
      try {
        final signedUrl = await _client.storage
            .from(bucket)
            .createSignedUrl(storagePath, _signedVideoUrlTtlSeconds);
        final normalizedSignedUrl = signedUrl.trim();
        if (normalizedSignedUrl.isNotEmpty) {
          return normalizedSignedUrl;
        }
      } catch (_) {
        // Fall back to public URL when signing is unavailable.
      }
    }

    if (publicUrl.isNotEmpty) {
      return publicUrl;
    }

    if (storagePath.isNotEmpty) {
      return _client.storage.from(bucket).getPublicUrl(storagePath);
    }

    return '';
  }

  String? _toOptionalText(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value.toLocal();
    }

    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed?.toLocal() ?? DateTime.now();
  }

  String _normalizeBucketName(String rawBucketName) {
    final trimmed = rawBucketName.trim();
    if (trimmed.isEmpty) {
      return 'app_media';
    }

    const schemaPrefix = 'public.';
    if (trimmed.startsWith(schemaPrefix)) {
      return trimmed.substring(schemaPrefix.length);
    }

    return trimmed;
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('กรุณาเข้าสู่ระบบอีกครั้ง');
    }
    return user;
  }

  Future<String> _insertPost({
    required String userId,
    required String content,
  }) async {
    final insertedRow = await _client
        .from(_postsTable)
        .insert({
          'user_id': userId,
          'content_text': content,
        })
        .select('id')
        .single();

    final postId = insertedRow['id']?.toString().trim();
    if (postId == null || postId.isEmpty) {
      throw const PostgrestException(
        message: 'ไม่สามารถอ่านรหัสโพสต์ที่เพิ่งสร้างได้',
      );
    }

    return postId;
  }

  Future<void> _deleteStorageObject(String storagePath) async {
    try {
      await _client.storage.from(_defaultBucket).remove([storagePath]);
    } catch (_) {
      // Ignore cleanup failures to avoid masking the main action result.
    }
  }

  Future<void> _deletePostRow({
    required String postId,
    required String userId,
  }) async {
    try {
      await _client
          .from(_postsTable)
          .delete()
          .eq('id', postId)
          .eq('user_id', userId);
    } catch (_) {
      // Ignore cleanup failures to avoid masking the main action result.
    }
  }

  Future<void> _approvePost({
    required String postId,
    required String userId,
  }) async {
    if (await _tryApprovePostViaRpc(postId: postId)) {
      return;
    }
    if (await _trySetPostVisibleWithUpdate(postId: postId, userId: userId)) {
      return;
    }
    throw HomeVideoApprovePostFailedException(postId: postId);
  }

  Future<bool> _tryApprovePostViaRpc({required String postId}) async {
    final candidateParams = <Map<String, dynamic>>[
      {'post_id': postId},
      {'p_post_id': postId},
      {'_post_id': postId},
    ];

    for (final params in candidateParams) {
      try {
        await _client.rpc(_approvePostRpc, params: params);
        return true;
      } catch (_) {
        // Try next known function signature.
      }
    }

    return false;
  }

  Future<bool> _trySetPostVisibleWithUpdate({
    required String postId,
    required String userId,
  }) async {
    final candidatePayloads = <Map<String, dynamic>>[
      {
        'is_visible': true,
        'moderation_status': 'approved',
        'status': 'active',
      },
      {
        'is_visible': true,
        'moderation_status': 'approved',
      },
      {
        'is_visible': true,
        'status': 'active',
      },
      {
        'is_visible': true,
      },
      {
        'moderation_status': 'approved',
        'status': 'active',
      },
      {
        'moderation_status': 'approved',
      },
      {
        'status': 'active',
      },
    ];

    for (final payload in candidatePayloads) {
      try {
        final updated = await _client
            .from(_postsTable)
            .update(payload)
            .eq('id', postId)
            .eq('user_id', userId)
            .select('id')
            .maybeSingle();

        if (updated != null) {
          return true;
        }
      } catch (_) {
        // Try next payload for schema compatibility.
      }
    }

    return false;
  }

  String _resolveVideoExtension(String fileName, {String? filePath}) {
    String extensionFrom(String source) {
      final trimmed = source.trim();
      final dotIndex = trimmed.lastIndexOf('.');
      if (dotIndex == -1 || dotIndex == trimmed.length - 1) {
        return '';
      }
      return trimmed.substring(dotIndex + 1).toLowerCase();
    }

    var extension = extensionFrom(fileName);
    if (extension.isEmpty && filePath != null && filePath.trim().isNotEmpty) {
      extension = extensionFrom(filePath);
    }

    switch (extension) {
      case 'mp4':
      case 'mov':
      case 'm4v':
      case 'avi':
      case 'webm':
      case 'mkv':
        return extension;
      default:
        return 'mp4';
    }
  }

  String _resolveStorageFileName(String fileName, String extension) {
    final trimmed = fileName.trim();
    final dotIndex = trimmed.lastIndexOf('.');
    final baseName = dotIndex > 0 ? trimmed.substring(0, dotIndex) : trimmed;
    final sanitizedBaseName = baseName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final normalizedBaseName =
        sanitizedBaseName.isEmpty ? 'clip' : sanitizedBaseName;
    return '$normalizedBaseName.$extension';
  }

  String _contentTypeForVideoExtension(String extension) {
    switch (extension) {
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case 'm4v':
      case 'mp4':
      default:
        return 'video/mp4';
    }
  }

  bool _looksLikeMissingBucket(StorageException error) {
    final message = error.toString().toLowerCase();
    return message.contains('bucket not found') ||
        message.contains('statuscode: 404') ||
        message.contains('status code: 404');
  }

  bool _looksLikeUnauthorizedStorage(StorageException error) {
    final message = error.toString().toLowerCase();
    return message.contains('row-level security policy') ||
        message.contains('unauthorized') ||
        message.contains('statuscode: 403') ||
        message.contains('status code: 403');
  }

  int _randomSortKey(String clipId) {
    var hash = _sessionSeed;
    for (final codeUnit in clipId.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
  }
}

class HomeVideoBucketNotFoundException implements Exception {
  const HomeVideoBucketNotFoundException(this.bucketName);

  final String bucketName;

  @override
  String toString() =>
      'HomeVideoBucketNotFoundException(bucketName: $bucketName)';
}

class HomeVideoUploadUnauthorizedException implements Exception {
  const HomeVideoUploadUnauthorizedException({
    required this.bucketName,
    required this.storagePath,
  });

  final String bucketName;
  final String storagePath;

  @override
  String toString() =>
      'HomeVideoUploadUnauthorizedException(bucketName: $bucketName, storagePath: $storagePath)';
}

class HomeVideoApprovePostFailedException implements Exception {
  const HomeVideoApprovePostFailedException({
    required this.postId,
  });

  final String postId;

  @override
  String toString() => 'HomeVideoApprovePostFailedException(postId: $postId)';
}

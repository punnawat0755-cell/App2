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
  static const _videoMediaType = 'video';
  static const _defaultBucketConfig = String.fromEnvironment(
    'SUPABASE_FEED_IMAGE_BUCKET',
    defaultValue: 'app_media',
  );
  static const Duration _signedUrlTtl = Duration(minutes: 55);
  static const int _maxAuthorCacheEntries = 500;
  static const int _maxMediaUrlCacheEntries = 700;

  final SupabaseClient _client;
  final int _sessionSeed = DateTime.now().microsecondsSinceEpoch;
  final Map<String, String> _cachedAuthorNamesById = <String, String>{};
  final Map<String, _CachedSignedUrl> _cachedMediaUrls =
      <String, _CachedSignedUrl>{};
  final Map<String, Future<String>> _inFlightMediaUrlResolvers =
      <String, Future<String>>{};

  String get _defaultBucket => _normalizeBucketName(_defaultBucketConfig);

  Stream<List<HomeVideoClip>> watchVideoClips() {
    late final StreamController<List<HomeVideoClip>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? postsSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? mediaSubscription;
    Timer? remapDebounceTimer;
    var hasActiveListener = false;

    List<Map<String, dynamic>> latestPostRows = const [];
    var hasLoadedPosts = false;

    Future<void> emitMappedClips() async {
      if (!hasLoadedPosts) {
        return;
      }

      try {
        final postIds = latestPostRows
            .map((row) => row['id']?.toString() ?? '')
            .where((postId) => postId.isNotEmpty)
            .toSet()
            .toList();
        final mediaRows = await _loadVideoMediaRows(postIds);
        if (controller.isClosed) {
          return;
        }
        controller.add(await _mapVideoClips(latestPostRows, mediaRows));
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    Future<void> refreshPostsFromQuery({bool reportErrors = false}) async {
      try {
        final rows = await _loadVisiblePostRows();
        if (controller.isClosed) {
          return;
        }
        latestPostRows = rows;
        hasLoadedPosts = true;
        await emitMappedClips();
      } catch (error, stackTrace) {
        if (reportErrors && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    void scheduleEmitMappedClips({
      Duration delay = const Duration(milliseconds: 120),
    }) {
      if (!hasLoadedPosts || !hasActiveListener) {
        return;
      }
      remapDebounceTimer?.cancel();
      remapDebounceTimer = Timer(delay, () => unawaited(emitMappedClips()));
    }

    controller = StreamController<List<HomeVideoClip>>(
      onListen: () {
        hasActiveListener = true;
        unawaited(refreshPostsFromQuery(reportErrors: true));

        postsSubscription = _client
            .from(_postsTable)
            .stream(primaryKey: const ['id'])
            .order('created_at', ascending: false)
            .listen(
              (_) => unawaited(refreshPostsFromQuery()),
              onError: (_, __) => unawaited(refreshPostsFromQuery()),
            );

        mediaSubscription = _client
            .from(_postMediaTable)
            .stream(primaryKey: const ['post_id', 'storage_path'])
            .eq('media_type', _videoMediaType)
            .listen(
              (_) => scheduleEmitMappedClips(
                delay: const Duration(milliseconds: 80),
              ),
              onError: (_, __) => scheduleEmitMappedClips(
                delay: const Duration(milliseconds: 180),
              ),
            );
      },
      onCancel: () async {
        hasActiveListener = false;
        remapDebounceTimer?.cancel();
        await postsSubscription?.cancel();
        await mediaSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  Future<List<Map<String, dynamic>>> _loadVisiblePostRows() async {
    final currentUserId = _client.auth.currentUser?.id ?? '';

    try {
      final response = await _client.rpc(
        'get_posts_feed_fast',
        params: {'p_limit': 120, 'p_offset': 0},
      );
      if (response is! List) {
        return const [];
      }

      final rows = response
          .whereType<Map>()
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList();
      if (rows.isNotEmpty) {
        return rows;
      }
      // Legacy compatibility: if RPC returns nothing, query directly.
      return _loadLegacyCompatiblePostRows(currentUserId: currentUserId);
    } catch (_) {
      return _loadLegacyCompatiblePostRows(currentUserId: currentUserId);
    }
  }

  Future<List<Map<String, dynamic>>> _loadLegacyCompatiblePostRows({
    required String currentUserId,
  }) async {
    final rowsById = <String, Map<String, dynamic>>{};

    void absorbRows(Iterable<dynamic> rows) {
      for (final row in rows) {
        if (row is! Map) {
          continue;
        }
        final mapped = Map<String, dynamic>.from(row);
        final postId = mapped['id']?.toString() ?? '';
        if (postId.isEmpty) {
          continue;
        }
        rowsById[postId] = mapped;
      }
    }

    try {
      final broadRows = await _client
          .from(_postsTable)
          .select('*')
          .order('created_at', ascending: false)
          .limit(180);
      absorbRows(broadRows);
    } catch (_) {}

    if (rowsById.isEmpty) {
      return const [];
    }

    final filteredRows = rowsById.values.where((row) {
      final authorId = row['user_id']?.toString().trim() ?? '';
      if (currentUserId.isNotEmpty && authorId == currentUserId) {
        return true;
      }
      return _isReadableForOtherUsers(row);
    }).toList(growable: false);

    filteredRows.sort(
      (a, b) =>
          _toDateTime(b['created_at']).compareTo(_toDateTime(a['created_at'])),
    );
    return filteredRows;
  }

  Future<List<Map<String, dynamic>>> _loadVideoMediaRows(
    List<String> postIds,
  ) async {
    if (postIds.isEmpty) {
      return const [];
    }

    try {
      final strictRows = await _client
          .from(_postMediaTable)
          .select(
            'post_id, media_type, storage_bucket, storage_path, public_url, thumbnail_url, order_no',
          )
          .inFilter('post_id', postIds)
          .eq('media_type', _videoMediaType)
          .order('order_no', ascending: true);

      final strictMappedRows = strictRows
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList();
      if (strictMappedRows.isNotEmpty) {
        return strictMappedRows;
      }

      // Legacy compatibility: media_type may be empty on older rows.
      final legacyRows = await _client
          .from(_postMediaTable)
          .select(
            'post_id, media_type, storage_bucket, storage_path, public_url, thumbnail_url, order_no',
          )
          .inFilter('post_id', postIds)
          .order('order_no', ascending: true);
      return legacyRows
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .where(_isLikelyVideoMediaRow)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> createVideoClip({
    required Uint8List videoBytes,
    required String videoFileName,
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

      final extension = _resolveVideoExtension(videoFileName);
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
    final candidates = <_VideoClipCandidate>[];
    final postIdsWithVideoMedia = <String>{};
    for (final row in mediaRows) {
      final postId = row['post_id']?.toString() ?? '';
      final post = postsById[postId];
      if (post == null) {
        continue;
      }
      postIdsWithVideoMedia.add(postId);
      candidates.add(
        _VideoClipCandidate(
          postId: postId,
          post: post,
          mediaRow: row,
        ),
      );
    }

    // Legacy compatibility: allow direct video URL from posts table when post_media
    // is missing.
    for (final entry in postsById.entries) {
      if (postIdsWithVideoMedia.contains(entry.key)) {
        continue;
      }
      final mediaUrl = _extractLegacyVideoUrl(entry.value);
      if (mediaUrl == null) {
        continue;
      }
      candidates.add(
        _VideoClipCandidate(
          postId: entry.key,
          post: entry.value,
          mediaRow: <String, dynamic>{
            'post_id': entry.key,
            'media_type': _videoMediaType,
            'storage_bucket': null,
            'storage_path': '',
            'public_url': mediaUrl,
            'thumbnail_url': null,
            'order_no': 0,
          },
        ),
      );
    }

    final resolvedVideoUrls = await Future.wait(
      candidates.map((candidate) => _resolveMediaUrl(candidate.mediaRow)),
    );

    final clips = <HomeVideoClip>[];
    for (var index = 0; index < candidates.length; index++) {
      final candidate = candidates[index];
      final row = candidate.mediaRow;
      final post = candidate.post;
      final postId = candidate.postId;
      final videoUrl = resolvedVideoUrls[index];
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
    final missingUserIds = <String>[];
    for (final userId in userIds) {
      final cachedName = _cachedAuthorNamesById[userId];
      if (cachedName != null) {
        if (cachedName.isNotEmpty) {
          authorNamesById[userId] = cachedName;
        }
        continue;
      }
      missingUserIds.add(userId);
    }

    if (missingUserIds.isEmpty) {
      return authorNamesById;
    }

    try {
      final profiles = await _client
          .from(_profilesTable)
          .select('id, username')
          .inFilter('id', missingUserIds);

      final fetchedUserIds = <String>{};
      for (final row in profiles) {
        final map = Map<String, dynamic>.from(row);
        final userId = map['id']?.toString() ?? '';
        if (userId.isEmpty) {
          continue;
        }
        fetchedUserIds.add(userId);
        final username = map['username']?.toString().trim() ?? '';
        _cachedAuthorNamesById[userId] = username;
        if (username.isNotEmpty) {
          authorNamesById[userId] = username;
        }
      }

      for (final userId in missingUserIds) {
        if (!fetchedUserIds.contains(userId)) {
          _cachedAuthorNamesById[userId] = '';
        }
      }
      if (_cachedAuthorNamesById.length > _maxAuthorCacheEntries) {
        _cachedAuthorNamesById.clear();
      }
    } catch (_) {
      // Keep fallback names when profiles cannot be loaded.
    }

    return authorNamesById;
  }

  Future<String> _resolveMediaUrl(Map<String, dynamic> row) async {
    final publicUrl = row['public_url']?.toString().trim();
    final storagePath = row['storage_path']?.toString().trim() ?? '';
    if (storagePath.isEmpty) {
      return publicUrl ?? '';
    }

    final bucket = _normalizeBucketName(
      row['storage_bucket']?.toString() ?? _defaultBucket,
    );
    final cacheKey = '$bucket/$storagePath';
    final now = DateTime.now();
    final cachedUrl = _cachedMediaUrls[cacheKey];
    if (cachedUrl != null && cachedUrl.expiresAt.isAfter(now)) {
      return cachedUrl.url;
    }

    final inFlight = _inFlightMediaUrlResolvers[cacheKey];
    if (inFlight != null) {
      return inFlight;
    }

    Future<String> resolve() async {
      try {
        final signedUrl = await _client.storage.from(bucket).createSignedUrl(
              storagePath,
              60 * 60,
            );
        if (signedUrl.isNotEmpty) {
          _cachedMediaUrls[cacheKey] = _CachedSignedUrl(
            url: signedUrl,
            expiresAt: now.add(_signedUrlTtl),
          );
          _trimMediaUrlCacheIfNeeded();
          return signedUrl;
        }
      } catch (_) {
        // Continue with fallback below.
      }

      if (publicUrl != null && publicUrl.isNotEmpty) {
        _cachedMediaUrls[cacheKey] = _CachedSignedUrl(
          url: publicUrl,
          expiresAt: now.add(const Duration(hours: 6)),
        );
        _trimMediaUrlCacheIfNeeded();
        return publicUrl;
      }

      final fallbackUrl =
          _client.storage.from(bucket).getPublicUrl(storagePath);
      if (fallbackUrl.isNotEmpty) {
        _cachedMediaUrls[cacheKey] = _CachedSignedUrl(
          url: fallbackUrl,
          expiresAt: now.add(const Duration(hours: 6)),
        );
        _trimMediaUrlCacheIfNeeded();
      }
      return fallbackUrl;
    }

    final resolver = resolve();
    _inFlightMediaUrlResolvers[cacheKey] = resolver;
    try {
      return await resolver;
    } finally {
      _inFlightMediaUrlResolvers.remove(cacheKey);
    }
  }

  void _trimMediaUrlCacheIfNeeded() {
    if (_cachedMediaUrls.length > _maxMediaUrlCacheEntries) {
      _cachedMediaUrls.clear();
    }
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

  bool _isReadableForOtherUsers(Map<String, dynamic> row) {
    final status = row['status']?.toString().trim().toLowerCase() ?? '';
    if (status == 'draft' ||
        status == 'hidden' ||
        status == 'deleted' ||
        status == 'archived') {
      return false;
    }

    final isVisibleRaw = row['is_visible'];
    if (isVisibleRaw is bool && isVisibleRaw == false) {
      return false;
    }

    return true;
  }

  bool _isLikelyVideoMediaRow(Map<String, dynamic> row) {
    final mediaType = row['media_type']?.toString().trim().toLowerCase() ?? '';
    if (mediaType == _videoMediaType || mediaType.contains('video')) {
      return true;
    }
    if (mediaType == 'mp4' ||
        mediaType == 'mov' ||
        mediaType == 'm4v' ||
        mediaType == 'avi' ||
        mediaType == 'webm' ||
        mediaType == 'mkv') {
      return true;
    }

    if (mediaType.isNotEmpty) {
      return false;
    }

    final candidates = <String>[
      row['storage_path']?.toString().trim() ?? '',
      row['public_url']?.toString().trim() ?? '',
      row['thumbnail_url']?.toString().trim() ?? '',
    ];
    for (final candidate in candidates) {
      if (_looksLikeVideoPath(candidate)) {
        return true;
      }
    }
    return false;
  }

  String? _extractLegacyVideoUrl(Map<String, dynamic> row) {
    final candidates = <dynamic>[
      row['video_url'],
      row['media_url'],
      row['file_url'],
    ];

    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (text.startsWith('http') &&
          (_looksLikeVideoPath(text) || text.contains('/storage/v1/object/'))) {
        return text;
      }
    }
    return null;
  }

  bool _looksLikeVideoPath(String path) {
    final normalizedPath = path.trim().toLowerCase();
    if (normalizedPath.isEmpty) {
      return false;
    }

    return normalizedPath.endsWith('.mp4') ||
        normalizedPath.endsWith('.mov') ||
        normalizedPath.endsWith('.m4v') ||
        normalizedPath.endsWith('.avi') ||
        normalizedPath.endsWith('.webm') ||
        normalizedPath.endsWith('.mkv');
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
    final now = DateTime.now().toUtc().toIso8601String();

    final insertedRow = await _client
        .from(_postsTable)
        .insert({
          'user_id': userId,
          'content_text': content,
          'status': 'active',
          'moderation_status': 'approved',
          'is_visible': true,
          'moderated_at': now,
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

  String _resolveVideoExtension(String fileName) {
    final trimmed = fileName.trim();
    final dotIndex = trimmed.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == trimmed.length - 1) {
      return 'mp4';
    }

    final extension = trimmed.substring(dotIndex + 1).toLowerCase();
    switch (extension) {
      case 'mp4':
      case 'mov':
      case 'm4v':
      case 'avi':
      case 'webm':
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

class _VideoClipCandidate {
  const _VideoClipCandidate({
    required this.postId,
    required this.post,
    required this.mediaRow,
  });

  final String postId;
  final Map<String, dynamic> post;
  final Map<String, dynamic> mediaRow;
}

class _CachedSignedUrl {
  const _CachedSignedUrl({
    required this.url,
    required this.expiresAt,
  });

  final String url;
  final DateTime expiresAt;
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

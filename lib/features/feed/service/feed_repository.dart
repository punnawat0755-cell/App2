import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_application_1/core/services/coin_service.dart';
import 'package:flutter_application_1/core/services/content_moderation_service.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:flutter_application_1/features/feed/model/feed_comment.dart';
import 'package:flutter_application_1/features/feed/model/feed_post.dart';
import 'package:flutter_application_1/features/feed/service/feed_delete_service.dart';
import 'package:flutter_application_1/features/profile/model/profile_avatar_catalog.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedComposerIdentity {
  const FeedComposerIdentity({
    required this.userId,
    required this.authorName,
    required this.authorAvatarUrl,
  });

  final String userId;
  final String authorName;
  final String authorAvatarUrl;
}

class FeedRepository {
  FeedRepository({SupabaseClient? client}) : _client = client ?? supabase;

  static const _postsTable = 'posts';
  static const _postMediaTable = 'post_media';
  static const _postLikesTable = 'post_reactions';
  static const _postCommentsTable = 'post_comments';
  static const _profilesTable = 'profiles';
  static const List<String> _savedPostsTableCandidates = <String>[
    'user_saved_posts',
    'saved_posts',
    'post_saves',
  ];
  static const List<String> _savedPostIdColumnCandidates = <String>[
    'post_id',
    'saved_post_id',
  ];
  static const _feedImageBucketConfig = String.fromEnvironment(
    'SUPABASE_FEED_IMAGE_BUCKET',
    defaultValue: 'app_media',
  );
  static const _imageMediaType = 'image';
  static const _videoMediaType = 'video';
  static const _likeReaction = 'like';
  static const Duration _signedUrlTtl = Duration(minutes: 55);
  static const int _maxProfileCacheEntries = 600;
  static const int _maxMediaUrlCacheEntries = 800;

  final SupabaseClient _client;
  final StreamController<void> _allPostsRefreshController =
      StreamController<void>.broadcast();
  final StreamController<String> _authorPostsRefreshController =
      StreamController<String>.broadcast();
  late final FeedDeleteService _deleteService = FeedDeleteService(
    client: _client,
  );
  final ContentModerationService _moderationService =
      ContentModerationService.instance;
  final Map<String, String> _cachedNamesByUserId = <String, String>{};
  final Map<String, String> _cachedAvatarsByUserId = <String, String>{};
  final Map<String, _CachedSignedUrl> _cachedMediaUrls =
      <String, _CachedSignedUrl>{};
  final Map<String, Future<String?>> _inFlightMediaUrlResolvers =
      <String, Future<String?>>{};
  final Map<String, int> _liveLikeCountsByPostId = <String, int>{};
  final Map<String, int> _liveCommentCountsByPostId = <String, int>{};

  String get _feedImageBucket => _normalizeBucketName(_feedImageBucketConfig);

  bool get supportsLikeActions => true;

  Stream<List<FeedPost>> watchPosts() {
    return _watchMappedPosts();
  }

  Stream<List<FeedPost>> watchPostsByAuthor(String authorId) {
    return _watchMappedPosts(authorId: authorId);
  }

  Future<void> refreshPosts() async {
    _allPostsRefreshController.add(null);
  }

  Future<void> refreshPostsByAuthor(String authorId) async {
    final normalizedAuthorId = authorId.trim();
    if (normalizedAuthorId.isEmpty) {
      return;
    }
    _authorPostsRefreshController.add(normalizedAuthorId);
  }

  Stream<Set<String>> watchLikedPostIds(String userId) {
    return _client
        .from(_postLikesTable)
        .stream(primaryKey: const ['post_id', 'user_id'])
        .eq('user_id', userId)
        .map(
          (rows) => rows
              .where(
                (row) => row['reaction']?.toString() == _likeReaction,
              )
              .map((row) => row['post_id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toSet(),
        );
  }

  Future<List<Map<String, dynamic>>> getSavedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    _requireUser();

    final response = await _client.rpc(
      'get_saved_posts',
      params: {
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    if (response is! List) {
      return const <Map<String, dynamic>>[];
    }

    return response
        .whereType<Map>()
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<Set<String>> getSavedPostIds({
    int limit = 300,
    int offset = 0,
  }) async {
    final rows = await getSavedPosts(limit: limit, offset: offset);
    return rows
        .map(_extractSavedPostId)
        .where((postId) => postId.isNotEmpty)
        .toSet();
  }

  Future<void> savePost(String postId) async {
    final user = _requireUser();
    final normalizedPostId = postId.trim();

    if (normalizedPostId.isEmpty) {
      throw const PostgrestException(
        message: 'ไม่พบรหัสโพสต์สำหรับบันทึก',
      );
    }

    try {
      await _client.rpc(
        'save_post',
        params: {
          'p_post_id': normalizedPostId,
        },
      );
    } on PostgrestException catch (error) {
      if (_isRpcPostNotFound(error)) {
        final saved = await _savePostByDirectInsertFallback(
          userId: user.id,
          postId: normalizedPostId,
        );
        if (saved) {
          return;
        }
      }
      rethrow;
    }
  }

  Future<void> unsavePost(String postId) async {
    final user = _requireUser();
    final normalizedPostId = postId.trim();

    if (normalizedPostId.isEmpty) {
      throw const PostgrestException(
        message: 'ไม่พบรหัสโพสต์สำหรับยกเลิกบันทึก',
      );
    }

    try {
      await _client.rpc(
        'unsave_post',
        params: {
          'p_post_id': normalizedPostId,
        },
      );
    } on PostgrestException catch (error) {
      if (_isRpcPostNotFound(error)) {
        final removed = await _unsavePostByDirectDeleteFallback(
          userId: user.id,
          postId: normalizedPostId,
        );
        if (removed) {
          return;
        }
      }
      rethrow;
    }
  }

  Stream<List<FeedComment>> watchCommentsByPost(String postId) {
    if (postId.trim().isEmpty) {
      return Stream<List<FeedComment>>.value(const <FeedComment>[]);
    }

    late final StreamController<List<FeedComment>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? commentsSubscription;
    Timer? remapDebounceTimer;

    List<Map<String, dynamic>> latestRows = const [];
    var hasLoadedComments = false;

    Future<void> emitMappedComments() async {
      if (!hasLoadedComments) {
        return;
      }

      try {
        controller.add(await _mapComments(latestRows));
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
    }

    controller = StreamController<List<FeedComment>>(
      onListen: () {
        commentsSubscription = _client
            .from(_postCommentsTable)
            .stream(primaryKey: const ['id'])
            .eq('post_id', postId)
            .order('created_at', ascending: true)
            .listen(
              (rows) {
                latestRows = rows
                    .map<Map<String, dynamic>>(
                      (row) => Map<String, dynamic>.from(row),
                    )
                    .toList();
                hasLoadedComments = true;
                remapDebounceTimer?.cancel();
                remapDebounceTimer = Timer(
                  const Duration(milliseconds: 90),
                  () => unawaited(emitMappedComments()),
                );
              },
              onError: controller.addError,
            );
      },
      onCancel: () async {
        remapDebounceTimer?.cancel();
        await commentsSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  Future<FeedComposerIdentity> getComposerIdentity() async {
    final user = _requireUser();
    var authorName = _readNameFromAuth(user);
    var authorAvatarUrl = ProfileAvatarCatalog.defaultAvatar;

    try {
      final row = await _client
          .from(_profilesTable)
          .select('username, avatarurl')
          .eq('id', user.id)
          .maybeSingle();

      final username = row?['username']?.toString().trim();
      if (username != null && username.isNotEmpty) {
        authorName = username;
      }

      authorAvatarUrl = ProfileAvatarCatalog.normalize(
        row?['avatarurl']?.toString(),
      );
    } catch (_) {
      // Fall back to auth metadata if the profile row is unavailable.
    }

    return FeedComposerIdentity(
      userId: user.id,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
    );
  }

  Future<void> createPost({
    required String content,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final identity = await getComposerIdentity();
    final normalizedContent = content.trim();
    final selectedImageBytes = imageBytes;
    final hasImage =
        selectedImageBytes != null && selectedImageBytes.isNotEmpty;

    if (normalizedContent.isEmpty && !hasImage) {
      throw const PostgrestException(
        message: 'กรุณาเพิ่มข้อความหรือเลือกรูปภาพก่อนโพสต์',
      );
    }

    var safeText = normalizedContent;
    if (normalizedContent.isNotEmpty) {
      final moderation = await _moderationService.moderateText(
        source: 'feed_post',
        text: normalizedContent,
        metadata: {
          'userId': identity.userId,
          'authorName': identity.authorName,
        },
      );

      if (!moderation.allow) {
        throw ContentModerationBlockedException(moderation.reason);
      }

      safeText = moderation.safeText.trim().isNotEmpty
          ? moderation.safeText.trim()
          : normalizedContent;
    }

    String? createdPostId;
    String? uploadedImagePath;
    try {
      // FIX: ส่ง hasMedia เข้า _insertPost เพื่อ set status ให้ถูกต้อง
      final postId = await _insertPost(
        userId: identity.userId,
        content: safeText,
        hasMedia: hasImage,
      );
      createdPostId = postId;

      if (!hasImage) {
        await _rewardPostCreated(postId);
        await _refreshCoins();
        return;
      }

      final storagePath = await _uploadPostImage(
        postId: postId,
        userId: identity.userId,
        imageBytes: selectedImageBytes,
        imageFileName: imageFileName,
      );
      uploadedImagePath = storagePath;

      await _insertPostMedia(
        postId: postId,
        storagePath: storagePath,
        publicUrl: _client.storage.from(_feedImageBucket).getPublicUrl(
              storagePath,
            ),
        fileSizeBytes: selectedImageBytes.lengthInBytes,
      );
      await _rewardPostCreated(postId);
      await _refreshCoins();
    } catch (error) {
      if (uploadedImagePath != null) {
        await _deleteStorageObject(uploadedImagePath);
      }
      if (createdPostId != null && hasImage) {
        await _deletePostRow(postId: createdPostId, userId: identity.userId);
      }
      rethrow;
    }
  }

  Future<void> likePost(String postId) async {
    final user = _requireUser();
    await _client.from(_postLikesTable).upsert({
      'post_id': postId,
      'user_id': user.id,
      'reaction': _likeReaction,
    }, onConflict: 'post_id,user_id');
    await _refreshCoins();
  }

  Future<void> unlikePost(String postId) async {
    final user = _requireUser();
    await _client
        .from(_postLikesTable)
        .delete()
        .eq('post_id', postId)
        .eq('reaction', _likeReaction)
        .eq('user_id', user.id);
    await _refreshCoins();
  }

  Future<void> _rewardPostCreated(String postId) async {
    try {
      await _client.rpc('reward_post_created', params: {
        'p_post_id': postId,
      });
    } catch (_) {
      // Reward RPC may be unavailable in some environments.
    }
  }

  Future<void> createComment({
    required String postId,
    required String content,
  }) async {
    final identity = await getComposerIdentity();
    final normalizedContent = content.trim();

    if (postId.trim().isEmpty || normalizedContent.isEmpty) {
      throw const PostgrestException(
        message: 'กรุณากรอกความคิดเห็นก่อนส่ง',
      );
    }

    final moderation = await _moderationService.moderateText(
      source: 'feed_comment',
      text: normalizedContent,
      metadata: {
        'userId': identity.userId,
        'authorName': identity.authorName,
        'postId': postId,
      },
    );

    if (!moderation.allow) {
      throw ContentModerationBlockedException(moderation.reason);
    }

    final safeText = moderation.safeText.trim().isNotEmpty
        ? moderation.safeText.trim()
        : normalizedContent;

    await _client.from(_postCommentsTable).insert({
      'post_id': postId,
      'user_id': identity.userId,
      'content_text': safeText,
    });
  }

  Future<void> _refreshCoins() async {
    final coinService = Get.isRegistered<CoinService>()
        ? Get.find<CoinService>()
        : Get.put(CoinService(), permanent: true);
    await coinService.loadCoins();
  }

  Future<void> deletePost(String postId) async {
    await _deleteService.deletePostWithMedia(postId: postId);
  }

  Future<List<FeedPost>> _mapPosts(List<Map<String, dynamic>> rows) async {
    final postIds = rows
        .map((row) => row['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final authorIds = rows
        .map((row) => row['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final namesByUserId = <String, String>{};
    final avatarsByUserId = <String, String>{};
    final imageUrlsByPostId = <String, String>{};
    final postsWithVideoMedia = <String>{};
    final likeCountsByPostId = <String, int>{};
    final commentCountsByPostId = <String, int>{};

    if (authorIds.isNotEmpty) {
      await _loadProfiles(
        userIds: authorIds,
        namesByUserId: namesByUserId,
        avatarsByUserId: avatarsByUserId,
      );
    }

    if (postIds.isNotEmpty) {
      try {
        final mediaRows = await _client
            .from(_postMediaTable)
            .select(
              'post_id, media_type, public_url, storage_bucket, storage_path, order_no',
            )
            .inFilter('post_id', postIds)
            .order('order_no', ascending: true);

        final firstImageMediaByPostId = <String, Map<String, dynamic>>{};
        for (final row in mediaRows) {
          final map = Map<String, dynamic>.from(row);
          final postId = map['post_id']?.toString() ?? '';
          if (postId.isEmpty) {
            continue;
          }

          final mediaType = map['media_type']?.toString() ?? '';
          if (mediaType == _videoMediaType) {
            postsWithVideoMedia.add(postId);
            continue;
          }
          if (mediaType != _imageMediaType) {
            continue;
          }
          if (firstImageMediaByPostId.containsKey(postId)) {
            continue;
          }
          firstImageMediaByPostId[postId] = map;
        }

        await Future.wait(
          firstImageMediaByPostId.entries.map((entry) async {
            final resolvedImageUrl = await _resolveFeedImageUrl(entry.value);
            if (resolvedImageUrl != null && resolvedImageUrl.isNotEmpty) {
              imageUrlsByPostId[entry.key] = resolvedImageUrl;
            }
          }),
        );
      } catch (_) {
        // Keep posts visible even if post_media fetch fails.
      }

      for (final postId in postIds) {
        final liveCount = _liveLikeCountsByPostId[postId];
        if (liveCount != null) {
          likeCountsByPostId[postId] = liveCount;
        }
      }

      final shouldHydrateLikeCounts = rows.any(
            (row) => _toNullableInt(row['like_count']) == null,
          ) &&
          postIds.any((postId) => !likeCountsByPostId.containsKey(postId));
      if (shouldHydrateLikeCounts) {
        final targetPostIds = postIds
            .where((postId) => !likeCountsByPostId.containsKey(postId))
            .toList(growable: false);
        try {
          final likeRows = await _client
              .from(_postLikesTable)
              .select('post_id')
              .eq('reaction', _likeReaction)
              .inFilter('post_id', targetPostIds);

          for (final row in likeRows) {
            final map = Map<String, dynamic>.from(row);
            final postId = map['post_id']?.toString() ?? '';
            if (postId.isEmpty) {
              continue;
            }
            likeCountsByPostId[postId] = (likeCountsByPostId[postId] ?? 0) + 1;
          }
          _liveLikeCountsByPostId.addAll(likeCountsByPostId);
        } catch (_) {
          // Keep feed visible even if like counts fail to load.
        }
      }

      for (final postId in postIds) {
        final liveCount = _liveCommentCountsByPostId[postId];
        if (liveCount != null) {
          commentCountsByPostId[postId] = liveCount;
        }
      }

      final shouldHydrateCommentCounts = rows.any(
            (row) => _toNullableInt(row['comment_count']) == null,
          ) &&
          postIds.any((postId) => !commentCountsByPostId.containsKey(postId));
      if (shouldHydrateCommentCounts) {
        final targetPostIds = postIds
            .where((postId) => !commentCountsByPostId.containsKey(postId))
            .toList(growable: false);
        try {
          final commentRows = await _client
              .from(_postCommentsTable)
              .select('post_id')
              .inFilter('post_id', targetPostIds);

          for (final row in commentRows) {
            final map = Map<String, dynamic>.from(row);
            final postId = map['post_id']?.toString() ?? '';
            if (postId.isEmpty) {
              continue;
            }
            commentCountsByPostId[postId] =
                (commentCountsByPostId[postId] ?? 0) + 1;
          }
          _liveCommentCountsByPostId.addAll(commentCountsByPostId);
        } catch (_) {
          // Keep feed visible even if comment counts fail to load.
        }
      }
    }

    final posts = rows.where((row) {
      final postId = row['id']?.toString() ?? '';
      return postId.isNotEmpty && !postsWithVideoMedia.contains(postId);
    }).map((row) {
      final map = Map<String, dynamic>.from(row);
      final postId = map['id']?.toString() ?? '';
      final userId = map['user_id']?.toString() ?? '';
      final authorName = namesByUserId[userId];
      if (authorName != null && authorName.isNotEmpty) {
        map['author_name'] = authorName;
      }
      final authorAvatarUrl = avatarsByUserId[userId];
      if (authorAvatarUrl != null && authorAvatarUrl.isNotEmpty) {
        map['author_avatar_url'] = authorAvatarUrl;
      }
      final imageUrl = imageUrlsByPostId[postId];
      if (imageUrl != null && imageUrl.isNotEmpty) {
        map['image_url'] = imageUrl;
      }
      final hydratedLikeCount = likeCountsByPostId[postId];
      if (hydratedLikeCount != null) {
        map['like_count'] = hydratedLikeCount;
      }
      final hydratedCommentCount = commentCountsByPostId[postId];
      if (hydratedCommentCount != null) {
        map['comment_count'] = hydratedCommentCount;
      }
      return FeedPost.fromMap(map);
    }).toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<List<FeedComment>> _mapComments(
      List<Map<String, dynamic>> rows) async {
    final authorIds = rows
        .map((row) => row['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final namesByUserId = <String, String>{};
    final avatarsByUserId = <String, String>{};

    if (authorIds.isNotEmpty) {
      await _loadProfiles(
        userIds: authorIds,
        namesByUserId: namesByUserId,
        avatarsByUserId: avatarsByUserId,
      );
    }

    final comments = rows.map((row) {
      final map = Map<String, dynamic>.from(row);
      final userId = map['user_id']?.toString() ?? '';
      map['author_name'] = namesByUserId[userId];
      map['author_avatar_url'] = avatarsByUserId[userId];
      return FeedComment.fromMap(map);
    }).toList();

    comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return comments;
  }

  Future<void> _loadProfiles({
    required List<String> userIds,
    required Map<String, String> namesByUserId,
    required Map<String, String> avatarsByUserId,
  }) async {
    if (userIds.isEmpty) {
      return;
    }

    final missingUserIds = <String>[];
    for (final userId in userIds) {
      final cachedName = _cachedNamesByUserId[userId];
      final cachedAvatar = _cachedAvatarsByUserId[userId];
      if (cachedName != null || cachedAvatar != null) {
        if (cachedName != null && cachedName.isNotEmpty) {
          namesByUserId[userId] = cachedName;
        }
        if (cachedAvatar != null && cachedAvatar.isNotEmpty) {
          avatarsByUserId[userId] = cachedAvatar;
        }
        continue;
      }
      missingUserIds.add(userId);
    }

    if (missingUserIds.isEmpty) {
      return;
    }

    try {
      final profiles = await _client
          .from(_profilesTable)
          .select('id, username, avatarurl')
          .inFilter('id', missingUserIds);

      final fetchedUserIds = <String>{};
      for (final row in profiles) {
        final map = Map<String, dynamic>.from(row);
        final id = map['id']?.toString() ?? '';
        if (id.isEmpty) {
          continue;
        }
        fetchedUserIds.add(id);

        final username = map['username']?.toString().trim() ?? '';
        final avatar = ProfileAvatarCatalog.normalize(
          map['avatarurl']?.toString(),
        );

        _cachedNamesByUserId[id] = username;
        _cachedAvatarsByUserId[id] = avatar;

        if (username.isNotEmpty) {
          namesByUserId[id] = username;
        }
        if (avatar.isNotEmpty) {
          avatarsByUserId[id] = avatar;
        }
      }

      for (final userId in missingUserIds) {
        if (!fetchedUserIds.contains(userId)) {
          _cachedNamesByUserId[userId] = '';
          _cachedAvatarsByUserId[userId] = ProfileAvatarCatalog.defaultAvatar;
          avatarsByUserId[userId] = ProfileAvatarCatalog.defaultAvatar;
        }
      }

      _trimProfileCachesIfNeeded();
    } catch (_) {
      // Keep fallback display names from auth metadata/default text.
    }
  }

  void _trimProfileCachesIfNeeded() {
    if (_cachedNamesByUserId.length > _maxProfileCacheEntries) {
      _cachedNamesByUserId.clear();
    }
    if (_cachedAvatarsByUserId.length > _maxProfileCacheEntries) {
      _cachedAvatarsByUserId.clear();
    }
  }

  int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  Set<String> _extractPostIdsFromRows(List<Map<String, dynamic>> rows) {
    return rows
        .map((row) => row['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  bool _hasSamePostIds(Set<String> left, Set<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final id in left) {
      if (!right.contains(id)) {
        return false;
      }
    }
    return true;
  }

  void _syncLiveLikeCounts(
    List<Map<String, dynamic>> rows,
    Set<String> trackedPostIds,
  ) {
    _liveLikeCountsByPostId.removeWhere(
      (postId, _) => !trackedPostIds.contains(postId),
    );

    final counts = <String, int>{};
    for (final postId in trackedPostIds) {
      counts[postId] = 0;
    }

    for (final row in rows) {
      final postId = row['post_id']?.toString() ?? '';
      if (postId.isEmpty || !trackedPostIds.contains(postId)) {
        continue;
      }

      if (row['reaction']?.toString() != _likeReaction) {
        continue;
      }

      counts[postId] = (counts[postId] ?? 0) + 1;
    }

    _liveLikeCountsByPostId.addAll(counts);
  }

  void _syncLiveCommentCounts(
    List<Map<String, dynamic>> rows,
    Set<String> trackedPostIds,
  ) {
    _liveCommentCountsByPostId.removeWhere(
      (postId, _) => !trackedPostIds.contains(postId),
    );

    final counts = <String, int>{};
    for (final postId in trackedPostIds) {
      counts[postId] = 0;
    }

    for (final row in rows) {
      final postId = row['post_id']?.toString() ?? '';
      if (postId.isEmpty || !trackedPostIds.contains(postId)) {
        continue;
      }

      counts[postId] = (counts[postId] ?? 0) + 1;
    }

    _liveCommentCountsByPostId.addAll(counts);
  }

  Future<String?> _resolveFeedImageUrl(Map<String, dynamic> row) async {
    final storagePath = row['storage_path']?.toString().trim() ?? '';
    final publicUrl = row['public_url']?.toString().trim();

    if (storagePath.isEmpty) {
      if (publicUrl == null || publicUrl.isEmpty) {
        return null;
      }
      return publicUrl;
    }

    final storageBucket = _normalizeBucketName(
      row['storage_bucket']?.toString() ?? _feedImageBucket,
    );
    final cacheKey = '$storageBucket/$storagePath';
    final now = DateTime.now();
    final cachedUrl = _cachedMediaUrls[cacheKey];
    if (cachedUrl != null && cachedUrl.expiresAt.isAfter(now)) {
      return cachedUrl.url;
    }

    final inFlight = _inFlightMediaUrlResolvers[cacheKey];
    if (inFlight != null) {
      return inFlight;
    }

    Future<String?> resolve() async {
      try {
        final signedUrl = await _client.storage
            .from(storageBucket)
            .createSignedUrl(storagePath, 60 * 60);
        if (signedUrl.isNotEmpty) {
          _cachedMediaUrls[cacheKey] = _CachedSignedUrl(
            url: signedUrl,
            expiresAt: now.add(_signedUrlTtl),
          );
          _trimMediaUrlCacheIfNeeded();
          return signedUrl;
        }
      } catch (_) {
        // Continue with public URL fallback below.
      }

      if (publicUrl != null && publicUrl.isNotEmpty) {
        return publicUrl;
      }

      try {
        final fallbackUrl =
            _client.storage.from(storageBucket).getPublicUrl(storagePath);
        if (fallbackUrl.isNotEmpty) {
          return fallbackUrl;
        }
      } catch (_) {
        return null;
      }
      return null;
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

  // FIX: แก้ _loadPostRows ให้ใช้ RPC สำหรับ feed หลัก
  // และ filter approved เท่านั้นสำหรับ profile ของคนอื่น
  Future<List<Map<String, dynamic>>> _loadPostRows({String? authorId}) async {
    // Profile page: query ตรงแต่ filter เฉพาะโพสต์ที่ approved
    if (authorId != null && authorId.isNotEmpty) {
      final currentUserId = _client.auth.currentUser?.id ?? '';
      final isOwnProfile = currentUserId == authorId;

      if (isOwnProfile) {
        // โปรไฟล์ตัวเอง: เห็นทุกสถานะ (draft, active, hidden)
        final rows = await _client
            .from(_postsTable)
            .select('*')
            .eq('user_id', authorId)
            .inFilter('status', ['draft', 'active', 'hidden']).order(
                'created_at',
                ascending: false);
        return rows
            .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
            .toList();
      } else {
        // โปรไฟล์คนอื่น: เห็นเฉพาะ approved + visible
        final rows = await _client
            .from(_postsTable)
            .select('*')
            .eq('user_id', authorId)
            .eq('status', 'active')
            .eq('moderation_status', 'approved')
            .eq('is_visible', true)
            .order('created_at', ascending: false);
        return rows
            .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
            .toList();
      }
    }

    // Feed หลัก: ใช้ RPC get_posts_feed_fast
    // ซึ่ง include โพสต์ approved ของทุกคน + โพสต์ทุกสถานะของตัวเอง
    try {
      final response = await _client.rpc(
        'get_posts_feed_fast',
        params: {'p_limit': 60, 'p_offset': 0},
      );

      if (response is! List) return const [];

      return response
          .whereType<Map>()
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (_) {
      // Fallback: query ตรงถ้า RPC ล้มเหลว (filter approved เท่านั้น)
      final rows = await _client
          .from(_postsTable)
          .select('*')
          .eq('status', 'active')
          .eq('moderation_status', 'approved')
          .eq('is_visible', true)
          .order('created_at', ascending: false)
          .limit(60);
      return rows
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList();
    }
  }

  Stream<List<FeedPost>> _watchMappedPosts({String? authorId}) {
    late final StreamController<List<FeedPost>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? postsSubscription;
    StreamSubscription<void>? allPostsRefreshSubscription;
    StreamSubscription<String>? authorPostsRefreshSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? mediaSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? likesSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? commentsSubscription;
    Timer? queryRefreshDebounceTimer;
    Timer? remapDebounceTimer;
    var hasActiveListener = false;
    var isEmittingPosts = false;
    var hasPendingEmit = false;
    Set<String> trackedPostIds = <String>{};

    List<Map<String, dynamic>> latestPostRows = const [];
    var hasLoadedPosts = false;

    Future<void> emitMappedPosts() async {
      if (!hasLoadedPosts || !hasActiveListener || controller.isClosed) {
        return;
      }

      if (isEmittingPosts) {
        hasPendingEmit = true;
        return;
      }

      isEmittingPosts = true;
      try {
        controller.add(await _mapPosts(latestPostRows));
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      } finally {
        isEmittingPosts = false;
        if (hasPendingEmit && hasActiveListener && !controller.isClosed) {
          hasPendingEmit = false;
          unawaited(emitMappedPosts());
        }
      }
    }

    void scheduleEmitMappedPosts({
      Duration delay = const Duration(milliseconds: 220),
    }) {
      if (!hasLoadedPosts || !hasActiveListener) {
        return;
      }
      remapDebounceTimer?.cancel();
      remapDebounceTimer = Timer(delay, () => unawaited(emitMappedPosts()));
    }

    Future<void> resubscribeAggregateStreams() async {
      final nextTrackedPostIds = _extractPostIdsFromRows(latestPostRows);
      if (_hasSamePostIds(nextTrackedPostIds, trackedPostIds)) {
        return;
      }

      trackedPostIds = nextTrackedPostIds;
      _liveLikeCountsByPostId.removeWhere(
        (postId, _) => !trackedPostIds.contains(postId),
      );
      _liveCommentCountsByPostId.removeWhere(
        (postId, _) => !trackedPostIds.contains(postId),
      );

      await mediaSubscription?.cancel();
      await likesSubscription?.cancel();
      await commentsSubscription?.cancel();
      mediaSubscription = null;
      likesSubscription = null;
      commentsSubscription = null;

      if (!hasActiveListener || controller.isClosed || trackedPostIds.isEmpty) {
        return;
      }

      final postIds = trackedPostIds.toList(growable: false);

      mediaSubscription = _client
          .from(_postMediaTable)
          .stream(primaryKey: const ['post_id', 'storage_path'])
          .inFilter('post_id', postIds)
          .listen(
            (_) => scheduleEmitMappedPosts(),
            onError: (_, __) {},
          );

      likesSubscription = _client
          .from(_postLikesTable)
          .stream(primaryKey: const ['post_id', 'user_id'])
          .inFilter('post_id', postIds)
          .listen(
            (rows) {
              _syncLiveLikeCounts(rows, trackedPostIds);
              scheduleEmitMappedPosts();
            },
            onError: (_, __) {},
          );

      commentsSubscription = _client
          .from(_postCommentsTable)
          .stream(primaryKey: const ['id'])
          .inFilter('post_id', postIds)
          .listen(
            (rows) {
              _syncLiveCommentCounts(rows, trackedPostIds);
              scheduleEmitMappedPosts();
            },
            onError: (_, __) {},
          );
    }

    Future<void> refreshPostsFromQuery({bool reportErrors = false}) async {
      try {
        final rows = await _loadPostRows(authorId: authorId);
        if (controller.isClosed) {
          return;
        }
        latestPostRows = rows;
        hasLoadedPosts = true;
        await resubscribeAggregateStreams();
        await emitMappedPosts();
      } catch (error, stackTrace) {
        if (reportErrors && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    void scheduleRefreshPostsFromQuery({
      Duration delay = const Duration(milliseconds: 260),
    }) {
      if (!hasActiveListener) {
        return;
      }
      queryRefreshDebounceTimer?.cancel();
      queryRefreshDebounceTimer = Timer(
        delay,
        () => unawaited(refreshPostsFromQuery()),
      );
    }

    controller = StreamController<List<FeedPost>>(
      onListen: () {
        hasActiveListener = true;

        void onPosts(List<Map<String, dynamic>> rows) {
          // FIX: realtime stream อาจดึงมาโดยไม่ filter -> ให้ refresh จาก
          // _loadPostRows แทนการใช้ rows จาก stream โดยตรง
          // เพื่อให้ได้ข้อมูลที่ถูก filter แล้วเสมอ
          scheduleRefreshPostsFromQuery();
        }

        unawaited(refreshPostsFromQuery(reportErrors: true));

        if (authorId != null && authorId.isNotEmpty) {
          authorPostsRefreshSubscription = _authorPostsRefreshController.stream
              .where((targetAuthorId) => targetAuthorId == authorId)
              .listen((_) {
            unawaited(refreshPostsFromQuery(reportErrors: true));
          });
          postsSubscription = _client
              .from(_postsTable)
              .stream(primaryKey: const ['id'])
              .eq('user_id', authorId)
              .order('created_at', ascending: false)
              .listen(
                onPosts,
                onError: (_, __) => scheduleRefreshPostsFromQuery(),
              );
        } else {
          allPostsRefreshSubscription =
              _allPostsRefreshController.stream.listen((_) {
            unawaited(refreshPostsFromQuery(reportErrors: true));
          });
          postsSubscription = _client
              .from(_postsTable)
              .stream(primaryKey: const ['id'])
              .order('created_at', ascending: false)
              .listen(
                onPosts,
                onError: (_, __) => scheduleRefreshPostsFromQuery(),
              );
        }
      },
      onCancel: () async {
        hasActiveListener = false;
        queryRefreshDebounceTimer?.cancel();
        remapDebounceTimer?.cancel();
        await allPostsRefreshSubscription?.cancel();
        await authorPostsRefreshSubscription?.cancel();
        await postsSubscription?.cancel();
        await mediaSubscription?.cancel();
        await likesSubscription?.cancel();
        await commentsSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('กรุณาเข้าสู่ระบบอีกครั้ง');
    }
    return user;
  }

  String _readNameFromAuth(User user) {
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final candidates = [
      metadata['username'],
      metadata['name'],
      metadata['full_name'],
      user.email?.split('@').first,
    ];

    for (final value in candidates) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    return 'ผู้ใช้';
  }

  Future<String> _uploadPostImage({
    required String postId,
    required String userId,
    required Uint8List imageBytes,
    String? imageFileName,
  }) async {
    final extension = _resolveImageExtension(imageFileName);
    final fileName = _resolveStorageFileName(imageFileName, extension);
    final storagePath = 'posts/$userId/$postId/$fileName';

    try {
      await _client.storage.from(_feedImageBucket).uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: _contentTypeForExtension(extension),
            ),
          );
    } on StorageException catch (error) {
      if (_looksLikeMissingBucket(error)) {
        throw FeedImageBucketNotFoundException(_feedImageBucket);
      }
      rethrow;
    }

    return storagePath;
  }

  // FIX: เพิ่ม hasMedia parameter เพื่อ set status ให้ถูกต้องตั้งแต่ต้น
  Future<String> _insertPost({
    required String userId,
    required String content,
    bool hasMedia = false,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final insertedRow = await _client
        .from(_postsTable)
        .insert({
          'user_id': userId,
          'content_text': content,
          // text-only -> approved ทันที ไม่ต้องรอ moderation
          // มี media -> pending รอ n8n/moderation approve ก่อน
          'status': 'active',
          'moderation_status': hasMedia ? 'pending' : 'approved',
          'is_visible': !hasMedia,
          if (!hasMedia) 'moderated_at': now,
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

  Future<void> _insertPostMedia({
    required String postId,
    required String storagePath,
    required String publicUrl,
    required int fileSizeBytes,
  }) async {
    await _client.from(_postMediaTable).insert({
      'post_id': postId,
      'media_type': _imageMediaType,
      'storage_bucket': _feedImageBucket,
      'storage_path': storagePath,
      'public_url': publicUrl,
      'thumbnail_url': null,
      'width': null,
      'height': null,
      'duration_sec': null,
      'file_size_bytes': fileSizeBytes,
      'order_no': 0,
    });
  }

  Future<void> _deleteStorageObject(String storagePath) async {
    try {
      await _client.storage.from(_feedImageBucket).remove([storagePath]);
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

  String _extractSavedPostId(Map<String, dynamic> row) {
    final candidates = <dynamic>[
      row['id'],
      row['post_id'],
      row['saved_post_id'],
      row['user_saved_posts'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) {
        for (final item in candidate) {
          final postId = item?.toString().trim() ?? '';
          if (postId.isNotEmpty) {
            return postId;
          }
        }
        continue;
      }
      final postId = candidate?.toString().trim() ?? '';
      if (postId.isNotEmpty) {
        return postId;
      }
    }

    return '';
  }

  bool _isRpcPostNotFound(PostgrestException error) {
    final code = (error.code ?? '').trim();
    final message = error.message.toLowerCase();
    return code == 'P0001' && message.contains('post not found');
  }

  Future<bool> _savePostByDirectInsertFallback({
    required String userId,
    required String postId,
  }) async {
    for (final table in _savedPostsTableCandidates) {
      for (final postIdColumn in _savedPostIdColumnCandidates) {
        try {
          await _client.from(table).upsert(
            {
              'user_id': userId,
              postIdColumn: postId,
            },
            onConflict: 'user_id,$postIdColumn',
          );
          return true;
        } catch (_) {
          continue;
        }
      }
    }
    return false;
  }

  Future<bool> _unsavePostByDirectDeleteFallback({
    required String userId,
    required String postId,
  }) async {
    for (final table in _savedPostsTableCandidates) {
      for (final postIdColumn in _savedPostIdColumnCandidates) {
        try {
          await _client
              .from(table)
              .delete()
              .eq('user_id', userId)
              .eq(postIdColumn, postId);
          return true;
        } catch (_) {
          continue;
        }
      }
    }
    return false;
  }

  String _resolveImageExtension(String? imageFileName) {
    final fileName = imageFileName?.trim() ?? '';
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return 'jpg';
    }

    final extension = fileName.substring(dotIndex + 1).toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
        return extension == 'jpeg' ? 'jpg' : extension;
      default:
        return 'jpg';
    }
  }

  String _resolveStorageFileName(String? imageFileName, String extension) {
    final original = imageFileName?.trim() ?? '';
    final dotIndex = original.lastIndexOf('.');
    final baseName = dotIndex > 0 ? original.substring(0, dotIndex) : original;
    final sanitizedBaseName = baseName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final normalizedBaseName =
        sanitizedBaseName.isEmpty ? 'image' : sanitizedBaseName;
    return '$normalizedBaseName.$extension';
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  bool _looksLikeMissingBucket(StorageException error) {
    final message = error.toString().toLowerCase();
    return message.contains('bucket not found') ||
        message.contains('statuscode: 404') ||
        message.contains('status code: 404');
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
}

class _CachedSignedUrl {
  const _CachedSignedUrl({
    required this.url,
    required this.expiresAt,
  });

  final String url;
  final DateTime expiresAt;
}

class FeedImageBucketNotFoundException implements Exception {
  const FeedImageBucketNotFoundException(this.bucketName);

  final String bucketName;

  @override
  String toString() =>
      'FeedImageBucketNotFoundException(bucketName: $bucketName)';
}

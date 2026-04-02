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
  static const _feedImageBucketConfig = String.fromEnvironment(
    'SUPABASE_FEED_IMAGE_BUCKET',
    defaultValue: 'app_media',
  );
  static const _imageMediaType = 'image';
  static const _videoMediaType = 'video';
  static const _likeReaction = 'like';

  final SupabaseClient _client;
  late final FeedDeleteService _deleteService = FeedDeleteService(
    client: _client,
  );
  final ContentModerationService _moderationService =
      ContentModerationService.instance;

  String get _feedImageBucket => _normalizeBucketName(_feedImageBucketConfig);

  bool get supportsLikeActions => true;

  Stream<List<FeedPost>> watchPosts() {
    return _watchMappedPosts();
  }

  Stream<List<FeedPost>> watchPostsByAuthor(String authorId) {
    return _watchMappedPosts(authorId: authorId);
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

  Stream<List<FeedComment>> watchCommentsByPost(String postId) {
    if (postId.trim().isEmpty) {
      return Stream<List<FeedComment>>.value(const <FeedComment>[]);
    }

    late final StreamController<List<FeedComment>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? commentsSubscription;

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
                unawaited(emitMappedComments());
              },
              onError: controller.addError,
            );
      },
      onCancel: () async {
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
      final postId = await _insertPost(
        userId: identity.userId,
        content: safeText,
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
      try {
        final profiles = await _client
            .from(_profilesTable)
            .select('id, username, avatarurl')
            .inFilter('id', authorIds);

        for (final row in profiles) {
          final map = Map<String, dynamic>.from(row);
          final id = map['id']?.toString() ?? '';
          final username = map['username']?.toString().trim() ?? '';
          if (id.isNotEmpty && username.isNotEmpty) {
            namesByUserId[id] = username;
          }
          if (id.isNotEmpty) {
            avatarsByUserId[id] = ProfileAvatarCatalog.normalize(
              map['avatarurl']?.toString(),
            );
          }
        }
      } catch (_) {
        // Keep fallback display names from auth metadata/default text.
      }
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

        for (final row in mediaRows) {
          final map = Map<String, dynamic>.from(row);
          final postId = map['post_id']?.toString() ?? '';
          if (postId.isEmpty || imageUrlsByPostId.containsKey(postId)) {
            if (postId.isNotEmpty &&
                map['media_type']?.toString() == _videoMediaType) {
              postsWithVideoMedia.add(postId);
            }
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

          final resolvedImageUrl = await _resolveFeedImageUrl(map);
          if (resolvedImageUrl != null && resolvedImageUrl.isNotEmpty) {
            imageUrlsByPostId[postId] = resolvedImageUrl;
          }
        }
      } catch (_) {
        // Keep posts visible even if post_media fetch fails.
      }

      try {
        final likeRows = await _client
            .from(_postLikesTable)
            .select('post_id')
            .eq('reaction', _likeReaction)
            .inFilter('post_id', postIds);

        for (final row in likeRows) {
          final map = Map<String, dynamic>.from(row);
          final postId = map['post_id']?.toString() ?? '';
          if (postId.isEmpty) {
            continue;
          }
          likeCountsByPostId[postId] = (likeCountsByPostId[postId] ?? 0) + 1;
        }
      } catch (_) {
        // Keep feed visible even if like counts fail to load.
      }

      try {
        final commentRows = await _client
            .from(_postCommentsTable)
            .select('post_id')
            .inFilter('post_id', postIds);

        for (final row in commentRows) {
          final map = Map<String, dynamic>.from(row);
          final postId = map['post_id']?.toString() ?? '';
          if (postId.isEmpty) {
            continue;
          }
          commentCountsByPostId[postId] =
              (commentCountsByPostId[postId] ?? 0) + 1;
        }
      } catch (_) {
        // Keep feed visible even if comment counts fail to load.
      }
    }

    final posts = rows.where((row) {
      final postId = row['id']?.toString() ?? '';
      return postId.isNotEmpty && !postsWithVideoMedia.contains(postId);
    }).map((row) {
      final map = Map<String, dynamic>.from(row);
      final postId = map['id']?.toString() ?? '';
      final userId = map['user_id']?.toString() ?? '';
      map['author_name'] = namesByUserId[userId];
      map['author_avatar_url'] = avatarsByUserId[userId];
      map['image_url'] = imageUrlsByPostId[postId];
      map['like_count'] = likeCountsByPostId[postId] ?? map['like_count'];
      map['comment_count'] =
          commentCountsByPostId[postId] ?? map['comment_count'];
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
      try {
        final profiles = await _client
            .from(_profilesTable)
            .select('id, username, avatarurl')
            .inFilter('id', authorIds);

        for (final row in profiles) {
          final map = Map<String, dynamic>.from(row);
          final id = map['id']?.toString() ?? '';
          final username = map['username']?.toString().trim() ?? '';
          if (id.isNotEmpty && username.isNotEmpty) {
            namesByUserId[id] = username;
          }
          if (id.isNotEmpty) {
            avatarsByUserId[id] = ProfileAvatarCatalog.normalize(
              map['avatarurl']?.toString(),
            );
          }
        }
      } catch (_) {
        // Keep fallback display names when profiles cannot be loaded.
      }
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

    try {
      return await _client.storage
          .from(storageBucket)
          .createSignedUrl(storagePath, 60 * 60);
    } catch (_) {
      if (publicUrl != null && publicUrl.isNotEmpty) {
        return publicUrl;
      }

      try {
        return _client.storage.from(storageBucket).getPublicUrl(storagePath);
      } catch (_) {
        return null;
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadPostRows({String? authorId}) async {
    var query = _client.from(_postsTable).select('*');
    if (authorId != null && authorId.isNotEmpty) {
      query = query.eq('user_id', authorId);
    }

    final rows = await query.order('created_at', ascending: false);
    return rows
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Stream<List<FeedPost>> _watchMappedPosts({String? authorId}) {
    late final StreamController<List<FeedPost>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? postsSubscription;

    List<Map<String, dynamic>> latestPostRows = const [];
    var hasLoadedPosts = false;

    Future<void> emitMappedPosts() async {
      if (!hasLoadedPosts) {
        return;
      }

      try {
        controller.add(await _mapPosts(latestPostRows));
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
    }

    Future<void> refreshPostsFromQuery({bool reportErrors = false}) async {
      try {
        final rows = await _loadPostRows(authorId: authorId);
        if (controller.isClosed) {
          return;
        }
        latestPostRows = rows;
        hasLoadedPosts = true;
        await emitMappedPosts();
      } catch (error, stackTrace) {
        if (reportErrors && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<List<FeedPost>>(
      onListen: () {
        void onPosts(List<Map<String, dynamic>> rows) {
          latestPostRows = rows
              .map<Map<String, dynamic>>(
                (row) => Map<String, dynamic>.from(row),
              )
              .toList();
          hasLoadedPosts = true;
          unawaited(emitMappedPosts());
        }

        unawaited(refreshPostsFromQuery(reportErrors: true));

        if (authorId != null && authorId.isNotEmpty) {
          postsSubscription = _client
              .from(_postsTable)
              .stream(primaryKey: const ['id'])
              .eq('user_id', authorId)
              .order('created_at', ascending: false)
              .listen(
                onPosts,
                onError: (_, __) => unawaited(refreshPostsFromQuery()),
              );
        } else {
          postsSubscription = _client
              .from(_postsTable)
              .stream(primaryKey: const ['id'])
              .order('created_at', ascending: false)
              .listen(
                onPosts,
                onError: (_, __) => unawaited(refreshPostsFromQuery()),
              );
        }

      },
      onCancel: () async {
        await postsSubscription?.cancel();
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

class FeedImageBucketNotFoundException implements Exception {
  const FeedImageBucketNotFoundException(this.bucketName);

  final String bucketName;

  @override
  String toString() =>
      'FeedImageBucketNotFoundException(bucketName: $bucketName)';
}

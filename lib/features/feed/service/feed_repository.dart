import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_application_1/core/services/content_moderation_service.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:flutter_application_1/features/feed/model/feed_post.dart';
import 'package:flutter_application_1/features/profile/model/profile_avatar_catalog.dart';
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
  static const _profilesTable = 'profiles';
  static const _feedImageBucketConfig = String.fromEnvironment(
    'SUPABASE_FEED_IMAGE_BUCKET',
    defaultValue: 'app_media',
  );
  static const _imageMediaType = 'image';
  static const _videoMediaType = 'video';
  static const _likeReaction = 'like';

  final SupabaseClient _client;
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
  }

  Future<void> unlikePost(String postId) async {
    final user = _requireUser();
    await _client
        .from(_postLikesTable)
        .delete()
        .eq('post_id', postId)
        .eq('reaction', _likeReaction)
        .eq('user_id', user.id);
  }

  Future<void> deletePost(String postId) async {
    final user = _requireUser();
    Map<String, dynamic>? ownedPost;
    List<Map<String, dynamic>> postMediaRows = const [];

    try {
      ownedPost = await _client
          .from(_postsTable)
          .select('id')
          .eq('id', postId)
          .eq('user_id', user.id)
          .maybeSingle();
    } catch (_) {
      ownedPost = null;
    }

    if (ownedPost == null) {
      return;
    }

    try {
      final mediaRows = await _client
          .from(_postMediaTable)
          .select('storage_bucket, storage_path')
          .eq('post_id', postId);
      postMediaRows = mediaRows
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (_) {
      postMediaRows = const [];
    }

    await _client
        .from(_postsTable)
        .delete()
        .eq('id', postId)
        .eq('user_id', user.id);

    final removablePaths = postMediaRows
        .where(
          (row) =>
              _normalizeBucketName(row['storage_bucket']?.toString() ?? '') ==
              _feedImageBucket,
        )
        .map((row) => row['storage_path']?.toString().trim() ?? '')
        .where((path) => path.isNotEmpty)
        .toList();
    if (removablePaths.isNotEmpty) {
      await _deleteStorageObjects(removablePaths);
    }
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

          final publicUrl = map['public_url']?.toString().trim();
          if (publicUrl != null && publicUrl.isNotEmpty) {
            imageUrlsByPostId[postId] = publicUrl;
            continue;
          }

          final storagePath = map['storage_path']?.toString().trim() ?? '';
          final storageBucket = _normalizeBucketName(
            map['storage_bucket']?.toString() ?? _feedImageBucket,
          );
          if (storagePath.isNotEmpty) {
            imageUrlsByPostId[postId] =
                _client.storage.from(storageBucket).getPublicUrl(storagePath);
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
      return FeedPost.fromMap(map);
    }).toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Stream<List<FeedPost>> _watchMappedPosts({String? authorId}) {
    late final StreamController<List<FeedPost>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? postsSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? mediaSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? likesSubscription;

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

        if (authorId != null && authorId.isNotEmpty) {
          postsSubscription = _client
              .from(_postsTable)
              .stream(primaryKey: const ['id'])
              .eq('user_id', authorId)
              .order('created_at', ascending: false)
              .listen(
                onPosts,
                onError: controller.addError,
              );
        } else {
          postsSubscription = _client
              .from(_postsTable)
              .stream(primaryKey: const ['id'])
              .order('created_at', ascending: false)
              .listen(
                onPosts,
                onError: controller.addError,
              );
        }

        mediaSubscription = _client
            .from(_postMediaTable)
            .stream(primaryKey: const ['post_id', 'storage_path']).listen(
          (_) => unawaited(emitMappedPosts()),
          onError: (_, __) {},
        );

        likesSubscription = _client
            .from(_postLikesTable)
            .stream(primaryKey: const ['post_id', 'user_id']).listen(
          (_) => unawaited(emitMappedPosts()),
          onError: (_, __) {},
        );
      },
      onCancel: () async {
        await postsSubscription?.cancel();
        await mediaSubscription?.cancel();
        await likesSubscription?.cancel();
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

  Future<void> _deleteStorageObjects(List<String> storagePaths) async {
    try {
      await _client.storage.from(_feedImageBucket).remove(storagePaths);
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

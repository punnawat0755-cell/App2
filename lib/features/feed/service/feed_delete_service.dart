import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedDeleteService {
  FeedDeleteService({SupabaseClient? client}) : _client = client ?? supabase;

  static const _postsTable = 'posts';
  static const _postMediaTable = 'post_media';

  final SupabaseClient _client;

  Future<void> deletePostWithMedia({
    required String postId,
  }) async {
    final normalizedPostId = postId.trim();
    if (normalizedPostId.isEmpty) {
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('กรุณาเข้าสู่ระบบอีกครั้ง');
    }

    final detail = await _loadPostDetailWithMedia(
      postId: normalizedPostId,
      userId: user.id,
    );
    if (detail == null) {
      throw const FeedPostUnavailableException();
    }

    final media = detail.media;
    final deletedRows = await _client
        .from(_postsTable)
        .delete()
        .eq('id', normalizedPostId)
        .eq('user_id', user.id)
        .select('id');
    if ((deletedRows as List<dynamic>).isEmpty) {
      throw const FeedPostUnavailableException();
    }

    if (media.isNotEmpty) {
      final storagePathsByBucket = <String, List<String>>{};
      for (final item in media) {
        final storagePath = item.storagePath.trim();
        final bucket = item.storageBucket.trim();
        if (storagePath.isEmpty || bucket.isEmpty) {
          continue;
        }

        storagePathsByBucket.putIfAbsent(bucket, () => <String>[]).add(
              storagePath,
            );
      }

      for (final entry in storagePathsByBucket.entries) {
        try {
          await _client.storage.from(entry.key).remove(entry.value);
        } catch (_) {
          // Continue deleting the post row even if storage cleanup partially fails.
        }
      }
    }
  }

  Future<_PostDeleteDetail?> _loadPostDetailWithMedia({
    required String postId,
    required String userId,
  }) async {
    try {
      final detail = await _client.rpc(
        'get_post_detail_with_media',
        params: {'p_post_id': postId},
      );
      final rows = (detail as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      if (rows.isEmpty) {
        return null;
      }

      final post = rows.first;
      final ownerId = post['user_id']?.toString().trim() ?? '';
      if (ownerId.isNotEmpty && ownerId != userId) {
        return null;
      }

      final media = (post['media'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => _PostMediaRef.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      return _PostDeleteDetail(
        postId: post['id']?.toString().trim() ?? postId,
        media: media,
      );
    } catch (_) {
      return _loadPostDetailDirectly(
        postId: postId,
        userId: userId,
      );
    }
  }

  Future<_PostDeleteDetail?> _loadPostDetailDirectly({
    required String postId,
    required String userId,
  }) async {
    final ownedPost = await _client
        .from(_postsTable)
        .select('id, user_id')
        .eq('id', postId)
        .eq('user_id', userId)
        .maybeSingle();
    if (ownedPost == null) {
      return null;
    }

    final mediaRows = await _client
        .from(_postMediaTable)
        .select('storage_bucket, storage_path')
        .eq('post_id', postId);

    final media = mediaRows
        .map(
          (row) => _PostMediaRef.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();

    return _PostDeleteDetail(
      postId: ownedPost['id']?.toString().trim() ?? postId,
      media: media,
    );
  }
}

class FeedPostUnavailableException implements Exception {
  const FeedPostUnavailableException();

  @override
  String toString() => 'FeedPostUnavailableException()';
}

class _PostDeleteDetail {
  const _PostDeleteDetail({
    required this.postId,
    required this.media,
  });

  final String postId;
  final List<_PostMediaRef> media;
}

class _PostMediaRef {
  const _PostMediaRef({
    required this.storageBucket,
    required this.storagePath,
  });

  final String storageBucket;
  final String storagePath;

  factory _PostMediaRef.fromMap(Map<String, dynamic> map) {
    return _PostMediaRef(
      storageBucket: map['storage_bucket']?.toString().trim() ?? '',
      storagePath: map['storage_path']?.toString().trim() ?? '',
    );
  }
}

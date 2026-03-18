import 'dart:async';

import 'package:flutter_application_1/core/services/content_moderation_service.dart';
import 'package:flutter_application_1/features/feed/model/feed_comment.dart';
import 'package:flutter_application_1/features/feed/model/feed_post.dart';
import 'package:flutter_application_1/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedComposerIdentity {
  const FeedComposerIdentity({
    required this.userId,
    required this.authorName,
  });

  final String userId;
  final String authorName;
}

class FeedRepository {
  FeedRepository({SupabaseClient? client}) : _client = client ?? supabase;

  static const _postsTable = 'posts';
  static const _profilesTable = 'profiles';
  static const _postStatsTable = 'post_stats';
  static const _postReactionsTable = 'post_reactions';
  static const _postCommentsTable = 'post_comments';

  static const List<String> _profileNameSelectCandidates = <String>[
    'id, username',
    'id, display_name',
    'id, displayName',
    'id, displayname',
  ];

  final SupabaseClient _client;
  final ContentModerationService _moderationService =
      ContentModerationService.instance;

  bool get supportsLikeActions => true;

  Stream<List<FeedPost>> watchPosts() {
    return _watchMappedPosts(
      _client
          .from(_postsTable)
          .stream(primaryKey: const ['id'])
          .eq('status', 'active')
          .order('created_at', ascending: false),
    );
  }

  Stream<List<FeedPost>> watchPostsByAuthor(String authorId) {
    return _watchMappedPosts(
      _client
          .from(_postsTable)
          .stream(primaryKey: const ['id'])
          .eq('user_id', authorId)
          .order('created_at', ascending: false),
    );
  }

  Stream<Set<String>> watchLikedPostIds(String userId) {
    if (userId.trim().isEmpty) {
      return Stream<Set<String>>.value(const <String>{});
    }

    return _client
        .from(_postReactionsTable)
        .stream(primaryKey: const ['id'])
        .eq('user_id', userId)
        .map(
          (rows) => rows
              .where((row) => row['reaction']?.toString() == 'like')
              .map((row) => row['post_id']?.toString() ?? '')
              .where((postId) => postId.isNotEmpty)
              .toSet(),
        );
  }

  Stream<List<FeedComment>> watchComments(String postId) {
    return _client
        .from(_postCommentsTable)
        .stream(primaryKey: const ['id'])
        .eq('post_id', postId)
        .order('created_at')
        .asyncMap(_mapComments);
  }

  Future<FeedComposerIdentity> getComposerIdentity() async {
    final user = _requireUser();
    var authorName = _readNameFromAuth(user);

    try {
      final namesByUserId = await _loadProfileNames(<String>[user.id]);
      final profileName = namesByUserId[user.id];
      if (profileName != null && profileName.isNotEmpty) {
        authorName = profileName;
      }
    } catch (_) {
      // Fall back to auth metadata if the profile row is unavailable.
    }

    return FeedComposerIdentity(userId: user.id, authorName: authorName);
  }

  Future<void> createPost(String content) async {
    final identity = await getComposerIdentity();
    final normalizedContent = content.trim();
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

    final safeText = moderation.safeText.trim().isNotEmpty
        ? moderation.safeText.trim()
        : normalizedContent;

    await _client.from(_postsTable).insert({
      'user_id': identity.userId,
      'content_text': safeText,
    });
  }

  Future<void> likePost(String postId) async {
    _requireUser();
    await _client.rpc(
      'set_post_reaction_fast',
      params: {
        'p_post_id': postId,
        'p_reaction': 'like',
      },
    );
  }

  Future<void> unlikePost(String postId) async {
    _requireUser();
    await _client.rpc(
      'clear_post_reaction_fast',
      params: {
        'p_post_id': postId,
      },
    );
  }

  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final identity = await getComposerIdentity();
    final normalizedContent = content.trim();
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

    await _client.rpc(
      'add_post_comment_fast',
      params: {
        'p_post_id': postId,
        'p_content_text': safeText,
      },
    );
  }

  Future<void> deletePost(String postId) async {
    final user = _requireUser();
    await _client
        .from(_postsTable)
        .delete()
        .eq('id', postId)
        .eq('user_id', user.id);
  }

  Stream<List<FeedPost>> _watchMappedPosts(
    Stream<List<Map<String, dynamic>>> postsStream,
  ) {
    final controller = StreamController<List<FeedPost>>();

    List<Map<String, dynamic>> latestPosts = const <Map<String, dynamic>>[];
    List<Map<String, dynamic>> latestStats = const <Map<String, dynamic>>[];
    var isClosed = false;

    Future<void> emitMappedPosts() async {
      if (isClosed) return;

      try {
        final posts = await _mapPosts(
          latestPosts,
          statsRows: latestStats,
        );
        if (!isClosed) {
          controller.add(posts);
        }
      } catch (error, stackTrace) {
        if (!isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    late final StreamSubscription<List<Map<String, dynamic>>> postsSub;
    late final StreamSubscription<List<Map<String, dynamic>>> statsSub;

    postsSub = postsStream.listen(
      (rows) {
        latestPosts = rows;
        unawaited(emitMappedPosts());
      },
      onError: controller.addError,
    );

    statsSub = _client
        .from(_postStatsTable)
        .stream(primaryKey: const ['post_id']).listen(
      (rows) {
        latestStats = rows;
        unawaited(emitMappedPosts());
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      isClosed = true;
      await postsSub.cancel();
      await statsSub.cancel();
    };

    return controller.stream;
  }

  Future<List<FeedPost>> _mapPosts(
    List<Map<String, dynamic>> rows, {
    required List<Map<String, dynamic>> statsRows,
  }) async {
    final visibleRows =
        rows.where((row) => row['status']?.toString() == 'active').toList();

    final authorIds = visibleRows
        .map((row) => row['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final namesByUserId = await _loadProfileNames(authorIds);
    final statsByPostId = <String, Map<String, dynamic>>{
      for (final row in statsRows)
        if ((row['post_id']?.toString() ?? '').isNotEmpty)
          row['post_id'].toString(): Map<String, dynamic>.from(row),
    };

    final posts = visibleRows.map((row) {
      final map = Map<String, dynamic>.from(row);
      final userId = map['user_id']?.toString() ?? '';
      final postId = map['id']?.toString() ?? '';
      final stats = statsByPostId[postId];

      map['author_name'] = namesByUserId[userId];
      map['like_count'] = stats?['like_count'] ?? map['like_count'];
      map['comment_count'] = stats?['comment_count'] ?? map['comment_count'];

      return FeedPost.fromMap(map);
    }).toList();

    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<List<FeedComment>> _mapComments(
    List<Map<String, dynamic>> rows,
  ) async {
    final visibleRows =
        rows.where((row) => row['status']?.toString() == 'active').toList();

    final authorIds = visibleRows
        .map((row) => row['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final namesByUserId = await _loadProfileNames(authorIds);
    final comments = visibleRows.map((row) {
      final map = Map<String, dynamic>.from(row);
      final userId = map['user_id']?.toString() ?? '';
      map['author_name'] = namesByUserId[userId];
      return FeedComment.fromMap(map);
    }).toList();

    comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return comments;
  }

  Future<Map<String, String>> _loadProfileNames(
      Iterable<String> userIds) async {
    final ids = userIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) {
      return <String, String>{};
    }

    final namesByUserId = <String, String>{};

    for (final selectClause in _profileNameSelectCandidates) {
      try {
        final rows = await _client
            .from(_profilesTable)
            .select(selectClause)
            .inFilter('id', ids);

        for (final row in rows) {
          final map = Map<String, dynamic>.from(row);
          final id = map['id']?.toString() ?? '';
          final text = _readFirstText(<dynamic>[
            map['username'],
            map['display_name'],
            map['displayName'],
            map['displayname'],
          ]);

          if (id.isNotEmpty && text != null && text.isNotEmpty) {
            namesByUserId.putIfAbsent(id, () => text);
          }
        }

        if (namesByUserId.length == ids.length) {
          break;
        }
      } on PostgrestException catch (error) {
        if (_isMissingColumnError(error)) {
          continue;
        }
        rethrow;
      }
    }

    return namesByUserId;
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
    final name = _readFirstText(<dynamic>[
      metadata['username'],
      metadata['display_name'],
      metadata['displayName'],
      metadata['displayname'],
      metadata['name'],
      metadata['full_name'],
      user.email?.split('@').first,
    ]);

    return name ?? 'ผู้ใช้';
  }

  String? _readFirstText(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  bool _isMissingColumnError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == '42703' ||
        error.code == 'PGRST204' ||
        message.contains('column') && message.contains('does not exist') ||
        message.contains('could not find the') && message.contains('column');
  }
}

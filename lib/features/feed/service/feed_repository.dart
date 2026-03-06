import 'dart:async';

import 'package:flutter_application_1/core/services/content_moderation_service.dart';
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

  final SupabaseClient _client;
  final ContentModerationService _moderationService =
      ContentModerationService.instance;

  bool get supportsLikeActions => false;

  Stream<List<FeedPost>> watchPosts() {
    return _client
        .from(_postsTable)
        .stream(primaryKey: const ['id'])
        .order('created_at', ascending: false)
        .asyncMap(_mapPosts);
  }

  Stream<List<FeedPost>> watchPostsByAuthor(String authorId) {
    return _client
        .from(_postsTable)
        .stream(primaryKey: const ['id'])
        .eq('user_id', authorId)
        .order('created_at', ascending: false)
        .asyncMap(_mapPosts);
  }

  Stream<Set<String>> watchLikedPostIds(String userId) {
    return Stream<Set<String>>.value(const <String>{});
  }

  Future<FeedComposerIdentity> getComposerIdentity() async {
    final user = _requireUser();
    var authorName = _readNameFromAuth(user);

    try {
      final row = await _client
          .from(_profilesTable)
          .select('username')
          .eq('id', user.id)
          .maybeSingle();

      final username = row?['username']?.toString().trim();
      if (username != null && username.isNotEmpty) {
        authorName = username;
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
    throw const PostgrestException(
      message: 'ยังไม่มีตารางไลก์รายผู้ใช้สำหรับ feed นี้',
    );
  }

  Future<void> unlikePost(String postId) async {
    throw const PostgrestException(
      message: 'ยังไม่มีตารางไลก์รายผู้ใช้สำหรับ feed นี้',
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

  Future<List<FeedPost>> _mapPosts(List<Map<String, dynamic>> rows) async {
    final authorIds = rows
        .map((row) => row['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final namesByUserId = <String, String>{};
    if (authorIds.isNotEmpty) {
      try {
        final profiles = await _client
            .from(_profilesTable)
            .select('id, username')
            .inFilter('id', authorIds);

        for (final row in profiles) {
          final map = Map<String, dynamic>.from(row);
          final id = map['id']?.toString() ?? '';
          final username = map['username']?.toString().trim() ?? '';
          if (id.isNotEmpty && username.isNotEmpty) {
            namesByUserId[id] = username;
          }
        }
      } catch (_) {
        // Keep fallback display names from auth metadata/default text.
      }
    }

    final posts = rows.map((row) {
      final map = Map<String, dynamic>.from(row);
      final userId = map['user_id']?.toString() ?? '';
      map['author_name'] = namesByUserId[userId];
      return FeedPost.fromMap(map);
    }).toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
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
}

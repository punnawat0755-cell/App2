class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.content,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String content;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  factory FeedPost.fromMap(Map<String, dynamic> map) {
    return FeedPost(
      id: map['id']?.toString() ?? '',
      authorId: map['user_id']?.toString() ?? '',
      authorName: (map['author_name']?.toString().trim().isNotEmpty ?? false)
          ? map['author_name'].toString().trim()
          : 'ผู้ใช้',
      authorAvatarUrl: map['author_avatar_url']?.toString().trim() ?? '',
      content: map['content_text']?.toString().trim() ?? '',
      likeCount: _toInt(map['like_count']),
      commentCount: _toInt(map['comment_count']),
      createdAt: _toDateTime(map['created_at']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is DateTime) return value.toLocal();

    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed?.toLocal() ?? DateTime.now();
  }
}

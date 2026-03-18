class FeedComment {
  const FeedComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  factory FeedComment.fromMap(Map<String, dynamic> map) {
    return FeedComment(
      id: map['id']?.toString() ?? '',
      postId: map['post_id']?.toString() ?? '',
      authorId: map['user_id']?.toString() ?? '',
      authorName: (map['author_name']?.toString().trim().isNotEmpty ?? false)
          ? map['author_name'].toString().trim()
          : 'ผู้ใช้',
      content: map['content_text']?.toString().trim() ?? '',
      createdAt: _toDateTime(map['created_at']),
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is DateTime) return value.toLocal();

    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed?.toLocal() ?? DateTime.now();
  }
}

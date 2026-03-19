class HomeVideoClip {
  const HomeVideoClip({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.caption,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.createdAt,
    required this.orderNo,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String caption;
  final String videoUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final int orderNo;

  String get relativeTimeLabel {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} h';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} day';
    }
    return '${(difference.inDays / 7).floor()} week';
  }
}

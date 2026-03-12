import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/services/content_moderation_service.dart';
import 'package:flutter_application_1/features/feed/model/feed_post.dart';
import 'package:flutter_application_1/features/profile/model/profile_avatar_catalog.dart';
import 'package:flutter_application_1/features/feed/service/feed_repository.dart';
import 'package:flutter_application_1/supabase_client.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const _brandBlue = Color(0xFF4A89D8);

  final FeedRepository _repository = FeedRepository();
  final User? _currentUser = supabase.auth.currentUser;

  String _composerName = 'คุณ';
  String _composerAvatarUrl = ProfileAvatarCatalog.defaultAvatar;
  bool _isLoadingComposer = true;

  @override
  void initState() {
    super.initState();
    _loadComposerIdentity();
  }

  Future<void> _loadComposerIdentity() async {
    if (_currentUser == null) {
      if (!mounted) return;
      setState(() {
        _composerName = 'คุณ';
        _composerAvatarUrl = ProfileAvatarCatalog.defaultAvatar;
        _isLoadingComposer = false;
      });
      return;
    }

    try {
      final identity = await _repository.getComposerIdentity();
      if (!mounted) return;
      setState(() {
        _composerName = identity.authorName;
        _composerAvatarUrl = identity.authorAvatarUrl;
        _isLoadingComposer = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _composerName = _currentUser.email?.split('@').first ?? 'คุณ';
        _composerAvatarUrl = ProfileAvatarCatalog.defaultAvatar;
        _isLoadingComposer = false;
      });
    }
  }

  Future<void> _openComposer() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _FeedComposerPage(
          repository: _repository,
          composerName: _composerName,
          composerAvatarUrl: _composerAvatarUrl,
        ),
      ),
    );
    if (!mounted || created != true) return;
    _showSnackBar('โพสต์ของคุณถูกเผยแพร่แล้ว');
  }

  Future<void> _toggleLike(FeedPost post, bool isLiked) async {
    try {
      if (isLiked) {
        await _repository.unlikePost(post.id);
      } else {
        await _repository.likePost(post.id);
      }
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('อัปเดตการกดถูกใจไม่สำเร็จ: $error', isError: true);
    }
  }

  Future<void> _deletePost(FeedPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบโพสต์นี้?'),
        content: const Text('โพสต์นี้จะถูกลบออกจากชุมชนทันที'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repository.deletePost(post.id);
      if (!mounted) return;
      _showSnackBar('ลบโพสต์เรียบร้อย');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('ลบโพสต์ไม่สำเร็จ: $error', isError: true);
    }
  }

  void _openAuthorProfile(FeedPost post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeedProfilePage(
          repository: _repository,
          authorId: post.authorId,
          authorName: post.authorName,
          authorAvatarUrl: post.authorAvatarUrl,
          currentUserId: _currentUser?.id,
        ),
      ),
    );
  }

  Future<void> _refreshFeed() async {
    await _loadComposerIdentity();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  void _showSnackBar(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : _brandBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('กรุณาเข้าสู่ระบบเพื่อใช้งาน feed')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _FeedHeader(
              composerName: _composerName,
              composerAvatarUrl: _composerAvatarUrl,
              isLoadingComposer: _isLoadingComposer,
              onComposerTap: _openComposer,
            ),
            Expanded(
              child: StreamBuilder<List<FeedPost>>(
                stream: _repository.watchPosts(),
                builder: (context, postSnapshot) {
                  if (postSnapshot.hasError) {
                    return _FeedMessageState(
                      icon: Icons.cloud_off_rounded,
                      title: 'โหลด feed ไม่สำเร็จ',
                      subtitle: '${postSnapshot.error}',
                      actionLabel: 'ลองใหม่',
                      onAction: _refreshFeed,
                    );
                  }

                  if (!postSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return StreamBuilder<Set<String>>(
                    stream: _repository.watchLikedPostIds(currentUser.id),
                    builder: (context, likeSnapshot) {
                      final likedPostIds =
                          likeSnapshot.data ?? const <String>{};
                      final posts = postSnapshot.data ?? const <FeedPost>[];

                      if (posts.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _refreshFeed,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
                            children: [
                              _FeedEmptyState(onCreatePost: _openComposer),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _refreshFeed,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: posts.length,
                          separatorBuilder: (context, index) => Divider(
                              thickness: 1, color: Colors.grey.shade200),
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            final isLiked = likedPostIds.contains(post.id);

                            return FeedPostCard(
                              post: post,
                              isLiked: isLiked,
                              isOwnPost: post.authorId == currentUser.id,
                              onAuthorTap: () => _openAuthorProfile(post),
                              onToggleLike: _repository.supportsLikeActions
                                  ? () => _toggleLike(post, isLiked)
                                  : null,
                              onDelete: post.authorId == currentUser.id
                                  ? () => _deletePost(post)
                                  : null,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedProfilePage extends StatelessWidget {
  const FeedProfilePage({
    super.key,
    required this.repository,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.currentUserId,
  });

  final FeedRepository repository;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String? currentUserId;

  Future<void> _toggleLike(
    BuildContext context,
    FeedPost post,
    bool isLiked,
  ) async {
    try {
      if (isLiked) {
        await repository.unlikePost(post.id);
      } else {
        await repository.likePost(post.id);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัปเดตการกดถูกใจไม่สำเร็จ: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePost(BuildContext context, FeedPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบโพสต์นี้?'),
        content: const Text('โพสต์นี้จะถูกลบออกจากชุมชนทันที'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await repository.deletePost(post.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบโพสต์เรียบร้อย')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบโพสต์ไม่สำเร็จ: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(authorName),
      ),
      body: StreamBuilder<List<FeedPost>>(
        stream: repository.watchPostsByAuthor(authorId),
        builder: (context, postSnapshot) {
          if (postSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'โหลดโปรไฟล์ไม่สำเร็จ\n${postSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!postSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<Set<String>>(
            stream: currentUserId == null
                ? Stream<Set<String>>.value(const <String>{})
                : repository.watchLikedPostIds(currentUserId!),
            builder: (context, likeSnapshot) {
              final posts = postSnapshot.data ?? const <FeedPost>[];
              final likedPostIds = likeSnapshot.data ?? const <String>{};
              final totalLikes =
                  posts.fold<int>(0, (sum, post) => sum + post.likeCount);
              final resolvedAuthorAvatarUrl = posts.isNotEmpty
                  ? posts.first.authorAvatarUrl
                  : authorAvatarUrl;
              final items = <Widget>[
                _ProfileHeader(
                  authorName: authorName,
                  authorAvatarUrl: resolvedAuthorAvatarUrl,
                  postCount: posts.length,
                  totalLikes: totalLikes,
                ),
                if (posts.isEmpty)
                  const _FeedMessageState(
                    icon: Icons.article_outlined,
                    title: 'ยังไม่มีโพสต์',
                    subtitle: 'เมื่อผู้ใช้คนนี้เริ่มโพสต์ ข้อความจะขึ้นที่นี่',
                  )
                else
                  ...posts.map(
                    (post) => FeedPostCard(
                      post: post,
                      isLiked: likedPostIds.contains(post.id),
                      isOwnPost: post.authorId == currentUserId,
                      onAuthorTap: null,
                      onToggleLike: repository.supportsLikeActions
                          ? () => _toggleLike(
                                context,
                                post,
                                likedPostIds.contains(post.id),
                              )
                          : null,
                      onDelete: post.authorId == currentUserId
                          ? () => _deletePost(context, post)
                          : null,
                    ),
                  ),
              ];

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 32),
                separatorBuilder: (context, index) =>
                    Divider(thickness: 1, color: Colors.grey.shade200),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return items[index];
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _FeedComposerPage extends StatefulWidget {
  const _FeedComposerPage({
    required this.repository,
    required this.composerName,
    required this.composerAvatarUrl,
  });

  final FeedRepository repository;
  final String composerName;
  final String composerAvatarUrl;

  @override
  State<_FeedComposerPage> createState() => _FeedComposerPageState();
}

class _FeedComposerPageState extends State<_FeedComposerPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  String _messageForModerationReason(String reason) {
    final normalizedReason = reason.toLowerCase();
    if (normalizedReason.contains('moderation-blocked-by-n8n')) {
      return 'ระบบตรวจพบว่าโพสต์นี้ไม่เหมาะสม จึงไม่อนุญาตให้เผยแพร่';
    }
    return 'ไม่สามารถโพสต์ข้อความนี้ได้ เนื่องจากผลคำไม่เหมาะสม';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.repository.createPost(content);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop(true);
    } on ContentModerationBlockedException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_messageForModerationReason(error.reason)),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สร้างโพสต์ไม่สำเร็จ: $error'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('เขียนโพสต์'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _AuthorAvatar(
                    name: widget.composerName,
                    avatarUrl: widget.composerAvatarUrl,
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.composerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF25527A),
                          ),
                        ),
                        const Text(
                          'แชร์ความรู้สึกหรือเรื่องที่อยากเล่าได้เลย',
                          style: TextStyle(color: Color(0xFF6D8BA3)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                maxLines: 8,
                minLines: 6,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText:
                      'วันนี้คุณกำลังรู้สึกยังไง หรืออยากแบ่งปันอะไรกับชุมชน?',
                  filled: true,
                  fillColor: const Color(0xFFF5FBFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'โพสต์จะปรากฏบน feed แบบ realtime',
                      style: TextStyle(color: Color(0xFF7E96AC)),
                    ),
                  ),
                  FilledButton(
                    onPressed: _controller.text.trim().isEmpty || _isSubmitting
                        ? null
                        : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4A89D8),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('โพสต์'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.isLiked,
    required this.isOwnPost,
    required this.onToggleLike,
    required this.onAuthorTap,
    this.onDelete,
  });

  final FeedPost post;
  final bool isLiked;
  final bool isOwnPost;
  final VoidCallback? onToggleLike;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onAuthorTap,
                borderRadius: BorderRadius.circular(40),
                child: _AuthorAvatar(
                  name: post.authorName,
                  avatarUrl: post.authorAvatarUrl,
                  radius: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: onAuthorTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatPostTime(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isOwnPost)
                Text(
                  'โพสต์ของคุณ',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (onDelete != null)
                PopupMenuButton<String>(
                  color: Colors.white,
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('ลบโพสต์'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.content,
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onToggleLike,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? const Color(0xFF4489D7) : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.likeCount.toString(),
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight:
                            isLiked ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.composerName,
    required this.composerAvatarUrl,
    required this.isLoadingComposer,
    required this.onComposerTap,
  });

  final String composerName;
  final String composerAvatarUrl;
  final bool isLoadingComposer;
  final VoidCallback onComposerTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Image.asset(
              'assets/images/How 1.png',
              width: 65,
              height: 88,
            ),
          ),
        ),
        Divider(thickness: 1, color: Colors.grey.shade200),
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: onComposerTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _AuthorAvatar(
                    name: composerName,
                    avatarUrl: composerAvatarUrl,
                    radius: 20,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      isLoadingComposer
                          ? 'กำลังโหลด...'
                          : '$composerName กำลังคิดอะไรอยู่.....',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/Picture.png',
                    width: 40,
                    height: 35,
                    fit: BoxFit.contain,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(thickness: 1, color: Colors.grey.shade200),
      ],
    );
  }
}

class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState({required this.onCreatePost});

  final VoidCallback onCreatePost;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.forum_outlined, size: 44, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        const Text(
          'ยังไม่มีโพสต์ในชุมชน',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'เริ่มโพสต์แรกเพื่อให้ feed นี้เริ่มใช้งานได้จริง',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 18),
        OutlinedButton(
          onPressed: onCreatePost,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4489D7),
          ),
          child: const Text('สร้างโพสต์แรก'),
        ),
      ],
    );
  }
}

class _FeedMessageState extends StatelessWidget {
  const _FeedMessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final FutureOr<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () => onAction?.call(),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.authorName,
    required this.authorAvatarUrl,
    required this.postCount,
    required this.totalLikes,
  });

  final String authorName;
  final String authorAvatarUrl;
  final int postCount;
  final int totalLikes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            _AuthorAvatar(
              name: authorName,
              avatarUrl: authorAvatarUrl,
              radius: 50,
            ),
            const SizedBox(height: 10),
            Text(
              authorName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$postCount โพสต์ • $totalLikes ถูกใจ',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({
    required this.name,
    required this.avatarUrl,
    required this.radius,
  });

  final String name;
  final String avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE6F4FF),
      backgroundImage: ProfileAvatarCatalog.providerFor(avatarUrl),
    );
  }
}

String _formatPostTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inSeconds < 60) return 'เมื่อสักครู่';
  if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
  if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
  if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';

  return DateFormat('d/M/yyyy HH:mm').format(time);
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/services/content_moderation_service.dart';
import 'package:flutter_application_1/features/feed/model/feed_post.dart';
import 'package:flutter_application_1/features/feed/service/feed_repository.dart';
import 'package:flutter_application_1/features/profile/model/profile_avatar_catalog.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const _brandBlue = Color(0xFF4489D7);

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
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedComposerSheet(
        repository: _repository,
        composerName: _composerName,
        composerAvatarUrl: _composerAvatarUrl,
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

  Future<void> _refreshProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: StreamBuilder<List<FeedPost>>(
        stream: repository.watchPostsByAuthor(authorId),
        builder: (context, postSnapshot) {
          if (postSnapshot.hasError) {
            return ListView(
              children: [
                _ProfileHeader(
                  authorName: authorName,
                  authorAvatarUrl: authorAvatarUrl,
                  postCount: 0,
                  totalLikes: 0,
                ),
                Divider(thickness: 1, color: Colors.grey.shade300),
                const SizedBox(height: 32),
                SizedBox(
                  height: 280,
                  child: _FeedMessageState(
                    icon: Icons.cloud_off_rounded,
                    title: 'โหลดโปรไฟล์ไม่สำเร็จ',
                    subtitle: '${postSnapshot.error}',
                  ),
                ),
              ],
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

              return RefreshIndicator(
                onRefresh: _refreshProfile,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 32),
                  itemCount: posts.isEmpty ? 2 : posts.length + 1,
                  separatorBuilder: (context, index) =>
                      Divider(thickness: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _ProfileHeader(
                        authorName: authorName,
                        authorAvatarUrl: resolvedAuthorAvatarUrl,
                        postCount: posts.length,
                        totalLikes: totalLikes,
                      );
                    }

                    if (posts.isEmpty) {
                      return const SizedBox(
                        height: 280,
                        child: _FeedMessageState(
                          icon: Icons.article_outlined,
                          title: 'ยังไม่มีโพสต์',
                          subtitle:
                              'เมื่อผู้ใช้คนนี้เริ่มโพสต์ ข้อความจะขึ้นที่นี่',
                        ),
                      );
                    }

                    final post = posts[index - 1];
                    return FeedPostCard(
                      post: post,
                      isLiked: likedPostIds.contains(post.id),
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
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FeedComposerSheet extends StatefulWidget {
  const _FeedComposerSheet({
    required this.repository,
    required this.composerName,
    required this.composerAvatarUrl,
  });

  final FeedRepository repository;
  final String composerName;
  final String composerAvatarUrl;

  @override
  State<_FeedComposerSheet> createState() => _FeedComposerSheetState();
}

class _FeedComposerSheetState extends State<_FeedComposerSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  String _messageForModerationReason(String reason) {
    final normalizedReason = reason.toLowerCase();
    if (normalizedReason.contains('moderation-blocked-by-n8n')) {
      return 'ระบบตรวจพบว่าโพสต์นี้ไม่เหมาะสม จึงไม่อนุญาตให้เผยแพร่';
    }
    return 'ไม่สามารถโพสต์ข้อความนี้ได้ เนื่องจากผลคำไม่เหมาะสม';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
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

  void _showAttachmentMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ตอนนี้ composer นี้ยังรองรับการโพสต์ข้อความเท่านั้น'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canSubmit = _controller.text.trim().isNotEmpty && !_isSubmitting;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Material(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 10),
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF8D8D8D),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          'NewPost',
                          style: TextStyle(
                            color: Color(0xFF6C6C6C),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        _AuthorAvatar(
                          name: widget.composerName,
                          avatarUrl: widget.composerAvatarUrl,
                          radius: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.composerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C6C6C),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _showAttachmentMessage,
                          child: Image.asset(
                            'assets/images/Picture.png',
                            width: 50,
                            height: 50,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextField(
                              focusNode: _focusNode,
                              autofocus: true,
                              controller: _controller,
                              maxLines: null,
                              maxLength: 120,
                              autocorrect: false,
                              enableSuggestions: false,
                              style: const TextStyle(fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: 'คุณกำลังคิดอะไรอยู่.....',
                                hintStyle: TextStyle(
                                  color: Color(0xFFCAC9C9),
                                  fontWeight: FontWeight.bold,
                                ),
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 15,
                      left: 15,
                      top: 5,
                      bottom: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_controller.text.length}/120',
                              style: const TextStyle(
                                color: Color(0xFFC3C3C3),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: canSubmit ? _submit : null,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: canSubmit ? 1 : 0.55,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 26,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5CD9FF),
                                    borderRadius: BorderRadius.circular(20),
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
                                      : const Text(
                                          'POST',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
    required this.onToggleLike,
    required this.onAuthorTap,
    this.onDelete,
  });

  final FeedPost post;
  final bool isLiked;
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
              GestureDetector(
                onTap: onAuthorTap,
                child: _AuthorAvatar(
                  name: post.authorName,
                  avatarUrl: post.authorAvatarUrl,
                  radius: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onAuthorTap,
                  child: Text(
                    post.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
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
            style: const TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          if ((post.imageUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: 250,
                  height: 300,
                  child: Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
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
                    fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.composerAvatarUrl,
    required this.isLoadingComposer,
    required this.onComposerTap,
  });

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
                    name: 'คุณ',
                    avatarUrl: composerAvatarUrl,
                    radius: 20,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      isLoadingComposer
                          ? 'กำลังโหลด...'
                          : 'คุณกำลังคิดอะไรอยู่.....',
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$postCount โพสต์ • $totalLikes ถูกใจ',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
        ],
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
      child: avatarUrl.trim().isEmpty
          ? Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: TextStyle(
                color: const Color(0xFF4489D7),
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }
}

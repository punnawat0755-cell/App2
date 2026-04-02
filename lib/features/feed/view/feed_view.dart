import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/core/services/content_moderation_service.dart';
import 'package:flutter_application_1/core/services/post_moderation_service.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:flutter_application_1/features/feed/model/feed_comment.dart';
import 'package:flutter_application_1/features/feed/model/feed_post.dart';
import 'package:flutter_application_1/features/feed/service/feed_delete_service.dart';
import 'package:flutter_application_1/features/feed/service/feed_repository.dart';
import 'package:flutter_application_1/features/feed/view/feed_photo_capture_page.dart';
import 'package:flutter_application_1/features/profile/model/profile_avatar_catalog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    this.focusPostId,
  });

  final String? focusPostId;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const _brandBlue = Color(0xFF4489D7);
  static const _feedBackground = Color(0xFFF4FAFF);

  final FeedRepository _repository = FeedRepository();
  final User? _currentUser = supabase.auth.currentUser;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _postItemKeys = <String, GlobalKey>{};
  late final Stream<List<FeedPost>> _postsStream;
  late final Stream<Set<String>> _likedPostIdsStream;

  String _composerName = 'คุณ';
  String _composerAvatarUrl = ProfileAvatarCatalog.defaultAvatar;
  bool _isLoadingComposer = true;
  String? _pendingFocusPostId;
  bool _isFocusingPost = false;
  bool _hasShownMissingPostMessage = false;

  @override
  void initState() {
    super.initState();
    final focusPostId = widget.focusPostId?.trim() ?? '';
    _pendingFocusPostId = focusPostId.isEmpty ? null : focusPostId;
    _postsStream = _repository.watchPosts();
    _likedPostIdsStream = _currentUser == null
        ? Stream<Set<String>>.value(const <String>{})
        : _repository.watchLikedPostIds(_currentUser.id);
    _loadComposerIdentity();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _openComposer({bool openImagePickerOnOpen = false}) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedComposerSheet(
        repository: _repository,
        composerName: _composerName,
        composerAvatarUrl: _composerAvatarUrl,
        openImagePickerOnOpen: openImagePickerOnOpen,
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
      rethrow;
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
      _showSnackBar('????????????????');
    } on FeedPostUnavailableException {
      if (!mounted) return;
      _showSnackBar('???????????????????????????????????', isError: true);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('????????????????: $error', isError: true);
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

  GlobalKey _keyForPost(String postId) {
    return _postItemKeys.putIfAbsent(postId, GlobalKey.new);
  }

  void _focusPostIfNeeded(List<FeedPost> posts) {
    final targetPostId = _pendingFocusPostId;
    if (targetPostId == null || _isFocusingPost) {
      return;
    }

    final targetIndex = posts.indexWhere((post) => post.id == targetPostId);
    if (targetIndex == -1) {
      if (!_hasShownMissingPostMessage) {
        _hasShownMissingPostMessage = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showSnackBar('ไม่พบโพสต์นี้ในฟีด', isError: true);
        });
      }
      _pendingFocusPostId = null;
      return;
    }

    _isFocusingPost = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted || !_scrollController.hasClients) return;

        final targetKey = _keyForPost(targetPostId);
        const maxAttempts = 8;

        for (var attempt = 0; attempt < maxAttempts; attempt++) {
          if (!mounted || !_scrollController.hasClients) {
            return;
          }

          final targetContext = targetKey.currentContext;
          if (targetContext != null && targetContext.mounted) {
            await Scrollable.ensureVisible(
              targetContext,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              alignment: 0.08,
            );
            return;
          }

          final maxOffset = _scrollController.position.maxScrollExtent;
          if (maxOffset <= 0) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            continue;
          }

          final targetRatio = (targetIndex + 1) / (posts.length + 1);
          final ratioOffset = maxOffset * targetRatio;
          final probeOffset = (ratioOffset + (attempt * 120.0)).clamp(
            0.0,
            maxOffset,
          );

          await _scrollController.animateTo(
            probeOffset,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
          await Future<void>.delayed(const Duration(milliseconds: 70));
        }

        if (mounted) {
          _showSnackBar('เลื่อนไปโพสต์นี้ไม่สำเร็จ ลองแตะอีกครั้ง',
              isError: true);
        }
      } finally {
        _pendingFocusPostId = null;
        _isFocusingPost = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser;
    final openedFromFavorites =
        (widget.focusPostId?.trim().isNotEmpty ?? false);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('กรุณาเข้าสู่ระบบเพื่อใช้งาน feed')),
      );
    }

    return Scaffold(
      appBar: openedFromFavorites
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              title: const Text(
                'กลับไปรายการโปรด',
                style: TextStyle(
                  color: Color(0xFF4489D7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      backgroundColor: _feedBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
            final maxContentWidth =
                constraints.maxWidth > 620 ? 620.0 : constraints.maxWidth;

            return Center(
              child: SizedBox(
                width: maxContentWidth,
                child: StreamBuilder<List<FeedPost>>(
                  stream: _postsStream,
                  builder: (context, postSnapshot) {
                    final feedHeader = _FeedHeader(
                      composerAvatarUrl: _composerAvatarUrl,
                      composerName: _composerName,
                      isLoadingComposer: _isLoadingComposer,
                      onComposerTap: () => _openComposer(),
                      onImageTap: () =>
                          _openComposer(openImagePickerOnOpen: true),
                    );

                    if (postSnapshot.hasError) {
                      return RefreshIndicator(
                        onRefresh: _refreshFeed,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: scale.rs(16, min: 12, max: 16),
                            right: scale.rs(16, min: 12, max: 16),
                            bottom: scale.rs(120, min: 90, max: 120),
                          ),
                          children: [
                            feedHeader,
                            SizedBox(
                              height: scale.rs(320, min: 240, max: 320),
                              child: _FeedMessageState(
                                icon: Icons.cloud_off_rounded,
                                title: 'โหลด feed ไม่สำเร็จ',
                                subtitle: '${postSnapshot.error}',
                                actionLabel: 'ลองใหม่',
                                onAction: _refreshFeed,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!postSnapshot.hasData) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: scale.rs(16, min: 12, max: 16),
                        ),
                        children: [
                          feedHeader,
                          Padding(
                            padding: EdgeInsets.only(
                              top: scale.rs(72, min: 54, max: 72),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ],
                      );
                    }

                    return StreamBuilder<Set<String>>(
                      stream: _likedPostIdsStream,
                      builder: (context, likeSnapshot) {
                        final likedPostIds =
                            likeSnapshot.data ?? const <String>{};
                        final posts = postSnapshot.data ?? const <FeedPost>[];
                        _focusPostIfNeeded(posts);

                        return RefreshIndicator(
                          onRefresh: _refreshFeed,
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(
                              left: scale.rs(16, min: 12, max: 16),
                              right: scale.rs(16, min: 12, max: 16),
                              top: scale.rs(8, min: 6, max: 8),
                              bottom: scale.rs(120, min: 90, max: 120),
                            ),
                            itemCount: posts.isEmpty ? 2 : posts.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return feedHeader;
                              }

                              if (posts.isEmpty) {
                                return Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    scale.rs(24, min: 16, max: 24),
                                    scale.rs(48, min: 30, max: 48),
                                    scale.rs(24, min: 16, max: 24),
                                    0,
                                  ),
                                  child: _FeedEmptyState(
                                    onCreatePost: () => _openComposer(),
                                  ),
                                );
                              }

                              final post = posts[index - 1];
                              final isLiked = likedPostIds.contains(post.id);

                              return KeyedSubtree(
                                key: _keyForPost(post.id),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: scale.rs(14, min: 10, max: 14),
                                  ),
                                  child: FeedPostCard(
                                    key: ValueKey(post.id),
                                    post: post,
                                    isLiked: isLiked,
                                    onAuthorTap: () => _openAuthorProfile(post),
                                    onToggleLike:
                                        _repository.supportsLikeActions
                                            ? () => _toggleLike(post, isLiked)
                                            : null,
                                    onDelete: post.authorId == currentUser.id
                                        ? () => _deletePost(post)
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
class FeedProfilePage extends StatefulWidget {
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

  @override
  State<FeedProfilePage> createState() => _FeedProfilePageState();
}

class _FeedProfilePageState extends State<FeedProfilePage> {
  late final Stream<List<FeedPost>> _postsStream;
  late final Stream<Set<String>> _likedPostIdsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = widget.repository.watchPostsByAuthor(widget.authorId);
    _likedPostIdsStream = widget.currentUserId == null
        ? Stream<Set<String>>.value(const <String>{})
        : widget.repository.watchLikedPostIds(widget.currentUserId!);
  }

  Future<void> _toggleLike(
    BuildContext context,
    FeedPost post,
    bool isLiked,
  ) async {
    try {
      if (isLiked) {
        await widget.repository.unlikePost(post.id);
      } else {
        await widget.repository.likePost(post.id);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('???????????????????????????????????????????????????????????????????????????: $error'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  Future<void> _deletePost(BuildContext context, FeedPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('???????????????????????????????'),
        content: const Text(
          '??????????????????????????????????????????????????????????????????????????????????????????????????????????',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('??????????????????'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('??????'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.repository.deletePost(post.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('????????????????????????????????????????????????????????????')),
      );
    } on FeedPostUnavailableException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('?????????????????????????????????????????????????????????'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('????????????????????????????????????????????????????????????????????????: $error'),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
          final maxContentWidth =
              constraints.maxWidth > 620 ? 620.0 : constraints.maxWidth;

          return Center(
            child: SizedBox(
              width: maxContentWidth,
              child: StreamBuilder<List<FeedPost>>(
                stream: _postsStream,
                builder: (context, postSnapshot) {
                  if (postSnapshot.hasError) {
                    return ListView(
                      children: [
                        _ProfileHeader(
                          authorName: widget.authorName,
                          authorAvatarUrl: widget.authorAvatarUrl,
                          postCount: 0,
                          totalLikes: 0,
                        ),
                        Divider(thickness: 1, color: Colors.grey.shade300),
                        SizedBox(height: scale.rs(32, min: 22, max: 32)),
                        SizedBox(
                          height: scale.rs(280, min: 220, max: 280),
                          child: _FeedMessageState(
                            icon: Icons.cloud_off_rounded,
                            title: '????????????????????????????????????????????????????????????',
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
                    stream: _likedPostIdsStream,
                    builder: (context, likeSnapshot) {
                      final posts = postSnapshot.data ?? const <FeedPost>[];
                      final likedPostIds = likeSnapshot.data ?? const <String>{};
                      final totalLikes = posts.fold<int>(
                        0,
                        (sum, post) => sum + post.likeCount,
                      );
                      final resolvedAuthorAvatarUrl = posts.isNotEmpty
                          ? posts.first.authorAvatarUrl
                          : widget.authorAvatarUrl;

                      return RefreshIndicator(
                        onRefresh: _refreshProfile,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: scale.rs(32, min: 24, max: 32),
                          ),
                          itemCount: posts.isEmpty ? 2 : posts.length + 1,
                          separatorBuilder: (context, index) => Divider(
                            thickness: 1,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _ProfileHeader(
                                authorName: widget.authorName,
                                authorAvatarUrl: resolvedAuthorAvatarUrl,
                                postCount: posts.length,
                                totalLikes: totalLikes,
                              );
                            }

                            if (posts.isEmpty) {
                              return SizedBox(
                                height: scale.rs(280, min: 220, max: 280),
                                child: _FeedMessageState(
                                  icon: Icons.article_outlined,
                                  title: '????????????????????????????????????????????????????????????',
                                  subtitle:
                                      '?????????????????????????????????????????????????????????????????????????????? ?????????????????????????????????????????????????????????',
                                ),
                              );
                            }

                            final post = posts[index - 1];
                            final isLiked = likedPostIds.contains(post.id);

                            return FeedPostCard(
                              key: ValueKey(post.id),
                              post: post,
                              isLiked: isLiked,
                              onAuthorTap: null,
                              onToggleLike: widget.repository.supportsLikeActions
                                  ? () => _toggleLike(
                                        context,
                                        post,
                                        isLiked,
                                      )
                                  : null,
                              onDelete: post.authorId == widget.currentUserId
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
            ),
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
    required this.openImagePickerOnOpen,
  });

  final FeedRepository repository;
  final String composerName;
  final String composerAvatarUrl;
  final bool openImagePickerOnOpen;

  @override
  State<_FeedComposerSheet> createState() => _FeedComposerSheetState();
}

class _FeedComposerSheetState extends State<_FeedComposerSheet> {
  static const _maxImageBytes = 8 * 1024 * 1024;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final PostModerationService _postModerationService =
      PostModerationService.instance;

  bool _isSubmitting = false;
  bool _isPickingImage = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

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
      if (!mounted) {
        return;
      }

      if (widget.openImagePickerOnOpen) {
        _pickImage();
      } else {
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

  Future<ImageSource?> _promptImageSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FeedImageSourceSheet(),
    );
  }

  Future<void> _waitForModalToClose() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
  }

  Future<void> _pickImage() async {
    if (_isPickingImage || _isSubmitting) {
      return;
    }

    final source = await _promptImageSource();
    if (!mounted || source == null) {
      _focusNode.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isPickingImage = true);

    try {
      final XFile? image;
      if (source == ImageSource.camera && _usesInAppCameraPage) {
        await _waitForModalToClose();
        if (!mounted) {
          return;
        }
        image = await Navigator.of(context).push<XFile>(
          MaterialPageRoute(
            builder: (_) => const FeedPhotoCapturePage(),
          ),
        );
      } else {
        image = await _imagePicker.pickImage(
          source: source,
          imageQuality: 88,
          maxWidth: 2200,
        );
      }

      final selectedImage = image;
      if (selectedImage == null) {
        return;
      }

      final imageBytes = await selectedImage.readAsBytes();
      if (!mounted) return;

      if (imageBytes.lengthInBytes > _maxImageBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รูปใหญ่เกินไป กรุณาเลือกรูปที่ไม่เกิน 8 MB'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _selectedImageBytes = imageBytes;
        _selectedImageName = selectedImage.name;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เลือกรูปไม่สำเร็จ: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
        _focusNode.requestFocus();
      }
    }
  }

  bool get _usesInAppCameraPage {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  void _removeSelectedImage() {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  List<String> _buildImageNotes({
    required String caption,
    required bool hasSelectedImage,
  }) {
    final normalizedCaption = caption.trim();
    if (!hasSelectedImage) {
      return const <String>[
        'โพสต์ข้อความในฟีดโดยไม่มีรูปภาพแนบ',
      ];
    }

    if (normalizedCaption.isNotEmpty) {
      return <String>[
        'รูปภาพประกอบโพสต์ในฟีด',
        'คำอธิบายจากผู้ใช้: $normalizedCaption',
      ];
    }

    return const <String>[
      'รูปภาพที่ผู้ใช้ต้องการโพสต์ในฟีด',
      'กรุณาตรวจสอบความเหมาะสมของภาพก่อนเผยแพร่',
    ];
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    final hasSelectedImage =
        _selectedImageBytes != null && _selectedImageBytes!.isNotEmpty;
    if ((content.isEmpty && !hasSelectedImage) || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // PRE-POST MODERATION HOOK: block submission unless webhook allows it.
      final moderationResult = await _postModerationService.moderateImage(
        userId: supabase.auth.currentUser?.id ?? '',
        caption: content,
        imageUrls: const <String>[],
        imageNotes: _buildImageNotes(
          caption: content,
          hasSelectedImage: hasSelectedImage,
        ),
      );
      if (!mounted) return;
      if (moderationResult.allowed != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(moderationResult.summary),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      await widget.repository.createPost(
        content: content,
        imageBytes: _selectedImageBytes,
        imageFileName: _selectedImageName,
      );
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
    } on FeedImageBucketNotFoundException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ยังไม่พบ Supabase Storage bucket ชื่อ ${error.bucketName} กรุณาตรวจชื่อ bucket หรือสร้าง bucket นี้เป็น Public',
          ),
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
    final scale = context.responsive;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasSelectedImage =
        _selectedImageBytes != null && _selectedImageBytes!.isNotEmpty;
    final canSubmit =
        (_controller.text.trim().isNotEmpty || hasSelectedImage) &&
            !_isSubmitting &&
            !_isPickingImage;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(scale.rs(20, min: 16, max: 20)),
          ),
          child: Material(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(
                        top: scale.rs(12, min: 8, max: 12),
                        bottom: scale.rs(10, min: 8, max: 10),
                      ),
                      width: scale.rs(45, min: 35, max: 45),
                      height: scale.rs(5, min: 4, max: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: scale.rs(15, min: 10, max: 15),
                      vertical: scale.rs(5, min: 3, max: 5),
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
                        Text(
                          'NewPost',
                          style: TextStyle(
                            color: Color(0xFF6C6C6C),
                            fontSize: scale.rf(18, min: 15.5, max: 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: scale.rs(10, min: 8, max: 10),
                      vertical: scale.rs(5, min: 3, max: 5),
                    ),
                    child: Row(
                      children: [
                        _AuthorAvatar(
                          name: widget.composerName,
                          avatarUrl: widget.composerAvatarUrl,
                          radius: scale.rs(18, min: 15, max: 18),
                        ),
                        SizedBox(width: scale.rs(12, min: 8, max: 12)),
                        Expanded(
                          child: Text(
                            widget.composerName,
                            style: TextStyle(
                              fontSize: scale.rf(18, min: 15.5, max: 18),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6C6C6C),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Image.asset(
                            'assets/images/Picture.png',
                            width: scale.rs(50, min: 40, max: 50),
                            height: scale.rs(50, min: 40, max: 50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: scale.rs(16, min: 12, max: 16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: scale.rs(10, min: 8, max: 10),
                            ),
                            child: TextField(
                              focusNode: _focusNode,
                              autofocus: true,
                              controller: _controller,
                              maxLines: null,
                              maxLength: 120,
                              autocorrect: false,
                              enableSuggestions: false,
                              style: TextStyle(
                                fontSize: scale.rf(16, min: 14, max: 16),
                              ),
                              decoration: InputDecoration(
                                hintText: 'คุณกำลังคิดอะไรอยู่.....',
                                hintStyle: TextStyle(
                                  color: Color(0xFFCAC9C9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: scale.rf(14, min: 12, max: 14),
                                ),
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          if (hasSelectedImage) ...[
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                scale.rs(10, min: 8, max: 10),
                                scale.rs(4, min: 2, max: 4),
                                scale.rs(10, min: 8, max: 10),
                                scale.rs(14, min: 10, max: 14),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      scale.rs(18, min: 14, max: 18),
                                    ),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Image.memory(
                                        _selectedImageBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: scale.rs(10, min: 6, max: 10),
                                    right: scale.rs(10, min: 6, max: 10),
                                    child: Material(
                                      color: Colors.black54,
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: _removeSelectedImage,
                                        child: Padding(
                                          padding: EdgeInsets.all(
                                            scale.rs(6, min: 4, max: 6),
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size:
                                                scale.rs(18, min: 14, max: 18),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: scale.rs(12, min: 8, max: 12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: scale.rs(18, min: 14, max: 18),
                                    color: Colors.grey.shade500,
                                  ),
                                  SizedBox(width: scale.rs(6, min: 4, max: 6)),
                                  Expanded(
                                    child: Text(
                                      _selectedImageName ?? 'รูปที่เลือก',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize:
                                            scale.rf(13, min: 11.5, max: 13),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: scale.rs(8, min: 6, max: 8)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      right: scale.rs(15, min: 10, max: 15),
                      left: scale.rs(15, min: 10, max: 15),
                      top: scale.rs(5, min: 3, max: 5),
                      bottom: scale.rs(12, min: 8, max: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_controller.text.length}/120',
                              style: TextStyle(
                                color: const Color(0xFFC3C3C3),
                                fontSize: scale.rf(13, min: 11.5, max: 13),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: scale.rs(8, min: 6, max: 8)),
                            if (_isPickingImage)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: scale.rs(8, min: 6, max: 8),
                                ),
                                child: SizedBox(
                                  width: scale.rs(18, min: 14, max: 18),
                                  height: scale.rs(18, min: 14, max: 18),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF5CD9FF),
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: canSubmit ? _submit : null,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: canSubmit ? 1 : 0.55,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: scale.rs(26, min: 20, max: 26),
                                    vertical: scale.rs(8, min: 6, max: 8),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5CD9FF),
                                    borderRadius: BorderRadius.circular(
                                      scale.rs(20, min: 16, max: 20),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? SizedBox(
                                          width: scale.rs(18, min: 14, max: 18),
                                          height:
                                              scale.rs(18, min: 14, max: 18),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'POST',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize:
                                                scale.rf(16, min: 14, max: 16),
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

class _FeedImageSourceSheet extends StatelessWidget {
  const _FeedImageSourceSheet();

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(scale.rs(28, min: 20, max: 28)),
        ),
        child: Material(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                scale.rs(24, min: 16, max: 24),
                scale.rs(20, min: 14, max: 20),
                scale.rs(24, min: 16, max: 24),
                scale.rs(24, min: 16, max: 24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: scale.rs(45, min: 35, max: 45),
                      height: scale.rs(5, min: 4, max: 5),
                      margin: EdgeInsets.only(
                        bottom: scale.rs(16, min: 10, max: 16),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    'เพิ่มรูปภาพ',
                    style: TextStyle(
                      fontSize: scale.rf(18, min: 15.5, max: 18),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4489D7),
                    ),
                  ),
                  SizedBox(height: scale.rs(6, min: 4, max: 6)),
                  Text(
                    'เลือกรูปจากกล้องหรือรูปที่มีอยู่ในเครื่อง',
                    style: TextStyle(
                      fontSize: scale.rf(14, min: 12, max: 14),
                      color: Colors.black.withValues(alpha: 0.65),
                    ),
                  ),
                  SizedBox(height: scale.rs(18, min: 12, max: 18)),
                  _FeedImageSourceTile(
                    icon: Icons.camera_alt_rounded,
                    title: 'ถ่ายรูป',
                    subtitle: 'เปิดกล้องเพื่อถ่ายรูปแล้วนำมาโพสต์',
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),
                  SizedBox(height: scale.rs(12, min: 8, max: 12)),
                  _FeedImageSourceTile(
                    icon: Icons.photo_library_rounded,
                    title: 'เลือกจากคลัง',
                    subtitle: 'ใช้รูปภาพที่มีอยู่แล้วในเครื่อง',
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
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

class _FeedImageSourceTile extends StatelessWidget {
  const _FeedImageSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    return Material(
      color: const Color(0xFFF4FAFF),
      borderRadius: BorderRadius.circular(scale.rs(22, min: 16, max: 22)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(scale.rs(22, min: 16, max: 22)),
        child: Padding(
          padding: EdgeInsets.all(scale.rs(16, min: 12, max: 16)),
          child: Row(
            children: [
              Container(
                width: scale.rs(46, min: 36, max: 46),
                height: scale.rs(46, min: 36, max: 46),
                decoration: BoxDecoration(
                  color: const Color(0xFF4489D7).withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(scale.rs(16, min: 12, max: 16)),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4489D7),
                  size: scale.rs(24, min: 20, max: 24),
                ),
              ),
              SizedBox(width: scale.rs(14, min: 10, max: 14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: scale.rf(16, min: 14, max: 16),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: scale.rs(4, min: 2, max: 4)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: scale.rf(13, min: 11.5, max: 13),
                        height: 1.35,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: scale.rs(12, min: 8, max: 12)),
              Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF4489D7),
                size: scale.rs(24, min: 20, max: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _LegacyFeedPostCard extends StatefulWidget {
  const _LegacyFeedPostCard({
    required this.post,
    required this.isLiked,
    required this.onToggleLike,
    required this.onAuthorTap,
  });

  final FeedPost post;
  final bool isLiked;
  final Future<void> Function()? onToggleLike;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onDelete = null;

  @override
  State<_LegacyFeedPostCard> createState() => _LegacyFeedPostCardState();
}

class _LegacyFeedPostCardState extends State<_LegacyFeedPostCard> {
  late bool _displayIsLiked;
  late int _displayLikeCount;
  bool _isUpdatingLike = false;

  String _formatRelativeTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'เมื่อสักครู่';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    }

    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year + 543;
    return '$day/$month/$year';
  }

  void _handleCommentTap() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentSheet(post: widget.post),
    );
  }

  @override
  void initState() {
    super.initState();
    _displayIsLiked = widget.isLiked;
    _displayLikeCount = widget.post.likeCount;
  }

  @override
  void didUpdateWidget(covariant _LegacyFeedPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked) {
      _displayIsLiked = widget.isLiked;
    }
    if (widget.post.likeCount != oldWidget.post.likeCount) {
      _displayLikeCount = widget.post.likeCount;
    }
  }

  Future<void> _handleToggleLike() async {
    final onToggleLike = widget.onToggleLike;
    if (onToggleLike == null || _isUpdatingLike) {
      return;
    }

    final previousIsLiked = _displayIsLiked;
    final previousLikeCount = _displayLikeCount;
    final nextIsLiked = !previousIsLiked;
    final nextLikeCount = nextIsLiked
        ? previousLikeCount + 1
        : (previousLikeCount > 0 ? previousLikeCount - 1 : 0);

    setState(() {
      _displayIsLiked = nextIsLiked;
      _displayLikeCount = nextLikeCount;
      _isUpdatingLike = true;
    });

    try {
      await onToggleLike();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _displayIsLiked = previousIsLiked;
        _displayLikeCount = previousLikeCount;
      });
    } finally {
      if (mounted) {
        setState(() => _isUpdatingLike = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: scale.rs(16, min: 12, max: 16),
        vertical: scale.rs(12, min: 8, max: 12),
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onAuthorTap,
                child: _AuthorAvatar(
                  name: widget.post.authorName,
                  avatarUrl: widget.post.authorAvatarUrl,
                  radius: scale.rs(20, min: 16, max: 20),
                ),
              ),
              SizedBox(width: scale.rs(10, min: 8, max: 10)),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onAuthorTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: scale.rf(16, min: 14, max: 16),
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: scale.rs(2, min: 2, max: 2)),
                      Text(
                        _formatRelativeTime(widget.post.createdAt),
                        style: TextStyle(
                          fontSize: scale.rf(12, min: 11, max: 12),
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.onDelete != null)
                PopupMenuButton<String>(
                  color: Colors.white,
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'delete') widget.onDelete?.call();
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
          if (widget.post.content.trim().isNotEmpty) ...[
            SizedBox(height: scale.rs(10, min: 8, max: 10)),
            Text(
              widget.post.content,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
          if ((widget.post.imageUrl ?? '').isNotEmpty) ...[
            SizedBox(height: scale.rs(12, min: 8, max: 12)),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxCardWidth = constraints.maxWidth;
                final imageWidth = maxCardWidth.clamp(180.0, 320.0);

                return Center(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(scale.rs(15, min: 12, max: 15)),
                    child: SizedBox(
                      width: imageWidth,
                      height: imageWidth * 1.2,
                      child: Image.network(
                        widget.post.imageUrl!,
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
                );
              },
            ),
          ],
          SizedBox(height: scale.rs(12, min: 8, max: 12)),
          Row(
            children: [
              InkWell(
                borderRadius:
                    BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
                onTap: _handleToggleLike,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale.rs(4, min: 2, max: 4),
                    vertical: scale.rs(4, min: 2, max: 4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _displayIsLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _displayIsLiked
                            ? const Color(0xFF4489D7)
                            : Colors.grey,
                        size: scale.rs(28, min: 24, max: 28),
                      ),
                      SizedBox(width: scale.rs(6, min: 4, max: 6)),
                      Text(
                        _displayLikeCount.toString(),
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: _displayIsLiked
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: scale.rs(14, min: 10, max: 14)),
              InkWell(
                borderRadius:
                    BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
                onTap: _handleCommentTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale.rs(4, min: 2, max: 4),
                    vertical: scale.rs(4, min: 2, max: 4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mode_comment_outlined,
                        color: Colors.grey,
                        size: scale.rs(26, min: 22, max: 26),
                      ),
                      SizedBox(width: scale.rs(6, min: 4, max: 6)),
                      Text(
                        widget.post.commentCount.toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _LegacyFeedHeader extends StatelessWidget {
  const _LegacyFeedHeader({
    required this.composerAvatarUrl,
    required this.isLoadingComposer,
    required this.onComposerTap,
    required this.onImageTap,
  });

  final String composerAvatarUrl;
  final bool isLoadingComposer;
  final VoidCallback onComposerTap;
  final VoidCallback onImageTap;

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: scale.rs(20, min: 14, max: 20),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: scale.rs(65, min: 52, max: 65),
              height: scale.rs(88, min: 70, max: 88),
            ),
          ),
        ),
        Divider(thickness: 1, color: Colors.grey.shade200),
        Material(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: scale.rs(16, min: 12, max: 16),
              vertical: scale.rs(10, min: 8, max: 10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(scale.rs(18, min: 14, max: 18)),
                    onTap: onComposerTap,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: scale.rs(4, min: 2, max: 4),
                        horizontal: scale.rs(2, min: 1, max: 2),
                      ),
                      child: Row(
                        children: [
                          _AuthorAvatar(
                            name: 'คุณ',
                            avatarUrl: composerAvatarUrl,
                            radius: scale.rs(20, min: 16, max: 20),
                          ),
                          SizedBox(width: scale.rs(15, min: 10, max: 15)),
                          Expanded(
                            child: Text(
                              isLoadingComposer
                                  ? 'กำลังโหลด...'
                                  : 'คุณกำลังคิดอะไรอยู่.....',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: scale.rf(16, min: 14, max: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: scale.rs(6, min: 4, max: 6)),
                InkWell(
                  borderRadius:
                      BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
                  onTap: onImageTap,
                  child: Padding(
                    padding: EdgeInsets.all(scale.rs(6, min: 4, max: 6)),
                    child: Image.asset(
                      'assets/images/Picture.png',
                      width: scale.rs(40, min: 32, max: 40),
                      height: scale.rs(35, min: 28, max: 35),
                      fit: BoxFit.contain,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(thickness: 1, color: Colors.grey.shade200),
      ],
    );
  }
}

class FeedPostCard extends StatefulWidget {
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
  final Future<void> Function()? onToggleLike;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onDelete;

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  static const _accent = Color(0xFF4489D7);
  static const _cardBorder = Color(0xFFDCEBFA);

  late bool _displayIsLiked;
  late int _displayLikeCount;
  bool _isUpdatingLike = false;
  bool _isSaved = false;

  String _formatRelativeTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'เมื่อสักครู่';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาที ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} ชม. ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} วัน ago';
    }

    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year + 543;
    return '$day/$month/$year';
  }

  void _handleCommentTap() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentSheet(post: widget.post),
    );
  }

  @override
  void initState() {
    super.initState();
    _displayIsLiked = widget.isLiked;
    _displayLikeCount = widget.post.likeCount;
  }

  @override
  void didUpdateWidget(covariant FeedPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked) {
      _displayIsLiked = widget.isLiked;
    }
    if (widget.post.likeCount != oldWidget.post.likeCount) {
      _displayLikeCount = widget.post.likeCount;
    }
  }

  Future<void> _handleToggleLike() async {
    final onToggleLike = widget.onToggleLike;
    if (onToggleLike == null || _isUpdatingLike) {
      return;
    }

    final previousIsLiked = _displayIsLiked;
    final previousLikeCount = _displayLikeCount;
    final nextIsLiked = !previousIsLiked;
    final nextLikeCount = nextIsLiked
        ? previousLikeCount + 1
        : (previousLikeCount > 0 ? previousLikeCount - 1 : 0);

    setState(() {
      _displayIsLiked = nextIsLiked;
      _displayLikeCount = nextLikeCount;
      _isUpdatingLike = true;
    });

    try {
      await onToggleLike();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _displayIsLiked = previousIsLiked;
        _displayLikeCount = previousLikeCount;
      });
    } finally {
      if (mounted) {
        setState(() => _isUpdatingLike = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    final tags = _buildTags(widget.post.content);
    final postBadge = _resolvePostBadge(widget.post.content);
    final handle = _buildHandle(widget.post.authorName);

    return Container(
      padding: EdgeInsets.fromLTRB(
        scale.rs(16, min: 12, max: 16),
        scale.rs(14, min: 10, max: 14),
        scale.rs(16, min: 12, max: 16),
        scale.rs(12, min: 10, max: 12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scale.rs(22, min: 18, max: 22)),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onAuthorTap,
                child: _AuthorAvatar(
                  name: widget.post.authorName,
                  avatarUrl: widget.post.authorAvatarUrl,
                  radius: scale.rs(22, min: 18, max: 22),
                ),
              ),
              SizedBox(width: scale.rs(10, min: 8, max: 10)),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onAuthorTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: scale.rf(16, min: 14, max: 16),
                          color: const Color(0xFF2C5282),
                        ),
                      ),
                      SizedBox(height: scale.rs(4, min: 2, max: 4)),
                      Wrap(
                        spacing: scale.rs(6, min: 4, max: 6),
                        runSpacing: scale.rs(4, min: 4, max: 4),
                        children: [
                          Text(
                            handle,
                            style: TextStyle(
                              fontSize: scale.rf(12.5, min: 11.5, max: 12.5),
                              color: const Color(0xFF6A7489),
                            ),
                          ),
                          Text(
                            _formatRelativeTime(widget.post.createdAt),
                            style: TextStyle(
                              fontSize: scale.rf(12.5, min: 11.5, max: 12.5),
                              color: const Color(0xFF6A7489),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: scale.rs(8, min: 6, max: 8),
                              vertical: scale.rs(3, min: 2, max: 3),
                            ),
                            decoration: BoxDecoration(
                              color: postBadge.backgroundColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              postBadge.label,
                              style: TextStyle(
                                fontSize: scale.rf(11, min: 10, max: 11),
                                fontWeight: FontWeight.w700,
                                color: postBadge.foregroundColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.onDelete != null)
                PopupMenuButton<String>(
                  color: Colors.white,
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Color(0xFF97A0B5),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') widget.onDelete?.call();
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
          if (widget.post.content.trim().isNotEmpty) ...[
            SizedBox(height: scale.rs(14, min: 10, max: 14)),
            Text(
              widget.post.content,
              style: TextStyle(
                color: const Color(0xFF42506A),
                height: 1.6,
                fontSize: scale.rf(14.5, min: 13, max: 14.5),
              ),
            ),
          ],
          if ((widget.post.imageUrl ?? '').isNotEmpty) ...[
            SizedBox(height: scale.rs(14, min: 10, max: 14)),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxCardWidth = constraints.maxWidth;
                final imageWidth = maxCardWidth.clamp(220.0, 420.0);

                return Center(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(scale.rs(18, min: 14, max: 18)),
                    child: SizedBox(
                      width: imageWidth,
                      height: imageWidth * 0.78,
                      child: Image.network(
                        widget.post.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFF0F3F8),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF97A0B5),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          if (tags.isNotEmpty) ...[
            SizedBox(height: scale.rs(14, min: 10, max: 14)),
            Wrap(
              spacing: scale.rs(8, min: 6, max: 8),
              runSpacing: scale.rs(8, min: 6, max: 8),
              children: tags
                  .map(
                    (tag) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: scale.rs(10, min: 8, max: 10),
                        vertical: scale.rs(6, min: 4, max: 6),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF7FF),
                        borderRadius: BorderRadius.circular(
                            scale.rs(10, min: 8, max: 10)),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: const Color(0xFF627089),
                          fontSize: scale.rf(12, min: 11, max: 12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          SizedBox(height: scale.rs(16, min: 12, max: 16)),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
          SizedBox(height: scale.rs(12, min: 8, max: 12)),
          Row(
            children: [
              InkWell(
                borderRadius:
                    BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
                onTap: _handleToggleLike,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale.rs(4, min: 2, max: 4),
                    vertical: scale.rs(4, min: 2, max: 4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _displayIsLiked
                            ? Icons.favorite
                            : Icons.favorite_border_rounded,
                        color:
                            _displayIsLiked ? _accent : const Color(0xFF6A7489),
                        size: scale.rs(24, min: 22, max: 24),
                      ),
                      SizedBox(width: scale.rs(6, min: 4, max: 6)),
                      Text(
                        _displayLikeCount.toString(),
                        style: TextStyle(
                          color: const Color(0xFF42506A),
                          fontWeight: _displayIsLiked
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: scale.rs(18, min: 12, max: 18)),
              InkWell(
                borderRadius:
                    BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
                onTap: _handleCommentTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale.rs(4, min: 2, max: 4),
                    vertical: scale.rs(4, min: 2, max: 4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mode_comment_outlined,
                        color: const Color(0xFF6A7489),
                        size: scale.rs(24, min: 22, max: 24),
                      ),
                      SizedBox(width: scale.rs(6, min: 4, max: 6)),
                      Text(
                        widget.post.commentCount.toString(),
                        style: const TextStyle(
                          color: Color(0xFF42506A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _isSaved = !_isSaved),
                child: Container(
                  width: scale.rs(34, min: 30, max: 34),
                  height: scale.rs(34, min: 30, max: 34),
                  decoration: BoxDecoration(
                    color: _isSaved
                        ? _accent.withValues(alpha: 0.12)
                        : const Color(0xFFF3F5FA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: _isSaved ? _accent : const Color(0xFF7B859B),
                    size: scale.rs(20, min: 18, max: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _buildTags(String content) {
    final matches = RegExp(r'#([\p{L}\p{N}_]+)', unicode: true)
        .allMatches(content)
        .map((match) => '#${match.group(1)}')
        .where((tag) => tag.length > 1)
        .toSet()
        .take(3)
        .toList();
    if (matches.isNotEmpty) {
      return matches;
    }

    return content
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .map((word) => word.trim())
        .where((word) => word.length >= 4)
        .take(3)
        .map((word) => '#$word')
        .toList();
  }

  _PostBadge _resolvePostBadge(String content) {
    final normalized = content.toLowerCase();
    if (normalized.contains('?') || normalized.contains('ทำไม')) {
      return const _PostBadge(
        label: 'คำถาม',
        backgroundColor: Color(0xFFE9F1FF),
        foregroundColor: Color(0xFF4166D5),
      );
    }
    if (normalized.contains('เหงา') ||
        normalized.contains('เหนื่อย') ||
        normalized.contains('เศร้า')) {
      return const _PostBadge(
        label: 'ขอกำลังใจ',
        backgroundColor: Color(0xFFFFECEC),
        foregroundColor: Color(0xFFE35D6A),
      );
    }
    if (normalized.contains('รู้สึก') ||
        normalized.contains('happy') ||
        normalized.contains('sad')) {
      return const _PostBadge(
        label: 'อารมณ์',
        backgroundColor: Color(0xFFEAFBF3),
        foregroundColor: Color(0xFF1E9E63),
      );
    }

    return const _PostBadge(
      label: 'ทั่วไป',
      backgroundColor: Color(0xFFEFF7FF),
      foregroundColor: Color(0xFF4489D7),
    );
  }

  String _buildHandle(String authorName) {
    final compact = authorName.trim().replaceAll(RegExp(r'\s+'), '_');
    if (compact.isEmpty) {
      return '@member';
    }
    return '@${compact.toLowerCase()}';
  }
}

class _PostBadge {
  const _PostBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.composerAvatarUrl,
    required this.composerName,
    required this.isLoadingComposer,
    required this.onComposerTap,
    required this.onImageTap,
  });

  final String composerAvatarUrl;
  final String composerName;
  final bool isLoadingComposer;
  final VoidCallback onComposerTap;
  final VoidCallback onImageTap;

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    final cardRadius = scale.rs(22, min: 18, max: 22);
    const appBlue = Color(0xFF4489D7);
    const appLightBlue = Color(0xFFEEF8FF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: scale.rs(10, min: 8, max: 10),
            bottom: scale.rs(14, min: 10, max: 14),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: scale.rs(65, min: 52, max: 65),
              height: scale.rs(88, min: 70, max: 88),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(scale.rs(14, min: 12, max: 14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: const Color(0xFFDCEBFA)),
            boxShadow: [
              BoxShadow(
                color: appBlue.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            onTap: onComposerTap,
            borderRadius: BorderRadius.circular(cardRadius - 4),
            child: Row(
              children: [
                _AuthorAvatar(
                  name: composerName,
                  avatarUrl: composerAvatarUrl,
                  radius: scale.rs(20, min: 18, max: 20),
                ),
                SizedBox(width: scale.rs(12, min: 10, max: 12)),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: scale.rs(16, min: 12, max: 16),
                      vertical: scale.rs(12, min: 10, max: 12),
                    ),
                    decoration: BoxDecoration(
                      color: appLightBlue,
                      borderRadius: BorderRadius.circular(
                        scale.rs(16, min: 14, max: 16),
                      ),
                    ),
                    child: Text(
                      isLoadingComposer
                          ? 'Loading profile...'
                          : 'แชร์สิ่งที่คุณกำลังรู้สึก...',
                      style: TextStyle(
                        color: const Color(0xFF6D8FB5),
                        fontSize: scale.rf(15, min: 13.5, max: 15),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: scale.rs(10, min: 8, max: 10)),
                InkWell(
                  onTap: onImageTap,
                  borderRadius:
                      BorderRadius.circular(scale.rs(14, min: 12, max: 14)),
                  child: Container(
                    padding: EdgeInsets.all(scale.rs(10, min: 8, max: 10)),
                    decoration: BoxDecoration(
                      color: appLightBlue,
                      borderRadius: BorderRadius.circular(
                        scale.rs(14, min: 12, max: 14),
                      ),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      color: appBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentSheet extends StatefulWidget {
  const _CommentSheet({required this.post});

  final FeedPost post;

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final FeedRepository _repository = FeedRepository();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  String _formatCommentTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'เมื่อสักครู่';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    }

    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year + 543;
    return '$day/$month/$year';
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final comment = _controller.text.trim();
    if (comment.isEmpty || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _repository.createComment(
        postId: widget.post.id,
        content: comment,
      );
      if (!mounted) return;
      _controller.clear();
      _focusNode.requestFocus();
      setState(() {});
    } on ContentModerationBlockedException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.reason.toLowerCase().contains('moderation-blocked')
                ? 'ไม่สามารถส่งความคิดเห็นนี้ได้ เนื่องจากระบบตรวจพบเนื้อหาที่ไม่เหมาะสม'
                : error.reason,
          ),
          backgroundColor: Colors.red,
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งความคิดเห็นไม่สำเร็จ: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canSubmit = _controller.text.trim().isNotEmpty && !_isSubmitting;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.78,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(scale.rs(22, min: 18, max: 22)),
          ),
          child: Material(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    width: scale.rs(44, min: 36, max: 44),
                    height: scale.rs(5, min: 4, max: 5),
                    margin: EdgeInsets.only(
                      top: scale.rs(12, min: 10, max: 12),
                      bottom: scale.rs(14, min: 10, max: 14),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: scale.rs(16, min: 12, max: 16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'ความคิดเห็น',
                          style: TextStyle(
                            fontSize: scale.rf(18, min: 16, max: 18),
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const Spacer(),
                        StreamBuilder<List<FeedComment>>(
                          stream:
                              _repository.watchCommentsByPost(widget.post.id),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.length ??
                                widget.post.commentCount;
                            return Text(
                              '$count รายการ',
                              style: TextStyle(
                                fontSize: scale.rf(13, min: 12, max: 13),
                                color: Colors.grey.shade500,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: scale.rs(14, min: 10, max: 14)),
                  Divider(height: 1, color: Colors.grey.shade200),
                  Expanded(
                    child: _CommentLiveSection(
                      repository: _repository,
                      post: widget.post,
                      formatTime: _formatCommentTime,
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      scale.rs(16, min: 12, max: 16),
                      scale.rs(12, min: 10, max: 12),
                      scale.rs(16, min: 12, max: 16),
                      scale.rs(12, min: 10, max: 12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            minLines: 1,
                            maxLines: 4,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.send,
                            onSubmitted:
                                canSubmit ? (_) => _submitComment() : null,
                            decoration: InputDecoration(
                              hintText: 'เขียนความคิดเห็น...',
                              filled: true,
                              fillColor: const Color(0xFFF7F9FC),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: scale.rs(14, min: 12, max: 14),
                                vertical: scale.rs(12, min: 10, max: 12),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  scale.rs(18, min: 14, max: 18),
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: scale.rs(10, min: 8, max: 10)),
                        FilledButton(
                          onPressed: canSubmit ? _submitComment : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4489D7),
                            padding: EdgeInsets.symmetric(
                              horizontal: scale.rs(16, min: 14, max: 16),
                              vertical: scale.rs(14, min: 12, max: 14),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: scale.rs(16, min: 14, max: 16),
                                  height: scale.rs(16, min: 14, max: 16),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('ส่ง'),
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

class _CommentLiveSection extends StatelessWidget {
  const _CommentLiveSection({
    required this.repository,
    required this.post,
    required this.formatTime,
  });

  final FeedRepository repository;
  final FeedPost post;
  final String Function(DateTime createdAt) formatTime;

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    return StreamBuilder<List<FeedComment>>(
      stream: repository.watchCommentsByPost(post.id),
      builder: (context, snapshot) {
        final comments = snapshot.data ?? const <FeedComment>[];

        return ListView(
          padding: EdgeInsets.fromLTRB(
            scale.rs(16, min: 12, max: 16),
            scale.rs(16, min: 12, max: 16),
            scale.rs(16, min: 12, max: 16),
            scale.rs(12, min: 8, max: 12),
          ),
          children: [
            Container(
              padding: EdgeInsets.all(scale.rs(14, min: 12, max: 14)),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(
                  scale.rs(16, min: 12, max: 16),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AuthorAvatar(
                    name: post.authorName,
                    avatarUrl: post.authorAvatarUrl,
                    radius: scale.rs(18, min: 16, max: 18),
                  ),
                  SizedBox(width: scale.rs(10, min: 8, max: 10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: scale.rf(14, min: 13, max: 14),
                            color: Colors.grey.shade800,
                          ),
                        ),
                        if (post.content.trim().isNotEmpty) ...[
                          SizedBox(height: scale.rs(6, min: 4, max: 6)),
                          Text(
                            post.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: scale.rs(20, min: 16, max: 20)),
            if (snapshot.hasError)
              SizedBox(
                height: scale.rs(220, min: 180, max: 220),
                child: _FeedMessageState(
                  icon: Icons.cloud_off_rounded,
                  title: 'โหลดคอมเมนต์ไม่สำเร็จ',
                  subtitle: '${snapshot.error}',
                ),
              )
            else if (!snapshot.hasData)
              Padding(
                padding: EdgeInsets.only(top: scale.rs(20, min: 16, max: 20)),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (comments.isEmpty)
              SizedBox(
                height: scale.rs(260, min: 220, max: 260),
                child: _FeedMessageState(
                  icon: Icons.mode_comment_outlined,
                  title: 'ยังไม่มีคอมเมนต์',
                  subtitle: 'เริ่มบทสนทนาแรกใต้โพสต์นี้ได้เลย',
                ),
              )
            else
              ...comments.map(
                (comment) => Padding(
                  padding: EdgeInsets.only(
                    bottom: scale.rs(12, min: 10, max: 12),
                  ),
                  child: _CommentCard(
                    comment: comment,
                    timeText: formatTime(comment.createdAt),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.timeText,
  });

  final FeedComment comment;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    return Container(
      padding: EdgeInsets.all(scale.rs(12, min: 10, max: 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scale.rs(14, min: 12, max: 14)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorAvatar(
            name: comment.authorName,
            avatarUrl: comment.authorAvatarUrl,
            radius: scale.rs(17, min: 15, max: 17),
          ),
          SizedBox(width: scale.rs(10, min: 8, max: 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: scale.rf(13.5, min: 12.5, max: 13.5),
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: scale.rf(11.5, min: 11, max: 11.5),
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: scale.rs(6, min: 4, max: 6)),
                Text(
                  comment.content,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.4,
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

class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState({required this.onCreatePost});

  final VoidCallback onCreatePost;

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    return Column(
      children: [
        Icon(
          Icons.forum_outlined,
          size: scale.rs(44, min: 34, max: 44),
          color: Colors.grey.shade400,
        ),
        SizedBox(height: scale.rs(12, min: 8, max: 12)),
        Text(
          'ยังไม่มีโพสต์ในชุมชน',
          style: TextStyle(
            fontSize: scale.rf(18, min: 15.5, max: 18),
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: scale.rs(8, min: 6, max: 8)),
        Text(
          'เริ่มโพสต์แรกเพื่อให้ feed นี้เริ่มใช้งานได้จริง',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            height: 1.5,
            fontSize: scale.rf(14, min: 12, max: 14),
          ),
        ),
        SizedBox(height: scale.rs(18, min: 12, max: 18)),
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
    final scale = context.responsive;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(scale.rs(24, min: 16, max: 24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: scale.rs(48, min: 38, max: 48),
                color: Colors.grey.shade400),
            SizedBox(height: scale.rs(12, min: 8, max: 12)),
            Text(
              title,
              style: TextStyle(
                fontSize: scale.rf(18, min: 15.5, max: 18),
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: scale.rs(8, min: 6, max: 8)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.5,
                fontSize: scale.rf(14, min: 12, max: 14),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: scale.rs(18, min: 12, max: 18)),
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
    final scale = context.responsive;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        scale.rs(24, min: 16, max: 24),
        scale.rs(20, min: 14, max: 20),
        scale.rs(24, min: 16, max: 24),
        scale.rs(20, min: 14, max: 20),
      ),
      child: Column(
        children: [
          _AuthorAvatar(
            name: authorName,
            avatarUrl: authorAvatarUrl,
            radius: scale.rs(50, min: 40, max: 50),
          ),
          SizedBox(height: scale.rs(10, min: 8, max: 10)),
          Text(
            authorName,
            style: TextStyle(
              fontSize: scale.rf(24, min: 20, max: 24),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: scale.rs(8, min: 6, max: 8)),
          Text(
            '$postCount โพสต์ • $totalLikes ถูกใจ',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: scale.rf(13, min: 11.5, max: 13),
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

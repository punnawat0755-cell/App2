import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/core/services/content_moderation_service.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:flutter_application_1/features/feed/model/feed_post.dart';
import 'package:flutter_application_1/features/feed/service/feed_repository.dart';
import 'package:flutter_application_1/features/feed/view/feed_photo_capture_page.dart';
import 'package:flutter_application_1/features/profile/model/profile_avatar_catalog.dart';
import 'package:image_picker/image_picker.dart';
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
            final maxContentWidth =
                constraints.maxWidth > 620 ? 620.0 : constraints.maxWidth;

            return Center(
              child: SizedBox(
                width: maxContentWidth,
                child: Column(
                  children: [
                    _FeedHeader(
                      composerAvatarUrl: _composerAvatarUrl,
                      isLoadingComposer: _isLoadingComposer,
                      onComposerTap: () => _openComposer(),
                      onImageTap: () =>
                          _openComposer(openImagePickerOnOpen: true),
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
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          return StreamBuilder<Set<String>>(
                            stream:
                                _repository.watchLikedPostIds(currentUser.id),
                            builder: (context, likeSnapshot) {
                              final likedPostIds =
                                  likeSnapshot.data ?? const <String>{};
                              final posts =
                                  postSnapshot.data ?? const <FeedPost>[];

                              if (posts.isEmpty) {
                                return RefreshIndicator(
                                  onRefresh: _refreshFeed,
                                  child: ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.fromLTRB(
                                      scale.rs(24, min: 16, max: 24),
                                      scale.rs(48, min: 30, max: 48),
                                      scale.rs(24, min: 16, max: 24),
                                      scale.rs(120, min: 90, max: 120),
                                    ),
                                    children: [
                                      _FeedEmptyState(
                                        onCreatePost: () => _openComposer(),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return RefreshIndicator(
                                onRefresh: _refreshFeed,
                                child: ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.only(
                                    bottom: scale.rs(120, min: 90, max: 120),
                                  ),
                                  itemCount: posts.length,
                                  separatorBuilder: (context, index) => Divider(
                                    thickness: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                  itemBuilder: (context, index) {
                                    final post = posts[index];
                                    final isLiked =
                                        likedPostIds.contains(post.id);

                                    return FeedPostCard(
                                      key: ValueKey(post.id),
                                      post: post,
                                      isLiked: isLiked,
                                      onAuthorTap: () =>
                                          _openAuthorProfile(post),
                                      onToggleLike:
                                          _repository.supportsLikeActions
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
          },
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
      rethrow;
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
          final maxContentWidth =
              constraints.maxWidth > 620 ? 620.0 : constraints.maxWidth;

          return Center(
            child: SizedBox(
              width: maxContentWidth,
              child: StreamBuilder<List<FeedPost>>(
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
                        SizedBox(height: scale.rs(32, min: 22, max: 32)),
                        SizedBox(
                          height: scale.rs(280, min: 220, max: 280),
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
                      final likedPostIds =
                          likeSnapshot.data ?? const <String>{};
                      final totalLikes = posts.fold<int>(
                          0, (sum, post) => sum + post.likeCount);
                      final resolvedAuthorAvatarUrl = posts.isNotEmpty
                          ? posts.first.authorAvatarUrl
                          : authorAvatarUrl;

                      return RefreshIndicator(
                        onRefresh: _refreshProfile,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: scale.rs(32, min: 24, max: 32),
                          ),
                          itemCount: posts.isEmpty ? 2 : posts.length + 1,
                          separatorBuilder: (context, index) => Divider(
                              thickness: 1, color: Colors.grey.shade200),
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
                              return SizedBox(
                                height: scale.rs(280, min: 220, max: 280),
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
                              key: ValueKey(post.id),
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

  Future<void> _submit() async {
    final content = _controller.text.trim();
    final hasSelectedImage =
        _selectedImageBytes != null && _selectedImageBytes!.isNotEmpty;
    if ((content.isEmpty && !hasSelectedImage) || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
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
  late bool _displayIsLiked;
  late int _displayLikeCount;
  bool _isUpdatingLike = false;

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
                  child: Text(
                    widget.post.authorName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: scale.rf(16, min: 14, max: 16),
                      color: Colors.grey,
                    ),
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
          SizedBox(height: scale.rs(10, min: 8, max: 10)),
          GestureDetector(
            onTap: _handleToggleLike,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _displayIsLiked ? Icons.favorite : Icons.favorite_border,
                  color:
                      _displayIsLiked ? const Color(0xFF4489D7) : Colors.grey,
                  size: scale.rs(32, min: 26, max: 32),
                ),
                SizedBox(width: scale.rs(6, min: 4, max: 6)),
                Text(
                  _displayLikeCount.toString(),
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight:
                        _displayIsLiked ? FontWeight.bold : FontWeight.normal,
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

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/model/home_video_clip.dart';
import 'package:flutter_application_1/features/home/service/home_video_prefetch_service.dart';
import 'package:video_player/video_player.dart';

class PlayVideoPage extends StatefulWidget {
  const PlayVideoPage({
    super.key,
    required this.clips,
    required this.initialIndex,
  });

  final List<HomeVideoClip> clips;
  final int initialIndex;

  @override
  State<PlayVideoPage> createState() => _PlayVideoPageState();
}

class _PlayVideoPageState extends State<PlayVideoPage>
    with WidgetsBindingObserver {
  final HomeVideoPrefetchService _prefetchService =
      HomeVideoPrefetchService.instance;

  late final PageController _pageController;
  late int _currentIndex;

  VideoPlayerController? _controller;
  bool _isPreparingVideo = true;
  bool _showManualPlayOverlay = false;
  bool _resumePlaybackOnForeground = false;
  String? _playbackError;
  String? _resolvedVideoPath;
  int _playRequestToken = 0;

  HomeVideoClip get _currentClip => widget.clips[_currentIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex.clamp(0, widget.clips.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    unawaited(_prefetchService.warmUpClips(_clipsAround(_currentIndex)));
    unawaited(_activateClipAt(_currentIndex));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _resumePlaybackIfNeeded();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _pauseForBackground();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  List<HomeVideoClip> _clipsAround(int index) {
    final nearbyClips = <HomeVideoClip>[];
    if (index >= 0 && index < widget.clips.length) {
      nearbyClips.add(widget.clips[index]);
    }
    if (index + 1 < widget.clips.length) {
      nearbyClips.add(widget.clips[index + 1]);
    }
    if (index - 1 >= 0) {
      nearbyClips.add(widget.clips[index - 1]);
    }
    return nearbyClips;
  }

  Future<void> _activateClipAt(int index) async {
    final requestToken = ++_playRequestToken;
    final clip = widget.clips[index];

    setState(() {
      _isPreparingVideo = true;
      _playbackError = null;
      _showManualPlayOverlay = false;
      _resolvedVideoPath = null;
    });

    await _disposeController();
    if (!mounted || requestToken != _playRequestToken) {
      return;
    }

    try {
      final preferredPath = await _prefetchService.resolvePlayablePath(
        clip.videoUrl,
      );
      if (!mounted || requestToken != _playRequestToken) {
        return;
      }

      final controller = await _initializeControllerWithFallback(
        preferredPath: preferredPath,
        remotePath: clip.videoUrl,
      );
      if (!mounted || requestToken != _playRequestToken) {
        await controller.dispose();
        return;
      }

      controller.addListener(_handleControllerUpdate);
      await controller.setLooping(true);
      await controller.play();
      if (!mounted || requestToken != _playRequestToken) {
        controller.removeListener(_handleControllerUpdate);
        await controller.dispose();
        return;
      }

      _controller = controller;
      setState(() {
        _resolvedVideoPath = controller.dataSource.trim().isNotEmpty
            ? controller.dataSource.trim()
            : preferredPath;
        _isPreparingVideo = false;
        _showManualPlayOverlay = false;
      });
    } catch (error) {
      debugPrint(
        'Failed to initialize clip ${clip.id} from ${clip.videoUrl}: $error',
      );
      if (!mounted || requestToken != _playRequestToken) {
        return;
      }

      setState(() {
        _isPreparingVideo = false;
        _playbackError = _friendlyPlaybackError(error);
      });
    }
  }

  Future<VideoPlayerController> _initializeControllerWithFallback({
    required String preferredPath,
    required String remotePath,
  }) async {
    try {
      return await _createInitializedController(preferredPath);
    } catch (error) {
      final normalizedPreferredPath = preferredPath.trim();
      final normalizedRemotePath = remotePath.trim();
      if (normalizedPreferredPath == normalizedRemotePath) {
        rethrow;
      }

      debugPrint(
        'Falling back to remote video after local warmup failed: $error',
      );
      return _createInitializedController(normalizedRemotePath);
    }
  }

  Future<VideoPlayerController> _createInitializedController(
    String sourcePath,
  ) async {
    final controller = sourcePath.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(sourcePath))
        : VideoPlayerController.file(File(sourcePath));

    try {
      await controller.initialize();
      return controller;
    } catch (_) {
      await controller.dispose();
      rethrow;
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    _controller = null;
    controller.removeListener(_handleControllerUpdate);
    try {
      await controller.pause();
    } catch (_) {
      // Ignore pause failures while tearing down the player.
    }
    await controller.dispose();
  }

  void _handleControllerUpdate() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
      if (!mounted) {
        return;
      }
      setState(() {
        _showManualPlayOverlay = true;
      });
      return;
    }

    await controller.play();
    if (!mounted) {
      return;
    }
    setState(() {
      _showManualPlayOverlay = false;
    });
  }

  void _pauseForBackground() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    _resumePlaybackOnForeground = controller.value.isPlaying;
    if (_resumePlaybackOnForeground) {
      unawaited(controller.pause());
    }
  }

  void _resumePlaybackIfNeeded() {
    final controller = _controller;
    if (!_resumePlaybackOnForeground ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    _resumePlaybackOnForeground = false;
    unawaited(
      controller.play().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _showManualPlayOverlay = false;
        });
      }),
    );
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _showManualPlayOverlay = false;
      _playbackError = null;
    });
    unawaited(_prefetchService.warmUpClips(_clipsAround(index)));
    unawaited(_activateClipAt(index));
  }

  String _friendlyPlaybackError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('403') ||
        message.contains('401') ||
        message.contains('404') ||
        message.contains('source error') ||
        message.contains('unable to connect')) {
      return 'โหลดวิดีโอจาก Supabase ไม่สำเร็จ';
    }

    if (message.contains('format') ||
        message.contains('codec') ||
        message.contains('parser') ||
        message.contains('unsupported') ||
        message.contains('mediacodecvideo')) {
      return 'ไฟล์วิดีโอนี้ยังไม่รองรับบนเครื่องนี้';
    }

    return 'ไม่สามารถโหลดวิดีโอได้ในตอนนี้';
  }

  String _previewPathFor(HomeVideoClip clip) {
    final thumbnailPath = clip.thumbnailUrl?.trim() ?? '';
    if (thumbnailPath.isNotEmpty) {
      return thumbnailPath;
    }
    if (clip.id == _currentClip.id &&
        (_resolvedVideoPath?.trim().isNotEmpty ?? false)) {
      return _resolvedVideoPath!.trim();
    }
    return clip.videoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final totalClips = widget.clips.length;
    final controller = _controller;
    final isReady = !_isPreparingVideo &&
        controller != null &&
        controller.value.isInitialized;
    final isBuffering = controller != null &&
        controller.value.isInitialized &&
        controller.value.isBuffering;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: totalClips,
            onPageChanged: _handlePageChanged,
            itemBuilder: (context, index) {
              final clip = widget.clips[index];
              final isCurrent = index == _currentIndex;

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (isCurrent && isReady)
                    GestureDetector(
                      onTap: _togglePlayback,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      ),
                    )
                  else if (isCurrent)
                    _VideoLoadingPreview(
                      thumbnailPath: _previewPathFor(clip),
                      errorText: _playbackError,
                      onRetry: _playbackError == null
                          ? null
                          : () => _activateClipAt(_currentIndex),
                    )
                  else
                    _ClipBackdrop(previewPath: _previewPathFor(clip)),
                  if (isCurrent && isReady && isBuffering)
                    const _PlaybackLoadingOverlay(),
                  if (isCurrent && isReady && _showManualPlayOverlay)
                    const Center(
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.play_arrow,
                          size: 45,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 42,
                    child: _ClipMeta(
                      clip: clip,
                      showSwipeHint: isCurrent,
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/$totalClips',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClipBackdrop extends StatelessWidget {
  const _ClipBackdrop({required this.previewPath});

  final String previewPath;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _ClipPreviewImage(path: previewPath),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ClipMeta extends StatelessWidget {
  const _ClipMeta({
    required this.clip,
    required this.showSwipeHint,
  });

  final HomeVideoClip clip;
  final bool showSwipeHint;

  @override
  Widget build(BuildContext context) {
    final caption = clip.caption.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          clip.authorName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            caption,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (showSwipeHint) ...[
          const SizedBox(height: 14),
          Text(
            'เลื่อนขึ้นหรือลงเพื่อดูคลิปต่อไป',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _VideoLoadingPreview extends StatelessWidget {
  const _VideoLoadingPreview({
    this.thumbnailPath,
    this.errorText,
    this.onRetry,
  });

  final String? thumbnailPath;
  final String? errorText;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final path = thumbnailPath?.trim() ?? '';
    final hasError = errorText != null && errorText!.trim().isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        _ClipBackdrop(previewPath: path),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasError)
                  const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  hasError ? errorText! : 'กำลังเตรียมวิดีโอ...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasError
                      ? 'ลองโหลดใหม่อีกครั้งได้เลย'
                      : 'กำลังโหลดคลิปจาก Supabase และเตรียมให้เล่นอัตโนมัติ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                if (hasError && onRetry != null) ...[
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ClipPreviewImage extends StatelessWidget {
  const _ClipPreviewImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return Container(color: Colors.black);
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.black),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.black),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: Colors.black),
    );
  }
}

class _PlaybackLoadingOverlay extends StatelessWidget {
  const _PlaybackLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.18),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

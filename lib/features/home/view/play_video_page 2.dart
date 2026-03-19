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

class _PlayVideoPageState extends State<PlayVideoPage> {
  final HomeVideoPrefetchService _prefetchService =
      HomeVideoPrefetchService.instance;

  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.clips.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    unawaited(_prefetchService.warmUpClips(_clipsAround(_currentIndex)));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  void _handlePageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    unawaited(_prefetchService.warmUpClips(_clipsAround(index)));
  }

  @override
  Widget build(BuildContext context) {
    final totalClips = widget.clips.length;

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
              return _PlayableClipView(
                key: ValueKey(clip.id),
                clip: clip,
                isActive: index == _currentIndex,
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

class _PlayableClipView extends StatefulWidget {
  const _PlayableClipView({
    super.key,
    required this.clip,
    required this.isActive,
  });

  final HomeVideoClip clip;
  final bool isActive;

  @override
  State<_PlayableClipView> createState() => _PlayableClipViewState();
}

class _PlayableClipViewState extends State<_PlayableClipView>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final HomeVideoPrefetchService _prefetchService =
      HomeVideoPrefetchService.instance;

  VideoPlayerController? _controller;
  bool _isPreparingVideo = false;
  bool _showManualPlayOverlay = false;
  bool _resumePlaybackOnForeground = false;
  String? _playbackError;
  String? _resolvedVideoPath;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) {
      unawaited(_prepareAndPlayVideo());
    }
  }

  @override
  void didUpdateWidget(covariant _PlayableClipView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !oldWidget.isActive) {
      if (_controller != null && _controller!.value.isInitialized) {
        unawaited(_playController());
      } else {
        unawaited(_prepareAndPlayVideo());
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      _pauseBecauseInactive();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_handleControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive) {
      return;
    }

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

  Future<void> _prepareAndPlayVideo() async {
    if (!widget.isActive || _isPreparingVideo) {
      return;
    }

    setState(() {
      _isPreparingVideo = true;
      _playbackError = null;
      _showManualPlayOverlay = false;
    });

    VideoPlayerController? nextController;
    try {
      final resolvedPath = await _prefetchService.resolvePlayablePath(
        widget.clip.videoUrl,
      );
      if (!mounted) {
        return;
      }
      if (!widget.isActive) {
        setState(() {
          _isPreparingVideo = false;
        });
        return;
      }

      nextController = await _initializeControllerWithFallback(resolvedPath);

      if (!mounted || !widget.isActive) {
        nextController.removeListener(_handleControllerUpdate);
        nextController.dispose();
        if (mounted) {
          setState(() {
            _isPreparingVideo = false;
          });
        }
        return;
      }

      await nextController.setLooping(true);
      await nextController.play();

      _controller?.removeListener(_handleControllerUpdate);
      _controller?.dispose();
      _controller = nextController;

      setState(() {
        _resolvedVideoPath = _controllerSourcePath(nextController!);
        _isPreparingVideo = false;
        _showManualPlayOverlay = false;
      });
    } catch (error) {
      nextController?.removeListener(_handleControllerUpdate);
      nextController?.dispose();
      if (!mounted) {
        return;
      }

      debugPrint(
        'Failed to initialize clip ${widget.clip.id} from ${widget.clip.videoUrl}: $error',
      );

      setState(() {
        _isPreparingVideo = false;
        _playbackError = _friendlyPlaybackError(error);
      });
    }
  }

  Future<VideoPlayerController> _initializeControllerWithFallback(
    String preferredPath,
  ) async {
    try {
      return await _createInitializedController(preferredPath);
    } catch (error) {
      final normalizedPreferredPath = preferredPath.trim();
      final normalizedRemotePath = widget.clip.videoUrl.trim();
      if (normalizedPreferredPath == normalizedRemotePath) {
        rethrow;
      }

      debugPrint(
        'Falling back to remote video for ${widget.clip.id} after local warmup failed: $error',
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
    controller.addListener(_handleControllerUpdate);

    try {
      await controller.initialize();
      return controller;
    } catch (_) {
      controller.removeListener(_handleControllerUpdate);
      await controller.dispose();
      rethrow;
    }
  }

  String _controllerSourcePath(VideoPlayerController controller) {
    final dataSource = controller.dataSource.trim();
    if (dataSource.isNotEmpty) {
      return dataSource;
    }
    return _resolvedVideoPath ?? widget.clip.videoUrl;
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

  void _handleControllerUpdate() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _playController() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
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

    await _playController();
  }

  void _pauseBecauseInactive() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    _resumePlaybackOnForeground = false;
    if (controller.value.isPlaying) {
      unawaited(controller.pause());
    }
    if (mounted) {
      setState(() {
        _showManualPlayOverlay = false;
      });
    }
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
    if (!widget.isActive ||
        !_resumePlaybackOnForeground ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    _resumePlaybackOnForeground = false;
    unawaited(_playController());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final caption = widget.clip.caption.trim();
    final controller = _controller;
    final isReady = !_isPreparingVideo &&
        controller != null &&
        controller.value.isInitialized;
    final isBuffering = controller != null &&
        controller.value.isInitialized &&
        controller.value.isBuffering;
    final previewPath = widget.clip.thumbnailUrl?.trim().isNotEmpty ?? false
        ? widget.clip.thumbnailUrl!
        : _resolvedVideoPath ?? widget.clip.videoUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isReady)
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
        else
          _VideoLoadingPreview(
            thumbnailPath: previewPath,
            errorText: _playbackError,
            onRetry: _playbackError == null ? null : _prepareAndPlayVideo,
          ),
        if (isReady && isBuffering) const _PlaybackLoadingOverlay(),
        if (isReady && _showManualPlayOverlay)
          const Center(
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Icon(Icons.play_arrow, size: 45, color: Colors.orange),
            ),
          ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 42,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.clip.authorName,
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
              const SizedBox(height: 14),
              Text(
                'เลื่อนขึ้นหรือลงเพื่อดูคลิปต่อไป',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
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
        _buildPreview(path),
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

  Widget _buildPreview(String path) {
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

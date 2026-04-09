import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:video_player/video_player.dart';

class ClipCard extends StatelessWidget {
  const ClipCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.thumbnailPath,
    this.forceVideoPreview = false,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final String? thumbnailPath;
  final bool forceVideoPreview;

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = imagePath.startsWith('http');
    final isAssetImage = imagePath.startsWith('assets/');
    final lower = imagePath.toLowerCase();
    final isVideo = forceVideoPreview ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.m4v');
    final scale = context.responsive;
    final cardWidth = scale.rs(128, min: 112, max: 132);

    return SizedBox(
      width: cardWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo)
              _VideoPreview(
                videoPath: imagePath,
                thumbnailPath: thumbnailPath,
              )
            else if (isNetworkImage)
              Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  debugPrint('โหลดรูปไม่ได้: $imagePath');
                  return Container(color: const Color(0xFFE2E2E2));
                },
              )
            else if (isAssetImage)
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  debugPrint('โหลดรูปไม่ได้: $imagePath');
                  return Container(color: const Color(0xFFE2E2E2));
                },
              )
            else
              Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  debugPrint('โหลดรูปไม่ได้: $imagePath');
                  return Container(color: const Color(0xFFE2E2E2));
                },
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: scale.rs(82, min: 70, max: 88),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            const Center(
              child: _PlayOverlayIcon(),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: scale.rf(12, min: 10.5, max: 12.5),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: scale.rf(10, min: 9, max: 10.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayOverlayIcon extends StatelessWidget {
  const _PlayOverlayIcon();

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    return CircleAvatar(
      radius: scale.rs(18, min: 15, max: 20),
      backgroundColor: Colors.white,
      child: Icon(
        Icons.play_arrow,
        color: const Color(0xFFC8C8C8),
        size: scale.rs(20, min: 17, max: 22),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({
    required this.videoPath,
    this.thumbnailPath,
  });

  final String videoPath;
  final String? thumbnailPath;

  @override
  Widget build(BuildContext context) {
    final resolvedThumbnailPath = thumbnailPath?.trim() ?? '';
    if (resolvedThumbnailPath.isNotEmpty) {
      return _PreviewImage(path: resolvedThumbnailPath);
    }

    if (!videoPath.startsWith('http')) {
      return _VideoThumbnail(
        key: ValueKey(videoPath),
        videoPath: videoPath,
      );
    }

    return Container(
      color: const Color(0xFFDDE7F0),
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_circle_fill_rounded,
        size: 42,
        color: Color(0xFF8AA0B6),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _previewFallback(),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _previewFallback(),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _previewFallback(),
    );
  }

  Widget _previewFallback() {
    return Container(
      color: const Color(0xFFDDE7F0),
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_circle_fill_rounded,
        size: 42,
        color: Color(0xFF8AA0B6),
      ),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  const _VideoThumbnail({
    super.key,
    required this.videoPath,
  });

  final String videoPath;

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;
  String? _controllerPath;

  @override
  void initState() {
    super.initState();
    _initializeController(widget.videoPath);
  }

  @override
  void didUpdateWidget(covariant _VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath == widget.videoPath) {
      return;
    }
    _initializeController(widget.videoPath);
  }

  Future<void> _initializeController(String path) async {
    final previous = _controller;
    _controller = null;
    _controllerPath = path;
    if (mounted) {
      setState(() {});
    }
    await previous?.dispose();

    final controller = path.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(path))
        : VideoPlayerController.file(File(path));

    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.seekTo(Duration.zero);
      await controller.play();
      await controller.pause();
    } catch (_) {
      // Keep fallback placeholder when preview initialization fails.
    }

    if (!mounted || _controllerPath != path || _controller != controller) {
      await controller.dispose();
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: const Color(0xFFDDE7F0),
        alignment: Alignment.center,
        child: const Icon(
          Icons.play_circle_fill_rounded,
          size: 42,
          color: Color(0xFF8AA0B6),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

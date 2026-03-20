import 'dart:io';

import 'package:flutter/material.dart';
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

    return SizedBox(
      width: 128,
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
              height: 82,
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
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.play_arrow,
                  color: Color(0xFFC8C8C8),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
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
      return _VideoThumbnail(videoPath: videoPath);
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
  const _VideoThumbnail({required this.videoPath});

  final String videoPath;

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.videoPath.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoPath))
        : VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) async {
        await _controller.setLooping(false);
        await _controller.seekTo(Duration.zero);
        await _controller.play();
        await _controller.pause();
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
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
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

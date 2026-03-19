import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayVideoPage extends StatefulWidget {
  const PlayVideoPage({
    super.key,
    required this.videoPath,
    required this.uploaderName,
    required this.caption,
  });

  final String videoPath;
  final String uploaderName;
  final String caption;

  @override
  State<PlayVideoPage> createState() => _PlayVideoPageState();
}

class _PlayVideoPageState extends State<PlayVideoPage> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.videoPath.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoPath))
        : VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) async {
        await _controller.setLooping(true);
        await _controller.play();
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

  void _togglePlayback() {
    if (!_controller.value.isInitialized) {
      return;
    }

    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.caption.trim();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller.value.isInitialized)
            GestureDetector(
              onTap: _togglePlayback,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          if (_controller.value.isInitialized && !_controller.value.isPlaying)
            const Center(
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Icon(Icons.play_arrow, size: 45, color: Colors.orange),
              ),
            ),
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.uploaderName,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

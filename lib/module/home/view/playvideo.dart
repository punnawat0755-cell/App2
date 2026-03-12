import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

// 💡 เปลี่ยนชื่อคลาสเป็น PlayVideo
class PlayVideo extends StatefulWidget {
  final String videoPath;
  final String uploaderName;
  final String caption;

  const PlayVideo({
    super.key,
    required this.videoPath,
    required this.uploaderName,
    required this.caption,
  });

  @override
  State<PlayVideo> createState() => _PlayVideoState();
}

// 💡 เปลี่ยนชื่อ State ให้ตรงกับ PlayVideo
class _PlayVideoState extends State<PlayVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // โหลดวิดีโอจากไฟล์ในเครื่อง
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {}); // รีเฟรชหน้าจอเมื่อโหลดข้อมูลวิดีโอเสร็จ
        _controller.play(); // เล่นอัตโนมัติ
        _controller.setLooping(true); // เล่นวนซ้ำ
      });
  }

  @override
  void dispose() {
    _controller.dispose(); // เคลียร์หน่วยความจำเมื่อปิดหน้าจอ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- 1. วิดีโอเต็มจอ ---
          _controller.value.isInitialized
              ? GestureDetector(
                  onTap: () {
                    // กดหน้าจอเพื่อ เล่น/หยุด
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                  child: FittedBox(
                    fit: BoxFit.cover, // ขยายวิดีโอให้เต็มจอ
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

          // --- 2. ปุ่ม Play ตรงกลาง (แสดงเมื่อกดหยุด) ---
          if (_controller.value.isInitialized && !_controller.value.isPlaying)
            const Center(
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Icon(Icons.play_arrow, size: 45, color: Colors.orange),
              ),
            ),

          // --- 3. ปุ่มย้อนกลับ ---
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          // --- 4. ชื่อและแคปชั่น ---
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.uploaderName, // ชื่อคนโพสต์
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.caption, // แคปชั่น
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

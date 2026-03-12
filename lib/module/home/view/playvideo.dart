import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class FullScreenVideoPage extends StatefulWidget {
  final String videoPath;
  final String uploaderName;
  final String caption;

  const FullScreenVideoPage({
    super.key,
    required this.videoPath,
    required this.uploaderName,
    required this.caption,
  });

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // 💡 ดึงไฟล์วิดีโอจากเครื่องมาโหลดเตรียมเล่น
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {}); // รีเฟรชหน้าจอเมื่อโหลดเสร็จ
        _controller.play(); // 💡 สั่งให้เล่นอัตโนมัติทันที
        _controller.setLooping(true); // 💡 สั่งให้เล่นวนซ้ำไปเรื่อยๆ
      });
  }

  @override
  void dispose() {
    _controller.dispose(); // ปิดวิดีโอเมื่อกดย้อนกลับ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- 1. ส่วนวิดีโอเต็มจอ ---
          _controller.value.isInitialized
              ? GestureDetector(
                  onTap: () {
                    // แตะหน้าจอเพื่อ เล่น/หยุด
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                  child: FittedBox(
                    fit: BoxFit.cover, // ทำให้วิดีโอขยายเต็มจอ
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ), // วงกลมโหลดตอนรอวิดีโอ
                ),

          // --- 2. ปุ่ม Play ตรงกลาง (แสดงเฉพาะตอนหยุดเล่น) ---
          if (_controller.value.isInitialized && !_controller.value.isPlaying)
            const Center(
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.play_arrow,
                  size: 45,
                  color: Colors.orange,
                ), // สีส้มแบบในรูป
              ),
            ),

          // --- 3. ปุ่มย้อนกลับ (ซ้ายบน) ---
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

          // --- 4. ชื่อและแคปชั่น (ซ้ายล่าง) แบบในรูป ---
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.uploaderName, // โชว์ชื่อ Seal หรือ Jellyfish
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.caption, // โชว์ข้อความที่พิมพ์มา
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

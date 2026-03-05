import 'package:flutter/material.dart';
import 'package:pod_player/pod_player.dart';
import 'package:get/get.dart';

class VideoAppController extends GetxController {
  late final VideoPlayerController videoController;
  final RxBool isInitialized = false.obs;
  final RxBool isPlaying = false.obs;

  @override
  void onInit() {
    super.onInit();
    videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://www.youtube.com/watch?v=l6a8q-WU6E4&list=RDl6a8q-WU6E4&start_radio=1'),
    )..initialize().then((_) {
        isInitialized.value = true;
        isPlaying.value = videoController.value.isPlaying;
      });
    videoController.addListener(_syncPlayback);
  }

  void _syncPlayback() {
    isPlaying.value = videoController.value.isPlaying;
  }

  void togglePlayPause() {
    if (videoController.value.isPlaying) {
      videoController.pause();
    } else {
      videoController.play();
    }
    isPlaying.value = videoController.value.isPlaying;
  }

  @override
  void onClose() {
    videoController.removeListener(_syncPlayback);
    videoController.dispose();
    super.onClose();
  }
}

class VideoApp extends StatelessWidget {
  VideoApp({super.key});

  final VideoAppController controller = Get.put(VideoAppController(), tag: 'video_app');

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: Center(
          child: controller.isInitialized.value
              ? AspectRatio(
                  aspectRatio: controller.videoController.value.aspectRatio,
                  child: VideoPlayer(controller.videoController),
                )
              : Container(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: controller.togglePlayPause,
          child: Icon(controller.isPlaying.value ? Icons.pause : Icons.play_arrow),
        ),
      ),
    );
  }
}

class PlayVideoNetworkController extends GetxController {
  late final PodPlayerController controller;

  @override
  void onInit() {
    super.onInit();
    controller = PodPlayerController(
      playVideoFrom: PlayVideoFrom.network(
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      ),
    )..initialise();
  }

  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }
}

class PlayVideoFromNetwork extends StatelessWidget {
  PlayVideoFromNetwork({super.key});

  final PlayVideoNetworkController podController =
      Get.put(PlayVideoNetworkController(), tag: 'pod_video');

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: PodVideoPlayer(controller: podController.controller));
  }
}

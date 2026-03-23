import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController createVideoPreviewController(String filePath) {
  return VideoPlayerController.file(File(filePath));
}

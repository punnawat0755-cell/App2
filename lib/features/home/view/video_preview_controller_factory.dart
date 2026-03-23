import 'package:video_player/video_player.dart';

import 'package:flutter_application_1/features/home/view/video_preview_controller_factory_stub.dart'
    if (dart.library.io) 'package:flutter_application_1/features/home/view/video_preview_controller_factory_io.dart'
    if (dart.library.html) 'package:flutter_application_1/features/home/view/video_preview_controller_factory_web.dart'
    as preview_factory;

VideoPlayerController createVideoPreviewController(String filePath) {
  return preview_factory.createVideoPreviewController(filePath);
}

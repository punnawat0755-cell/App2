import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppUserController extends GetxController {
  static const String defaultAvatarUrl =
      'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg';

  final RxString displayName = 'แมวน้ำ'.obs;
  final RxString gender = 'หญิง'.obs;
  final RxString avatarUrl = defaultAvatarUrl.obs;
  final RxString avatarLocalPath = ''.obs;
  final RxBool hasNewNotification = true.obs;

  ImageProvider get avatarImageProvider {
    final path = avatarLocalPath.value;
    if (path.isNotEmpty) {
      if (path.startsWith('assets/')) return AssetImage(path);
      return FileImage(File(path));
    }
    return NetworkImage(avatarUrl.value);
  }
}

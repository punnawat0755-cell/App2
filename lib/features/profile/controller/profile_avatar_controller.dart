import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileAvatarController extends GetxController {
  static const _avatarPrefsKey = 'profile.avatar_path';

  static const List<String> _avatarOptions = <String>[
    'assets/images/person.png',
    'assets/images/fine.png',
    'assets/images/Picture.png',
    'assets/images/whale_happy.png',
    'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
    'https://i.pinimg.com/736x/b7/ac/ba/b7acba5c729ea828c9ed398f21248681.jpg',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Felix',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Buddy',
  ];

  final RxString avatarUrl = _avatarOptions.first.obs;

  List<String> get avatarOptions => List<String>.unmodifiable(_avatarOptions);

  ImageProvider<Object> get avatarImageProvider =>
      avatarImageProviderFor(avatarUrl.value);

  ImageProvider<Object> avatarImageProviderFor(String avatarPath) {
    if (_isRemoteAvatar(avatarPath)) {
      return NetworkImage(avatarPath);
    }
    return AssetImage(avatarPath);
  }

  @override
  void onInit() {
    super.onInit();
    loadAvatar();
  }

  Future<void> loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAvatar = prefs.getString(_avatarPrefsKey);

    if (savedAvatar != null && _avatarOptions.contains(savedAvatar)) {
      avatarUrl.value = savedAvatar;
    }
  }

  Future<void> saveAvatar(String avatarPath) async {
    if (!_avatarOptions.contains(avatarPath)) return;

    avatarUrl.value = avatarPath;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarPrefsKey, avatarPath);
  }

  bool _isRemoteAvatar(String avatarPath) {
    return avatarPath.startsWith('http://') || avatarPath.startsWith('https://');
  }
}

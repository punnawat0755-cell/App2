import 'package:flutter/material.dart';

class ProfileAvatarCatalog {
  ProfileAvatarCatalog._();

  static const String _basePath = 'assets/images/profile_avatars';

  static final List<String> assetPaths = List<String>.unmodifiable(
    List<String>.generate(
      10,
      (index) => '$_basePath/avatar_${index + 1}.png',
    ),
  );

  static const String defaultAvatar = 'assets/images/profile_avatars/avatar_1.png';

  static String normalize(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return defaultAvatar;

    if (assetPaths.contains(value)) {
      return value;
    }

    final withFilename = '$_basePath/$value';
    if (assetPaths.contains(withFilename)) {
      return withFilename;
    }

    final withPng = value.endsWith('.png') ? value : '$value.png';
    final withFullPath = '$_basePath/$withPng';
    if (assetPaths.contains(withFullPath)) {
      return withFullPath;
    }

    return defaultAvatar;
  }

  static ImageProvider<Object> providerFor(String? rawValue) {
    return AssetImage(normalize(rawValue));
  }
}

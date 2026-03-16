import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettingsController extends GetxController {
  static const _themeModeKey = 'settings.theme_mode';

  final isLoading = false.obs;
  final selectedMode = 'system'.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();
    selectedMode.value = prefs.getString(_themeModeKey) ?? 'system';
    _applyTheme(selectedMode.value);
    isLoading.value = false;
  }

  Future<void> updateMode(String value) async {
    selectedMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, value);
    _applyTheme(value);
  }

  void _applyTheme(String mode) {
    switch (mode) {
      case 'light':
        Get.changeThemeMode(ThemeMode.light);
        break;
      case 'dark':
        Get.changeThemeMode(ThemeMode.dark);
        break;
      default:
        Get.changeThemeMode(ThemeMode.system);
    }
  }
}

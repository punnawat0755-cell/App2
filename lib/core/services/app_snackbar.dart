import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  static final Color _errorColor = Colors.red.shade400;
  static const Color _successColor = Colors.green;

  static void success(
    String title,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      title,
      message,
      backgroundColor: _successColor,
      duration: duration,
    );
  }

  static void error(
    String title,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      title,
      message,
      backgroundColor: _errorColor,
      duration: duration,
    );
  }

  static void _show(
    String title,
    String message, {
    required Color backgroundColor,
    required Duration duration,
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: duration,
    );
  }
}

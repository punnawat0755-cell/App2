import 'package:flutter/material.dart';

class Pictures {
  Pictures._();

  static Widget svg(
    String name, {
    double width = 24,
    double heigth = 24,
    Color? color,
  }) {
    IconData icon = Icons.image_outlined;
    if (name.contains('more-setting')) icon = Icons.menu_rounded;
    if (name.contains('about')) icon = Icons.info_outline_rounded;
    return Icon(icon, size: width, color: color);
  }
}

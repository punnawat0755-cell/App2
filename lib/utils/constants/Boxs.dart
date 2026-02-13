import 'package:flutter/material.dart';

class Boxs {
  Boxs._();

  static BoxDecoration decoration({
    BorderRadius? borderRadius,
    Color? color,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      color: color ?? Colors.white,
      boxShadow: const [
        BoxShadow(
            color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
      ],
    );
  }
}

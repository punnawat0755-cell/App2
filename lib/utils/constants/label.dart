import 'package:flutter/material.dart';

class Labels {
  Labels._();

  static Widget custom(
    String? label, {
    double maxSize = 14,
    double? minSize,
    int? maxLines,
    FontWeight? weight,
    Color? color,
    TextOverflow? overflow,
    TextAlign? textAlign,
  }) {
    return Text(
      label ?? '',
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: maxSize,
        fontWeight: weight ?? FontWeight.w400,
        color: color,
      ),
    );
  }

  static Widget body2({required String? label, Color? color}) =>
      custom(label, maxSize: 16, minSize: 14, color: color);

  static Widget body4({required String? label, Color? color}) =>
      custom(label, maxSize: 14, minSize: 12, color: color);

  static Widget body5({required String? label, Color? color}) =>
      custom(label, maxSize: 12, minSize: 10, color: color);

  static Widget h2({required String? label, Color? color}) =>
      custom(label, maxSize: 20, minSize: 18, weight: FontWeight.w700, color: color);

  static TextStyle fonts({
    double? fontSize,
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize ?? 14,
      fontWeight: weight ?? FontWeight.w400,
      color: color,
    );
  }

  static TextStyle fontsnotfuc({
    double? fontSize,
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize ?? 14,
      fontWeight: weight ?? FontWeight.w400,
      color: color,
    );
  }
}

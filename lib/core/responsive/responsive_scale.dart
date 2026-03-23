import 'package:flutter/widgets.dart';

class ResponsiveScale {
  const ResponsiveScale._(this.width);

  factory ResponsiveScale.of(BuildContext context) {
    return ResponsiveScale._(MediaQuery.sizeOf(context).width);
  }

  factory ResponsiveScale.fromWidth(double width) {
    return ResponsiveScale._(width);
  }

  final double width;

  bool get isCompact => width < 360;
  bool get isRegular => width >= 360 && width < 412;
  bool get isLarge => width >= 412;

  double get scale => (width / 390).clamp(0.84, 1.12).toDouble();

  double rs(
    double base, {
    double? min,
    double? max,
  }) {
    final resolvedMin = min ?? base * 0.82;
    final resolvedMax = max ?? base * 1.12;
    return (base * scale).clamp(resolvedMin, resolvedMax).toDouble();
  }

  double rf(
    double base, {
    double? min,
    double? max,
  }) {
    final resolvedMin = min ?? base * 0.9;
    final resolvedMax = max ?? base * 1.08;
    return (base * scale).clamp(resolvedMin, resolvedMax).toDouble();
  }

  double rw(
    double ratio, {
    double? min,
    double? max,
  }) {
    final computed = width * ratio;
    if (min == null && max == null) {
      return computed;
    }

    return computed
        .clamp(
          min ?? double.negativeInfinity,
          max ?? double.infinity,
        )
        .toDouble();
  }
}

extension BuildContextResponsiveScaleX on BuildContext {
  ResponsiveScale get responsive => ResponsiveScale.of(this);
}

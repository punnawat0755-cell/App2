import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppResponsiveFrame extends StatelessWidget {
  const AppResponsiveFrame({
    super.key,
    required this.child,
    this.baseWidth = 390,
    this.maxContentWidth = 520,
    this.minScale = 0.82,
    this.minTextScale = 0.9,
    this.maxTextScale = 1.15,
  });

  final Widget child;
  final double baseWidth;
  final double maxContentWidth;
  final double minScale;
  final double minTextScale;
  final double maxTextScale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final viewport = constraints.biggest;

        if (!viewport.width.isFinite ||
            !viewport.height.isFinite ||
            viewport.isEmpty) {
          return child;
        }

        final currentTextScale = mediaQuery.textScaler.scale(1);
        final safeTextScale = currentTextScale.clamp(
          minTextScale,
          maxTextScale,
        );

        if (viewport.width >= baseWidth) {
          final contentWidth = math.min(viewport.width, maxContentWidth);
          final sidePadding = (viewport.width - contentWidth) / 2;

          return MediaQuery(
            data: mediaQuery.copyWith(
              size: Size(contentWidth, viewport.height),
              textScaler: TextScaler.linear(safeTextScale),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              child: child,
            ),
          );
        }

        final scale = math.max(viewport.width / baseWidth, minScale);
        final virtualHeight = viewport.height / scale;

        // Keep logical insets proportional after app-wide scaling.
        final scaledMediaQuery = mediaQuery.copyWith(
          size: Size(baseWidth, virtualHeight),
          padding: mediaQuery.padding / scale,
          viewPadding: mediaQuery.viewPadding / scale,
          viewInsets: mediaQuery.viewInsets / scale,
          systemGestureInsets: mediaQuery.systemGestureInsets / scale,
          textScaler: TextScaler.linear(safeTextScale),
        );

        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: MediaQuery(
                data: scaledMediaQuery,
                child: SizedBox(
                  width: baseWidth,
                  height: virtualHeight,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

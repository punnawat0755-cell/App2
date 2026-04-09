import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';

class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.id,
    required this.title,
    required this.imagePath,
    required this.bgColor,
    required this.textColor,
    required this.isSelected,
    required this.onTap,
    this.width,
    this.height,
  });

  final String id;
  final String title;
  final String imagePath;
  final Color bgColor;
  final Color textColor;
  final bool isSelected;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final pageScale = context.responsive;

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = width ?? constraints.maxWidth;
          final isNarrowCard = cardWidth < 190;

          final resolvedHeight = height ??
              pageScale.rs(isNarrowCard ? 200 : 228, min: 184, max: 246);

          final topPadding =
              pageScale.rs(isNarrowCard ? 12 : 16, min: 10, max: 20);
          final bottomPadding =
              pageScale.rs(isNarrowCard ? 10 : 12, min: 8, max: 16);
          final radius = pageScale.rs(24, min: 18, max: 26);

          final titleFontSize = pageScale.rf(
            isNarrowCard ? 16.5 : 18,
            min: 14.5,
            max: 18.5,
          );
          final labelGap = pageScale.rs(isNarrowCard ? 8 : 12, min: 6, max: 14);

          final contentHeight = (resolvedHeight - topPadding - bottomPadding)
              .clamp(120.0, 320.0)
              .toDouble();
          final maxImageHeight =
              (contentHeight - (titleFontSize * 1.35) - labelGap)
                  .clamp(86.0, 220.0)
                  .toDouble();
          final desiredImageHeight = (contentHeight * 0.58).toDouble();
          final imageHeight =
              desiredImageHeight.clamp(86.0, maxImageHeight).toDouble();
          final imageWidth = (cardWidth * 0.76).clamp(110.0, 210.0).toDouble();

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: width,
            height: resolvedHeight,
            padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF4A7DCA) : Colors.transparent,
                width: isSelected ? 3.0 : 0.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: imageWidth,
                  height: imageHeight,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      id == 'listener'
                          ? Icons.volunteer_activism
                          : Icons.self_improvement,
                      size: (imageHeight * 0.72).clamp(56.0, 108.0),
                      color: Colors.white.withValues(alpha: 0.85),
                    );
                  },
                ),
                SizedBox(height: labelGap),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

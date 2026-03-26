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
          final topPadding = pageScale.rs(
            isNarrowCard ? 14 : 18,
            min: 12,
            max: 22,
          );
          final bottomPadding = pageScale.rs(
            isNarrowCard ? 10 : 14,
            min: 8,
            max: 16,
          );
          final radius = pageScale.rs(24, min: 18, max: 26);
          final imageWidth = (cardWidth * (isNarrowCard ? 0.62 : 0.68))
              .clamp(96.0, 176.0)
              .toDouble();
          final imageHeight = (imageWidth * 0.72).clamp(72.0, 132.0).toDouble();

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: width,
            height: height,
            padding: EdgeInsets.only(
              top: topPadding,
              bottom: bottomPadding,
            ),
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
              mainAxisSize: MainAxisSize.min,
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
                      size: pageScale.rs(
                        isNarrowCard ? 72 : 82,
                        min: 58,
                        max: 88,
                      ),
                      color: Colors.white.withValues(alpha: 0.85),
                    );
                  },
                ),
                SizedBox(
                  height: pageScale.rs(
                    isNarrowCard ? 10 : 14,
                    min: 8,
                    max: 16,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: pageScale.rf(
                      isNarrowCard ? 16.5 : 18,
                      min: 14.5,
                      max: 18.5,
                    ),
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

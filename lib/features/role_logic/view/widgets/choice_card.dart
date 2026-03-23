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
          final imageWidth = (cardWidth * 0.78).clamp(110.0, 200.0);
          final imageHeight = (imageWidth * 0.75).clamp(90.0, 150.0);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: width,
            height: height,
            padding: const EdgeInsets.only(top: 20, bottom: 15),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(25),
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
                      size: 90,
                      color: Colors.white.withValues(alpha: 0.85),
                    );
                  },
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: pageScale.rf(18, min: 16, max: 18.5),
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

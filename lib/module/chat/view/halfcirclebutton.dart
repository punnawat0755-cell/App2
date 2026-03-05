import 'package:flutter/material.dart';

class HalfCircleButton extends StatelessWidget {
  final String title;
  final String imagePath;
  final Color backgroundColor;
  final Color textColor;
  final bool isLeft;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? imagePadding;
  final double imageScale;
  final EdgeInsetsGeometry? textPadding;

  const HalfCircleButton({
    super.key,
    required this.title,
    required this.imagePath,
    required this.backgroundColor,
    required this.textColor,
    required this.isLeft,
    required this.onTap,
    this.imagePadding,
    this.imageScale = 1.0,
    this.textPadding,
  });

  @override
  Widget build(BuildContext context) {
    const double radius = 2000;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: isLeft
                ? const BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    bottomLeft: Radius.circular(radius),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(radius),
                    bottomRight: Radius.circular(radius),
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                bottom: 50,
                child: Padding(
                  padding: imagePadding ?? const EdgeInsets.all(15.0),
                  child: Transform.scale(
                    scale: imageScale,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        isLeft
                            ? Icons.sentiment_dissatisfied
                            : Icons.sentiment_satisfied_alt,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 35,
                left: 0,
                right: 0,
                child: Padding(
                  padding: textPadding ?? EdgeInsets.zero,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

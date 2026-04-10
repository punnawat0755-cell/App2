import 'package:flutter/material.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        padding: const EdgeInsets.only(top: 20, bottom: 15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A7DCA) : Colors.transparent,
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
              width: 200,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  id == 'listener'
                      ? Icons.volunteer_activism
                      : Icons.self_improvement,
                  size: 72,
                  color: Colors.white.withValues(alpha: 0.85),
                );
              },
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

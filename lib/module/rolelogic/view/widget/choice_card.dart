import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.id,
    required this.title,
    required this.imagePath,
    required this.bgColor,
    required this.textColor,
    required this.selectedRole,
    required this.onSelect,
    this.width,
    this.height,
  });

  final String id;
  final String title;
  final String imagePath;
  final Color bgColor;
  final Color textColor;
  final RxString selectedRole;
  final ValueChanged<String> onSelect;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = selectedRole.value == id;

      return GestureDetector(
        onTap: () => onSelect(id),
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
    });
  }
}

import 'package:flutter/material.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4489D7),
          ),
        ),
        const SizedBox(width: 5),
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ],
    );
  }
}

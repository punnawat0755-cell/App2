import 'dart:io';

import 'package:flutter/material.dart';

class ClipCard extends StatelessWidget {
  const ClipCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  final String title;
  final String subtitle;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = imagePath.startsWith('http');
    final isAssetImage = imagePath.startsWith('assets/');
    final lower = imagePath.toLowerCase();
    final isVideo = lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.m4v');

    return SizedBox(
      width: 110,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo)
              Container(
                color: const Color(0xFFDDE7F0),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 42,
                  color: Color(0xFF8AA0B6),
                ),
              )
            else if (isNetworkImage)
              Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  debugPrint('โหลดรูปไม่ได้: $imagePath');
                  return Container(color: const Color(0xFFE2E2E2));
                },
              )
            else if (isAssetImage)
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  debugPrint('โหลดรูปไม่ได้: $imagePath');
                  return Container(color: const Color(0xFFE2E2E2));
                },
              )
            else
              Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  debugPrint('โหลดรูปไม่ได้: $imagePath');
                  return Container(color: const Color(0xFFE2E2E2));
                },
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            const Center(
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.play_arrow,
                  color: Color(0xFFC8C8C8),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

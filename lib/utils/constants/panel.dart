import 'package:flutter/material.dart';

class Panels {
  Panels._();

  static Widget network({required String url, double size = 48}) {
    if (url.isEmpty) {
      return CircleAvatar(radius: size / 2, child: const Icon(Icons.person));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            CircleAvatar(radius: size / 2, child: const Icon(Icons.person)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';

class ClownFishBanner extends StatelessWidget {
  const ClownFishBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
        final horizontalPadding = scale.rs(20, min: 12, max: 22);
        final textSize = scale.rf(16, min: 14, max: 17);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFDE6A8),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 4,
                bottom: -15,
                right: 10,
                left: 10,
                child: Image.asset('assets/images/N1.png', fit: BoxFit.contain),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    'ในวันที่โลกใจร้ายกับเรา\nอย่าลืมใจดีกับตัวเองให้มากๆ นะ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF8D6E63),
                      fontWeight: FontWeight.bold,
                      fontSize: textSize,
                      height: 1.35,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          offset: const Offset(1, 1),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

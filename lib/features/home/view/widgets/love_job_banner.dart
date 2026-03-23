import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';

class LoveJobBanner extends StatelessWidget {
  const LoveJobBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
        final titleSize = scale.rf(22, min: 18, max: 23);
        final subtitleSize = scale.rf(16, min: 13, max: 17);
        final imageHeight = (constraints.maxHeight * 0.56).clamp(72.0, scale.rs(90));

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFB3E5FC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: -10,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/w1.png',
                  height: imageHeight,
                  width: 150,
                  fit: BoxFit.contain,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 1),
                      Text(
                        'I love my job',
                        style: TextStyle(
                          color: const Color(0xFF1565C0),
                          fontWeight: FontWeight.w900,
                          fontSize: titleSize,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ถ้าวันนี้คุณเหนื่อยก็แค่กลับไปพัก',
                        style: TextStyle(
                          color: const Color(0xFF1565C0),
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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

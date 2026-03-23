import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';

class DailyMissionBanner extends StatelessWidget {
  const DailyMissionBanner({
    super.key,
    this.onTap,
    this.dayCount = '138',
  });

  final VoidCallback? onTap;
  final String dayCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
        final whaleHeight =
            (constraints.maxHeight * 0.82).clamp(92.0, scale.rs(130));
        final listWidth = scale.rs(90, min: 72, max: 96);
        final textLeft = listWidth + scale.rs(18, min: 14, max: 22);
        final titleSize = scale.rf(15, min: 13, max: 16);
        final daySize = scale.rf(26, min: 22, max: 28);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFB5EFFF),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -9,
                bottom: 4,
                child:
                    Image.asset('assets/images/whale.png', height: whaleHeight),
              ),
              Positioned(
                left: 10,
                top: 14,
                bottom: 14,
                child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Image.asset(
                    'assets/images/list.png',
                    fit: BoxFit.contain,
                    width: listWidth,
                  ),
                ),
              ),
              Positioned(
                left: textLeft,
                top: 18,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ภารกิจรายวัน :',
                      style: TextStyle(
                        color: const Color(0xFF4489D7),
                        fontWeight: FontWeight.w200,
                        fontSize: titleSize,
                      ),
                    ),
                    Text(
                      'ตอบคำถามเพื่อรับเพื่อนแก้เหงา',
                      style: TextStyle(
                        color: const Color(0xFF4489D7),
                        fontSize: titleSize,
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Image.asset('assets/images/k1.png'),
                        const SizedBox(width: 5),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'DAY',
                              style: TextStyle(
                                color: const Color(0xFF4489D7),
                                fontWeight: FontWeight.bold,
                                fontSize: daySize,
                              ),
                            ),
                            Text(
                              dayCount,
                              style: TextStyle(
                                color: const Color(0xFF4489D7),
                                fontWeight: FontWeight.bold,
                                fontSize: daySize,
                                height: 0.9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

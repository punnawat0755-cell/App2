import 'package:flutter/material.dart';

class DailyMissionBanner extends StatelessWidget {
  const DailyMissionBanner({super.key});

  Future<void> _openCalendar(BuildContext context) async {
    await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
  }

  int _currentWhaleStreak() {
    final now = DateTime.now();
    final lastDayToCount = now.day;

    bool hasWhale(int day) {
      final isWhaleDay = (day >= 1 && day <= 8) || (day >= 15 && day <= 18);
      return isWhaleDay && day <= now.day;
    }

    final stack = <int>[];
    var streak = 0;
    for (var day = 1; day <= lastDayToCount; day++) {
      if (hasWhale(day)) {
        streak++;
      } else if (streak > 0) {
        stack.add(streak);
        streak = 0;
      }
    }
    if (streak > 0) stack.add(streak);
    return stack.isEmpty ? 0 : stack.last;
  }

  @override
  Widget build(BuildContext context) {
    final whaleStreak = _currentWhaleStreak();

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
            child: Image.asset('assets/images/whale.png', height: 130),
          ),
          Positioned(
            left: 10,
            top: 20,
            bottom: 20,
            child: GestureDetector(
              onTap: () => _openCalendar(context),
              behavior: HitTestBehavior.opaque,
              child: Image.asset(
                'assets/images/list.png',
                fit: BoxFit.contain,
                height: 200,
                width: 90,
              ),
            ),
          ),
          Positioned(
            left: 105,
            top: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ภารกิจรายวัน :',
                  style: TextStyle(
                    color: Color(0xFF4489D7),
                    fontWeight: FontWeight.w200,
                    fontSize: 15,
                  ),
                ),
                const Text(
                  'ตอบคำถามเพื่อรับเพื่อนแก้เหงา',
                  style: TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 15,
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
                        const Text(
                          'DAY',
                          style: TextStyle(
                            color: Color(0xFF4489D7),
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        Text(
                          '$whaleStreak',
                          style: const TextStyle(
                            color: Color(0xFF4489D7),
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
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
  }
}

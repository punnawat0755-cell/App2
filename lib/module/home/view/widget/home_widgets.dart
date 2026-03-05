import 'package:flutter/material.dart';

class DailyMissionBanner extends StatelessWidget {
  const DailyMissionBanner({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: Image.asset(
              'assets/images/list.png',
              fit: BoxFit.contain,
              height: 200,
              width: 90,
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAY',
                          style: TextStyle(
                            color: Color(0xFF4489D7),
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        Text(
                          '138',
                          style: TextStyle(
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

class ClownFishBanner extends StatelessWidget {
  const ClownFishBanner({super.key});

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'ในวันที่โลกใจร้ายกับเรา\nอย่าลืมใจดีกับตัวเองให้มากๆ นะ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF8D6E63),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.4,
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
  }
}

class LoveJobBanner extends StatelessWidget {
  const LoveJobBanner({super.key});

  @override
  Widget build(BuildContext context) {
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
              height: 90,
              width: 150,
              fit: BoxFit.contain,
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 1),
                  Text(
                    'I love my job',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ถ้าวันนี้คุณเหนื่อยก็แค่กลับไปพัก',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 16,
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
  }
}

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

    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: isNetworkImage
              ? NetworkImage(imagePath)
              : AssetImage(imagePath) as ImageProvider,
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            debugPrint("โหลดรูปไม่ได้: $imagePath");
          },
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
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
                color: Color.fromARGB(255, 200, 200, 200),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

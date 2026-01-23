import 'package:flutter/material.dart';
import '../supabase_client.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final name = supabase.auth.currentUser?.email?.split('@').first ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFE9F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE9F7FF),
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Hello, ',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.4),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              name,
              style: const TextStyle(
                color: Color(0xFF1E88FF),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Color(0xFF1E88FF)),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: const Icon(Icons.person, size: 18, color: Color(0xFF1E88FF)),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- PROGRESS CARD ----------
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD7F1FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book, color: Color(0xFF1E88FF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'การเรียนรู้:\nคลิปภาษาไทยพร้อมคำแปล',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Text(
                              'DAY ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E88FF),
                              ),
                            ),
                            Text(
                              '38',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E88FF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.waves, color: Color(0xFF1E88FF), size: 36),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ---------- SHORT CLIPS ----------
            _sectionHeader('Short Clips'),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _clipCard('jellyfish', '2 week'),
                  _clipCard('starfish', '1 week'),
                  _clipCard('octopus', '1 day'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ---------- LEARNING CONTENT ----------
            _sectionHeader('บทเรียนวิดีโอ'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _lessonCard(
                    title: 'วาฬ 52Hz\nเสียงที่โดดเดี่ยว',
                    subtitle: '1 Month Ago',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _lessonCard(
                    title: 'อยู่กับตัวเองให้เป็น',
                    subtitle: '3 Month Ago',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // ---------- BOTTOM NAV ----------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF1E88FF),
        unselectedItemColor: Colors.black.withValues(alpha: 0.35),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'ชอบ'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'แชท'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'แจ้ง'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'โปรไฟล์'),
        ],
      ),
    );
  }

  // ---------- WIDGETS ----------

  Widget _sectionHeader(String text) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E88FF),
          ),
        ),
        const Spacer(),
        const Icon(Icons.chevron_right, color: Color(0xFF1E88FF)),
      ],
    );
  }

  Widget _clipCard(String title, String time) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        image: const DecorationImage(
          image: AssetImage('assets/placeholder.jpg'), // เปลี่ยนเป็นภาพจริงได้
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(Icons.play_circle_fill,
                color: Colors.white, size: 42),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Text(
              '$title\n$time',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonCard({
    required String title,
    required String subtitle,
  }) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/placeholder.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

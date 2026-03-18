import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> favoriteItems = [
      {
        'date': 'January 25, 2026',
        'title': 'seal',
        'content':
            "อนุญาตให้ตัวเอง 'ไม่โอเค' บ้างก็ได้ ไม่จำเป็นต้องแบกความเข้มแข็งไว้ตลอดเวลา 24 ชม. หรอกนะ การยอมรับความเปราะบางของตัวเอง คือก้าวแรกของการเยียวยาที่แท้จริง 🤍",
        'image_url':
            'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
      },
      {
        'date': 'January 25, 2026',
        'title': 'seal2',
        'content':
            'คุณค่าของคุณไม่ได้ลดลงในวันที่คุณทำพลาด หรือในวันที่ใครมองไม่เห็น ดอกไม้ยังคงเป็นดอกไม้แม้ในวันที่ไม่มีใครชม คุณเองก็เช่นกัน 🌷',
        'image_url':
            'https://i.pinimg.com/736x/c5/47/82/c54782d0ca477283d800f5637a9efe67.jpg',
      },
      {
        'date': 'January 23, 2026',
        'title': 'seal',
        'content':
            "อนุญาตให้ตัวเอง 'ไม่โอเค' บ้างก็ได้ ไม่จำเป็นต้องแบกความเข้มแข็งไว้ตลอดเวลา 24 ชม. หรอกนะ การยอมรับความเปราะบางของตัวเอง คือก้าวแรกของการเยียวยาที่แท้จริง 🤍",
        'image_url':
            'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
      },
      {
        'date': 'January 23, 2026',
        'title': 'seal2',
        'content':
            'คุณค่าของคุณไม่ได้ลดลงในวันที่คุณทำพลาด หรือในวันที่ใครมองไม่เห็น ดอกไม้ยังคงเป็นดอกไม้แม้ในวันที่ไม่มีใครชม คุณเองก็เช่นกัน 🌷',
        'image_url':
            'https://i.pinimg.com/736x/c5/47/82/c54782d0ca477283d800f5637a9efe67.jpg',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 40,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/back.png',
                width: 25,
                height: 25,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        titleSpacing: 2,
        title: const Text(
          'รายการโปรด',
          style: TextStyle(
            color: Color(0xFF4489D7),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: favoriteItems.length,
        itemBuilder: (context, index) {
          final item = favoriteItems[index];
          final bool showDateHeader = index == 0 ||
              favoriteItems[index]['date'] != favoriteItems[index - 1]['date'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDateHeader) ...[
                const SizedBox(height: 10),
                Text(
                  item['date'] as String,
                  style: const TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: NetworkImage(
                            item['image_url'] as String? ??
                                'https://via.placeholder.com/150',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: const TextStyle(
                                  color: Color(0xFF757575),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['content'] as String,
                                style: const TextStyle(
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Divider(
                      color: Color(0xFFD9D9D9),
                      thickness: 1.2,
                      height: 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

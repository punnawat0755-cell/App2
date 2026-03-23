import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:get/get.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appScale = context.responsive;
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
        leadingWidth: appScale.rs(40, min: 34, max: 40),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Padding(
            padding: EdgeInsets.only(
              left: appScale.rs(10, min: 8, max: 10),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/back.png',
                width: appScale.rs(25, min: 20, max: 25),
                height: appScale.rs(25, min: 20, max: 25),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        titleSpacing: 2,
        title: Text(
          'รายการโปรด',
          style: TextStyle(
            color: Color(0xFF4489D7),
            fontSize: appScale.rf(22, min: 18, max: 22),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
          final horizontalPadding = constraints.maxWidth < 360
              ? scale.rs(14, min: 10, max: 14)
              : scale.rs(20, min: 14, max: 20);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: scale.rs(10, min: 8, max: 10),
                ),
                itemCount: favoriteItems.length,
                itemBuilder: (context, index) {
                  final item = favoriteItems[index];
                  final bool showDateHeader = index == 0 ||
                      favoriteItems[index]['date'] !=
                          favoriteItems[index - 1]['date'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDateHeader) ...[
                        SizedBox(height: scale.rs(10, min: 8, max: 10)),
                        Text(
                          item['date'] as String,
                          style: TextStyle(
                            color: const Color(0xFF4489D7),
                            fontSize: scale.rf(18, min: 15, max: 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: scale.rs(10, min: 8, max: 10)),
                      ],
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: scale.rs(10, min: 8, max: 10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: scale.rs(25, min: 20, max: 25),
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: NetworkImage(
                                    item['image_url'] as String? ??
                                        'https://via.placeholder.com/150',
                                  ),
                                ),
                                SizedBox(
                                  width: scale.rs(10, min: 8, max: 10),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] as String,
                                        style: TextStyle(
                                          color: const Color(0xFF757575),
                                          fontSize:
                                              scale.rf(18, min: 15, max: 18),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(
                                        height: scale.rs(2, min: 1, max: 2),
                                      ),
                                      Text(
                                        item['content'] as String,
                                        style: TextStyle(
                                          color: const Color(0xFF9E9E9E),
                                          fontSize:
                                              scale.rf(14, min: 12, max: 14),
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: scale.rs(15, min: 10, max: 15)),
                            Divider(
                              color: Color(0xFFD9D9D9),
                              thickness: scale.rs(1.2, min: 1, max: 1.2),
                              height: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

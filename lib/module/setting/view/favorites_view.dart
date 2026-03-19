// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class FavoritesPage extends StatelessWidget {
//   const FavoritesPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // ข้อมูลจำลอง (Mock Data)
//     final List<Map<String, dynamic>> favoriteItems = [
//       {
//         "date": "January 25, 2026",
//         "title": "seal",
//         "content":
//             "อนุญาตให้ตัวเอง 'ไม่โอเค' บ้างก็ได้ ไม่จำเป็นต้องแบกความเข้มแข็งไว้ตลอดเวลา 24 ชม. หรอกนะ การยอมรับความเปราะบางของตัวเอง คือก้าวแรกของการเยียวยาที่แท้จริง 🤍",
//         "image_url":
//             "https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg",
//       },
//       {
//         "date": "January 25, 2026",
//         "title": "seal2",
//         "content":
//             "คุณค่าของคุณไม่ได้ลดลงในวันที่คุณทำพลาด หรือในวันที่ใครมองไม่เห็น ดอกไม้ยังคงเป็นดอกไม้แม้ในวันที่ไม่มีใครชม คุณเองก็เช่นกัน 🌷",
//         "image_url":
//             "https://i.pinimg.com/736x/c5/47/82/c54782d0ca477283d800f5637a9efe67.jpg",
//       },
//       {
//         "date": "January 23, 2026",
//         "title": "seal",
//         "content":
//             "อนุญาตให้ตัวเอง 'ไม่โอเค' บ้างก็ได้ ไม่จำเป็นต้องแบกความเข้มแข็งไว้ตลอดเวลา 24 ชม. หรอกนะ การยอมรับความเปราะบางของตัวเอง คือก้าวแรกของการเยียวยาที่แท้จริง 🤍",
//         "image_url":
//             "https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg",
//       },
//       {
//         "date": "January 23, 2026",
//         "title": "seal2",
//         "content":
//             "คุณค่าของคุณไม่ได้ลดลงในวันที่คุณทำพลาด หรือในวันที่ใครมองไม่เห็น ดอกไม้ยังคงเป็นดอกไม้แม้ในวันที่ไม่มีใครชม คุณเองก็เช่นกัน 🌷",
//         "image_url":
//             "https://i.pinimg.com/736x/c5/47/82/c54782d0ca477283d800f5637a9efe67.jpg",
//       },
//     ];

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leadingWidth: 40,
//         leading: GestureDetector(
//           onTap: () => Get.back(),
//           child: Padding(
//             padding: const EdgeInsets.only(left: 10),
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: Image.asset(
//                 'assets/images/back.png',
//                 width: 25,
//                 height: 25,
//                 fit: BoxFit.contain,
//               ),
//             ),
//           ),
//         ),
//         titleSpacing: 2,
//         title: const Text(
//           "รายการโปรด",
//           style: TextStyle(
//             color: Color(0xFF4489D7),
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: false,
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         itemCount: favoriteItems.length,
//         itemBuilder: (context, index) {
//           final item = favoriteItems[index];

//           // เช็คการแสดง Header วันที่
//           bool showDateHeader = false;
//           if (index == 0 ||
//               favoriteItems[index]['date'] !=
//                   favoriteItems[index - 1]['date']) {
//             showDateHeader = true;
//           }

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 1. ส่วนแสดงวันที่ (Header)
//               if (showDateHeader) ...[
//                 const SizedBox(height: 10),
//                 Text(
//                   item['date'],
//                   style: const TextStyle(
//                     color: Color(0xFF4489D7),
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//               ],

//               // 2. ส่วนเนื้อหาแต่ละรายการ
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 10),
//                 child: Column(
//                   children: [
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         // รูปภาพวงกลม
//                         CircleAvatar(
//                           radius: 25, // ขนาดตามที่เคยปรับไว้
//                           backgroundColor: Colors.grey[200],
//                           backgroundImage: NetworkImage(
//                             item['image_url'] ??
//                                 'https://via.placeholder.com/150', // ดึงรูปตามข้อมูลในลิสต์
//                           ),
//                         ),
//                         const SizedBox(width: 10),

//                         // ข้อความ (Title & Content)
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 item['title'],
//                                 style: const TextStyle(
//                                   color: Color(0xFF757575),
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 2),
//                               Text(
//                                 item['content'],
//                                 style: const TextStyle(
//                                   color: Color(0xFF9E9E9E),
//                                   fontSize: 14,
//                                   height: 1.3,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 15),

//                     // 3. เส้นคั่นที่ยาวเต็มขอบ
//                     const Divider(
//                       color: Color(0xFFD9D9D9),
//                       thickness: 1.2,
//                       height: 1,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // 💡 อย่าลืมรันคำสั่ง: flutter pub add intl

// ==========================================
// 1. Controller สำหรับดึงข้อมูลจาก Supabase
// ==========================================
class FavoritesController extends GetxController {
  final supabase = Supabase.instance.client;

  // ตัวแปรสำหรับเก็บข้อมูลและสถานะการโหลด
  var isLoading = true.obs;
  var favoriteItems = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchFavorites(); // เรียกดึงข้อมูลทันทีที่เปิดหน้านี้
  }

  Future<void> fetchFavorites() async {
    try {
      isLoading(true);

      // 1. ดึง user_id ปัจจุบันที่ล็อกอินอยู่
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        print('User not logged in');
        isLoading(false);
        return;
      }

      // 2. Query ข้อมูลจากตาราง post_reactions Join กับ posts
      // 💡 ข้อควรระวัง: ถ้าตารางโพสต์ของคุณไม่ได้ชื่อ 'posts' ต้องเปลี่ยนชื่อให้ตรงด้วยนะครับ
      final response = await supabase
          .from('post_reactions')
          .select('''
            created_at,
            posts (
              title,
              content,
              image_url
            )
          ''')
          .eq('user_id', userId)
          .eq('reaction', 'like') // ดึงเฉพาะรายการที่กด Like
          .order('created_at', ascending: false);

      // 3. จัดการข้อมูลให้อยู่ในรูปแบบที่ UI ต้องการ
      final List<Map<String, dynamic>> loadedItems = [];

      for (var row in response) {
        final postData = row['posts'];

        if (postData != null) {
          // แปลงวันที่ created_at
          DateTime dt = DateTime.parse(row['created_at']);
          String formattedDate = DateFormat('MMMM dd, yyyy').format(dt);

          loadedItems.add({
            "date": formattedDate,
            "title": postData['title'] ?? 'ไม่มีชื่อโพสต์',
            "content": postData['content'] ?? '',
            "image_url":
                postData['image_url'] ?? 'https://via.placeholder.com/150',
          });
        }
      }

      // อัปเดตข้อมูลเข้าตัวแปร
      favoriteItems.assignAll(loadedItems);
    } catch (e) {
      print('Error fetching favorites: $e');
      Get.snackbar('ข้อผิดพลาด', 'ไม่สามารถโหลดรายการโปรดได้');
    } finally {
      isLoading(false);
    }
  }
}

// ==========================================
// 2. UI หน้า รายการโปรด
// ==========================================
class FavoritesPage extends StatelessWidget {
  FavoritesPage({super.key});

  // 💡 เรียกใช้ Controller ภายในไฟล์เดียวกัน
  final FavoritesController controller = Get.put(FavoritesController());

  @override
  Widget build(BuildContext context) {
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
          "รายการโปรด",
          style: TextStyle(
            color: Color(0xFF4489D7),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),

      // 💡 ครอบ Body ด้วย Obx เพื่อรอรับข้อมูลจาก API
      body: Obx(() {
        // สถานะ: กำลังโหลดข้อมูล
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4489D7)),
          );
        }

        // สถานะ: ไม่มีรายการโปรดเลย
        if (controller.favoriteItems.isEmpty) {
          return const Center(
            child: Text(
              "ยังไม่มีรายการโปรด",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        // สถานะ: มีข้อมูล แสดง ListView
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: controller.favoriteItems.length,
          itemBuilder: (context, index) {
            final item = controller.favoriteItems[index];

            // เช็คการแสดง Header วันที่
            bool showDateHeader = false;
            if (index == 0 ||
                controller.favoriteItems[index]['date'] !=
                    controller.favoriteItems[index - 1]['date']) {
              showDateHeader = true;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ส่วนแสดงวันที่ (Header)
                if (showDateHeader) ...[
                  const SizedBox(height: 10),
                  Text(
                    item['date'],
                    style: const TextStyle(
                      color: Color(0xFF4489D7),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // 2. ส่วนเนื้อหาแต่ละรายการ
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // รูปภาพวงกลม
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: NetworkImage(item['image_url']),
                          ),
                          const SizedBox(width: 10),

                          // ข้อความ (Title & Content)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: const TextStyle(
                                    color: Color(0xFF757575),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['content'],
                                  maxLines:
                                      3, // จำกัดจำนวนบรรทัดไม่ให้ยาวเกินไป
                                  overflow: TextOverflow.ellipsis,
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

                      // 3. เส้นคั่น
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
        );
      }),
    );
  }
}

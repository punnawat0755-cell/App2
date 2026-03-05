import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --------------------------------------------------------
// 1. GetX Controller สำหรับจัดการ State
// --------------------------------------------------------
class EncouragementController extends GetxController {
  void onNextPressed() {
    print("User clicked Next");
  }
}

// --------------------------------------------------------
// 2. หน้าจอ UI หลัก
// --------------------------------------------------------
class Encouragement extends StatelessWidget {
  // แก้ไขเป็น super.key ตามคำแนะนำของ Linter (เส้นหยักสีฟ้าจะหายไป)
  Encouragement({super.key});

  // เรียกใช้งาน Controller (เส้นหยักสีแดงจะหายไป เพราะ Controller อยู่ด้านบนแล้ว)
  final EncouragementController controller = Get.put(EncouragementController());

  @override
  Widget build(BuildContext context) {
    // กำหนดสีตามตัวอย่างรูปภาพ
    const Color cardBgColor = Color(0xFFD6F0FF);
    const Color textColor = Color(0xFF4489D7);
    const Color buttonColor = Color(0xFF234B83);
    const Color cardShadowColor = Color(0xFFF3DDBC); // สีเงาส้มอ่อนใต้กล่อง

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // --- เลเยอร์ที่ 1: ของตกแต่งพื้นหลัง (Positioned Images) ---

            // ก้อนเมฆบนซ้าย
            Positioned(
              top: 20,
              left: -10,
              child: Image.asset(
                'assets/images/cloud_top_left.png',
                width: 180,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.cloud_queue, color: Colors.blue),
              ),
            ),

            // น้องวาฬ (เยื้องขวาบน)
            Positioned(
              top: 100,
              right: 10,
              child: Image.asset(
                'assets/images/whale.png',
                width: 220,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.water, color: Colors.blue),
              ),
            ),

            // ก้อนเมฆล่างซ้าย
            Positioned(
              bottom: 0,
              left: -20,
              child: Image.asset(
                'assets/images/cloud_bottom_left.png',
                width: 250,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.cloud, color: Colors.blue),
              ),
            ),

            // ดอกไม้ล่างขวา
            Positioned(
              bottom: 40,
              right: 20,
              child: Image.asset(
                'assets/images/flower_bottom_right.png',
                width: 60,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.close, color: Colors.blue),
              ),
            ),

            // --- เลเยอร์ที่ 2: เนื้อหาหลัก (Center Content) ---
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 150), // เว้นระยะจากด้านบน
                      // กล่องข้อความ
                      Container(
                        padding: const EdgeInsets.all(25.0),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: textColor.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: cardShadowColor,
                              offset: Offset(6, 6), // เงาแข็งๆ แบบในรูป
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Text(
                          'การอนุญาตให้ตัวเอง "ไม่โอเค" บ้างไม่ใช่เรื่องผิด\n'
                          'และวันที่ท้องฟ้ามืดครึ้มก็ไม่ได้แปลว่าดวงอาทิตย์จะดับสูญ\n'
                          'ไปตลอดกาล ในช่วงเวลาที่อารมณ์ขุ่นมัว\n'
                          'ลองวางความคาดหวังที่แบกไว้ลงชั่วคราว หายใจเข้าลึกๆ\n'
                          'เพื่อดึงสติกลับมาอยู่กับปัจจุบัน\n'
                          'และโอบกอดความรู้สึกของตัวเองด้วยความเมตตาเหมือน\n'
                          'ที่คุณมักจะมอบให้ผู้อื่น จำไว้ว่าความรู้สึกแย่ๆ\n'
                          'นี้เป็นเพียงสภาวะชั่วคราวเหมือนเมฆที่ลอยผ่าน\n'
                          'เพียงแค่คุณใจดีกับตัวเองและผ่านวันนี้ไปได้\n'
                          'นั่นก็นับเป็นชัยชนะที่ยิ่งใหญ่แล้ว',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ปุ่ม "ถัดไป"
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          // เมื่อกดปุ่ม จะไปเรียกใช้ฟังก์ชันใน Controller ด้านบน
                          onPressed: () => controller.onNextPressed(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            'ถัดไป',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      // รูปภาพทุ่งหญ้าตรงกลางด้านล่าง
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/Picture.png',
                            width: 220,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 220,
                              height: 110,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 100), // พื้นที่ว่างกันขอบล่าง
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

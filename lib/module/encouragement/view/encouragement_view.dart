import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EncouragementController extends GetxController {
  void onNextPressed() {
    print("User clicked Next");
  }
}

class Encouragement extends StatelessWidget {
  Encouragement({super.key});

  final EncouragementController controller = Get.put(EncouragementController());

  @override
  Widget build(BuildContext context) {
    const Color cardBgColor = Color(0xFFD6F0FF);
    const Color textColor = Color(0xFF4489D7);
    const Color buttonColor = Color(0xFF234B83);
    const Color cardShadowColor = Color(0xFFF3DDBC);

    return Scaffold(
      backgroundColor: Colors.white,
      // 💡 แก้จุดที่ 1: ปิด SafeArea ด้านล่าง เพื่อให้รูปทะลุไปจนสุดขอบจอโทรศัพท์
      body: SafeArea(
        bottom: false,
        // 💡 แก้จุดที่ 2: ถอด SingleChildScrollView ออก แล้วใช้ Column ธรรมดา
        child: Column(
          children: [
            // ==========================================
            // ส่วนที่ 1: ด้านบน (ภาพน้องวาฬ/เมฆ)
            // ==========================================
            SizedBox(
              width: double.infinity,
              child: Image.asset(
                'assets/images/whaletop.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (c, e, s) => const SizedBox(height: 250),
              ),
            ),

            // ==========================================
            // ส่วนที่ 2: ตรงกลาง (กล่องข้อความ + ปุ่มถัดไป)
            // ==========================================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30.0,
                  vertical: 10.0,
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // จัดให้อยู่กึ่งกลางหน้าจอ
                  children: [
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
                            offset: Offset(6, 6),
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
                          fontSize: 12,
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
                        onPressed: () => controller.onNextPressed(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'ถัดไป',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================
            // ส่วนที่ 3: ด้านล่าง (รูปทุ่งหญ้า + เมฆ + ดอกไม้)
            // ==========================================
            SizedBox(
              width: double.infinity,
              child: Image.asset(
                'assets/images/whalebottom.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (c, e, s) => const SizedBox(height: 240),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

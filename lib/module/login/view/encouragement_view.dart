import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EncouragementController extends GetxController {
  void onNextPressed() {
    print("User clicked Next");
  }
}

class Encouragement extends StatelessWidget {
  // แก้ไขเป็น super.key เพื่อให้เส้นหยักสีฟ้าหายไป
  Encouragement({super.key});

  // เรียกใช้งาน Controller
  final EncouragementController controller = Get.put(EncouragementController());

  @override
  Widget build(BuildContext context) {
    // กำหนดสีตามตัวอย่างรูปภาพ
    const Color cardBgColor = Color(0xFFD6F0FF);
    const Color textColor = Color(0xFF4489D7);
    const Color buttonColor = Color(0xFF234B83);
    const Color cardShadowColor = Color(0xFFF3DDBC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // --------------------------------------------------------
          // ใช้ Column เป็นโครงร่างหลัก เพื่อแบ่งส่วน บน-กลาง-ล่าง ตามกรอบสีฟ้า
          // --------------------------------------------------------
          child: Column(
            children: [
              // ==========================================
              // ส่วนที่ 1: ด้านบน (ภาพน้องวาฬ/เมฆ)
              // ==========================================
              SizedBox(
                width: double.infinity,
                height: 250, // กำหนดความสูงของกรอบด้านบน
                child: Stack(
                  children: [
                    // ถ้ารูป whaletop.png คือรูปรวมทั้งหมดของด้านบน สามารถใช้ Center จัดกลางได้เลยครับ
                    Positioned(
                      top: 20,
                      left: -10,
                      child: Image.asset(
                        'assets/images/whaletop.png',
                        width: double.infinity,
                        height: 250,
                        // fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // ส่วนที่ 2: ตรงกลาง (กล่องข้อความ + ปุ่มถัดไป)
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
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
                  ],
                ),
              ),

              // ==========================================
              // ส่วนที่ 3: ด้านล่าง (รูปทุ่งหญ้า + เมฆ + ดอกไม้)
              // ==========================================
              const SizedBox(height: 30), // เว้นระยะห่างจากปุ่มถัดไป
              SizedBox(
                width: double.infinity,
                height: 300, // กำหนดพื้นที่ให้รูปด้านล่าง
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // รูปภาพทุ่งหญ้า
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
                          'assets/images/whalebottom.png',
                          width: 440,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 220,
                            height: 110,
                            // color: Colors.grey[300],
                            // child: const Icon(Icons.image),
                          ),
                        ),
                      ),
                    ),

                    // // ก้อนเมฆล่างซ้าย
                    // Positioned(
                    //   bottom: 0,
                    //   left: -20,
                    //   child: Image.asset(
                    //     'assets/images/cloud_bottom_left.png',
                    //     width: 250,
                    //   ),
                    // ),

                    // ดอกไม้ล่างขวา
                    Positioned(
                      bottom: 40,
                      right: 20,
                      child: Image.asset(
                        'assets/images/whalebottom.png',
                        width: 60,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30), // พื้นที่ว่างล่างสุดกันติดขอบจอ
            ],
          ),
        ),
      ),
    );
  }
}

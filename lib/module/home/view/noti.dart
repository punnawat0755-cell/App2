import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ==========================================
// 1. Controller สำหรับจัดการข้อมูลหน้า แจ้งเตือน
// ==========================================
class NotiPageController extends GetxController {
  // 💡 ในอนาคตถ้ามี API สามารถนำมาเชื่อมต่อข้อมูลตรงนี้ได้ครับ
}

// ==========================================
// 2. View หน้า UI (NotiPage)
// ==========================================
class NotiPage extends StatelessWidget {
  NotiPage({super.key});

  final NotiPageController controller = Get.put(NotiPageController());

  // กำหนดสีหลักที่ใช้ในหน้านี้ให้ตรงกับรูป
  final Color primaryBlue = const Color(0xFF4489D7); // สีฟ้าของตัวอักษรหัวข้อ
  final Color newNotiBgColor = const Color(0xFFE6F7FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ส่วนที่ 1: Header (ปุ่ม Back & คำว่า แจ้งเตือน) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Image.asset("assets/images/back.png"),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "แจ้งเตือน",
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // --- ส่วนที่ 2: รายการแจ้งเตือน ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // 🔴 หมวดหมู่: Now
                  _buildSectionTitle("Now"),
                  _buildNotificationItem(
                    text:
                        "ในอีก 3 วันคุณกำลังจะเป็นประจำเดือน อย่าลืมพกผ้าอนามัยด้วยนะคะ💖",
                    time: "7h",
                    isNew: true, // 💡 แจ้งเตือนใหม่ พื้นหลังจะเป็นสีฟ้าอ่อน
                  ),
                  _buildNotificationItem(
                    text:
                        "ตอนนี้คุณโอเคแล้วใช่ไหม💖 How are you ส่งกำลังใจให้คุณนะ✌️",
                    time: "7h",
                    isNew: true,
                  ),

                  const SizedBox(height: 10),

                  // 🔴 หมวดหมู่: January 23, 2026
                  _buildSectionTitle("January 23, 2026"),
                  _buildNotificationItem(
                    text:
                        "ตอนนี้คุณโอเคแล้วใช่ไหม💖 How are you ส่งกำลังใจให้คุณนะ✌️",
                    isNew: false, // 💡 แจ้งเตือนเก่า พื้นหลังสีขาว
                  ),
                  _buildNotificationItem(
                    text: "อาหารปลาของคุณเต็มแล้วตอนนี้🐟💕",
                    isNew: false,
                  ),

                  const SizedBox(height: 10),

                  // 🔴 หมวดหมู่: January 22, 2026
                  _buildSectionTitle("January 22, 2026"),
                  _buildNotificationItem(
                    text: "มีคนรอแชทกับคุณอยู่นะ🌟",
                    isNew: false,
                  ),
                  _buildNotificationItem(
                    text:
                        "ลืมกันหรือยัง คุณยังไม่ได้ใส่การเป็นประจำเดือนเลยน๊า🩸",
                    isNew: false,
                  ),

                  const SizedBox(height: 30), // เว้นระยะด้านล่างสุด
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 💡 Widget ย่อยสำหรับสร้าง "หัวข้อวันที่"
  // ==========================================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 10),
      child: Text(
        title,
        style: TextStyle(
          color: primaryBlue,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================
  // 💡 Widget ย่อยสำหรับสร้าง "กล่องข้อความแจ้งเตือน"
  // ==========================================
  Widget _buildNotificationItem({
    required String text,
    String? time,
    required bool isNew,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isNew ? newNotiBgColor : Colors.white, // ถ้าใหม่ให้เป็นสีฟ้าอ่อน
        borderRadius: BorderRadius.circular(30), // ขอบมนแบบเม็ดยา
        border: Border.all(
          color: Colors.grey[300]!, // สีขอบสีเทาอ่อน
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[600], // สีข้อความเทาเข้ม
                fontSize: 14,
                height: 1.4, // เพิ่มความห่างบรรทัดให้อ่านง่าย
              ),
            ),
          ),
          if (time != null) ...[
            const SizedBox(width: 10),
            Text(
              time,
              style: TextStyle(
                color: Colors.grey[400], // สีเวลาเทาอ่อน
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

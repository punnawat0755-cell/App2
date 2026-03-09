import 'package:flutter/material.dart';
import 'package:get/get.dart';
// อย่าลืมเช็ค path ของไฟล์เหล่านี้ให้ตรงกับโปรเจกต์ของคุณด้วยนะครับ
import 'package:flutter_application_1/module/chat/view/conversationsummarypage.dart';
import 'package:flutter_application_1/module/chat/view/chatconfirmdialog.dart';

// ==========================================
// 1. Controller: เปลี่ยนชื่อเป็น PauseChatController
// ==========================================
class PauseChatController extends GetxController {
  // ฟังก์ชันสำหรับยืนยันการจบสนทนา
  void confirmEndConversation() {
    Get.back(); // ปิดหน้าต่าง Popup
    Get.to(() => ConversationSummaryPage());
  }

  // ฟังก์ชันสำหรับโชว์ Popup
  void showEndConversationDialog() {
    showChatConfirmDialog(
      title: "คุณต้องการที่จะออกจากบทสนทนา\nใช่หรือไม่",
      onConfirm: confirmEndConversation,
    );
  }
}

// ==========================================
// 2. View: หน้า UI (รอแชท / พักแชท)
// ==========================================
class PauseChatPage extends StatelessWidget {
  PauseChatPage({super.key});

  // เรียกใช้ Controller ตัวใหม่
  final PauseChatController controller = Get.isRegistered<PauseChatController>()
      ? Get.find<PauseChatController>()
      : Get.put(PauseChatController());

  @override
  Widget build(BuildContext context) {
    // กำหนดโทนสีที่ดึงมาจากรูปภาพ
    const Color primaryBlue = Color(0xFF4A89D8);
    const Color outerPink = Color(0xFFFDF0F0); // วงกลมนอกสุด (สีอ่อนสุด)
    const Color middlePink = Color(0xFFF7D8D8); // วงกลมกลาง
    const Color innerPink = Color(0xFFF3BDBD); // วงกลมใน (เข้มสุด)
    const Color buttonYellow = Color(0xFFFFD54F);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),

            // --- ส่วนที่ 1: AppBar จำลอง (ปุ่ม Back + หัวข้อ) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.grey[700],
                        size: 24,
                      ),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const Text(
                    "มีคนกำลังรอแชทกับคุณ",
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // --- ส่วนที่ 2: ชื่อ User ---
            const Text(
              "kkkkk",
              style: TextStyle(
                color: primaryBlue,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            // --- ส่วนที่ 3: วงกลมซ้อนกัน (Avatar) ---
            Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  color: outerPink,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: const BoxDecoration(
                      color: middlePink,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          color: innerPink,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          // รูปภาพแมงกะพรุน
                          child: ClipOval(
                            child: NetworkImage(
                              'assets/images/jellyfish.png', 
                              width: 170,
                              height: 170,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 170,
                                    height: 170,
                                    color: Colors.black87,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 80,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),

            // --- ส่วนที่ 4: ปุ่มจบสนทนา ---
            GestureDetector(
              onTap: controller.showEndConversationDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: buttonYellow,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  "จบสนทนา",
                  style: TextStyle(
                    color: Color(0xFF7A7A7A), // สีเทาเข้ม
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

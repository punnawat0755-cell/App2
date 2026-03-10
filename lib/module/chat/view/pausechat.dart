import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/chat/view/chat_view.dart';
import 'package:get/get.dart';
// อย่าลืมเช็ค path ของไฟล์เหล่านี้ให้ตรงกับโปรเจกต์ของคุณด้วยนะครับ
import 'package:flutter_application_1/module/chat/view/feedback_page.dart';
import 'package:flutter_application_1/module/chat/view/chatconfirmdialog.dart';

// ==========================================
// 1. Controller: นำระบบ Timer จากหน้าสีฟ้ามาใส่
// ==========================================
class PauseChatController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final AnimationController animationController;
  Timer? timer; // 💡 ตัวแปรสำหรับจับเวลา

  @override
  void onInit() {
    super.onInit();
    // แอนิเมชันคลื่นสมูทๆ
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    startTimer(); // 💡 เริ่มจับเวลาทันทีที่เปิดหน้านี้
  }

  // 💡 ฟังก์ชันเริ่มจับเวลา 5 วินาที
  void startTimer() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 6), () {
      Get.off(() => ChatPage()); // ครบ 6 วิ ให้ไปหน้า Chat
    });
  }

  // 💡 ฟังก์ชันแสดง Popup (ทำงานเหมือนหน้าสีฟ้าเป๊ะ)
  void showExitDialog(BuildContext context) {
    timer?.cancel(); // หยุดเวลาชั่วคราวตอนที่ Popup เด้งขึ้นมา
    showChatConfirmDialog(
      title: "คุณต้องการที่จะออกจากบทสนทนา\nใช่หรือไม่",
      barrierDismissible: false, // บังคับให้ต้องกดปุ่มยืนยัน/ยกเลิกเท่านั้น
      onConfirm: () {
        Get.back(); // ปิด Popup
        Get.to(() => FeedbackPage()); // ยืนยันจบสนทนา ไปหน้า feedback
      },
      onCancel: () {
        Get.back(); // ปิด Popup
        startTimer(); // ถ้ายกเลิก ให้กลับมาจับเวลาต่อ
      },
    );
  }

  @override
  void onClose() {
    animationController.dispose();
    timer?.cancel(); // ทำลาย Timer ทิ้งเมื่อปิดหน้า
    super.onClose();
  }
}

// ==========================================
// 2. View: หน้า UI (ธีมสีชมพู แต่ทำงานเหมือนสีฟ้า)
// ==========================================
class PauseChatPage extends StatelessWidget {
  PauseChatPage({super.key});

  final PauseChatController controller = Get.isRegistered<PauseChatController>()
      ? Get.find<PauseChatController>()
      : Get.put(PauseChatController());

  static const Color primaryBlue = Color(0xFF4A89D8);
  static const Color innerPink = Color(0xFFF3BDBD);
  static const Color buttonYellow = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        controller.showExitDialog(
          context,
        ); // เรียก Popup ถ้ายูสเซอร์พยายามกด Back
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 15),

              // --- ส่วนที่ 1: AppBar จำลอง ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Image.asset(
                        'assets/images/back.png',
                        width: 25,
                        height: 25,
                      ),
                      onPressed: () =>
                          controller.showExitDialog(context), // 💡 ผูกกับ Popup
                    ),
                    // const SizedBox(width: 0),
                    const Expanded(
                      child: Text(
                        "มีคนกำลังรอแชทกับคุณ",
                        style: TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 70),

              // --- ส่วนที่ 2: ชื่อ User ---
              const Center(
                // 💡 เอา Center มาครอบ Text ไว้
                child: Text(
                  "แมวน้ำ",
                  style: TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- ส่วนที่ 3: Avatar + คลื่นสมูทๆ ---
              Center(
                child: SizedBox(
                  width: 350,
                  height: 350,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildOneWayRipple(0.0),
                      _buildOneWayRipple(0.33),
                      _buildOneWayRipple(0.66),

                      Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          color: innerPink,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                'https://images.unsplash.com/photo-1548681528-6a5c45b66b42?auto=format&fit=crop&w=600&q=80',
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // 💡 ฟังก์ชันสร้างคลื่นสีชมพู
  // ==============================================================
  Widget _buildOneWayRipple(double startDelay) {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        final double rawT =
            (controller.animationController.value + startDelay) % 1.0;
        final double t = Curves.easeOut.transform(rawT);
        final double currentSize = 210 + (140 * t);
        final double opacity = 0.5 * (1.0 - rawT);

        return Container(
          width: currentSize,
          height: currentSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF3BDBD).withOpacity(opacity),
            border: Border.all(
              color: Colors.white.withOpacity(opacity * 0.8),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }
}

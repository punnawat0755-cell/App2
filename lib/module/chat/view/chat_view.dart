import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ---------------------------------------------------------
// 1. Controller
// ---------------------------------------------------------
class ChatSelectionController extends GetxController {
  void goToStartChat() {
    print("User clicked: Start Chat");
    // Get.to(() => StartChatPage());
  }

  void goToCounseling() {
    print("User clicked: Give Counseling");
    // Get.to(() => CounselingPage());
  }
}

// ---------------------------------------------------------
// 2. Page
// ---------------------------------------------------------
class ChatSelectionPage extends StatelessWidget {
  const ChatSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatSelectionController());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: SafeArea(
        child: Stack(
          children: [
            // --- รูปโปรไฟล์มุมขวาบน ---
            Positioned(
              top: 15,
              right: 25,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // --- เนื้อหาตรงกลาง ---
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'มาแชทกันเถอะ มีคนรอคุณอยู่ในแชท',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4489D7),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ส่วนปุ่มครึ่งวงกลม 2 อัน
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: SizedBox(
                      height: 300,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ---------------------------------------------------
                          // [ปุ่มฝั่งซ้าย] เริ่มแชท (คนร้องไห้)
                          // ---------------------------------------------------
                          _buildHalfCircleButton(
                            title: 'เริ่มแชท',
                            imagePath: 'assets/images/sad.png',
                            backgroundColor: const Color(0xFFAEDEF4),
                            textColor: const Color(0xFF4489D7),
                            isLeft: true,
                            onTap: controller.goToStartChat,

                            // --- [ตั้งค่าฝั่งซ้าย] ---
                            // ขยับรูป: top=ลง, bottom=ขึ้น, left=ขวา, right=ซ้าย
                            imagePadding: const EdgeInsets.only(
                              top: 20,
                              left: 20,
                            ),
                            imageScale: 0.9,
                          ),

                          const SizedBox(width: 9),

                          // ---------------------------------------------------
                          // [ปุ่มฝั่งขวา] ให้คำปรึกษา (คนยิ้ม)
                          // ---------------------------------------------------
                          _buildHalfCircleButton(
                            title: 'ให้คำปรึกษา',
                            imagePath: 'assets/images/fine.png',
                            backgroundColor: const Color(0xFFFDE6A8),
                            textColor: const Color(0xFF8D6E63),
                            isLeft: false,
                            onTap: controller.goToCounseling,

                            // --- [ตั้งค่าฝั่งขวา] ---
                            // แยกอิสระจากฝั่งซ้าย อยากขยับแค่ฝั่งนี้แก้ตรงนี้
                            imagePadding: const EdgeInsets.only(
                              top: 9,
                              right: 4,
                            ),
                            imageScale:
                                0.7, // เช่น อยากให้ฝั่งนี้ตัวใหญ่กว่าหน่อย
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget สร้างปุ่ม (รองรับการตั้งค่าแยก)
  Widget _buildHalfCircleButton({
    required String title,
    required String imagePath,
    required Color backgroundColor,
    required Color textColor,
    required bool isLeft,
    required VoidCallback onTap,
    EdgeInsetsGeometry? imagePadding,
    double imageScale = 1.0,
  }) {
    const double radius = 2000;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: isLeft
                ? const BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    bottomLeft: Radius.circular(radius),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(radius),
                    bottomRight: Radius.circular(radius),
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Layer รูปภาพ
              Positioned.fill(
                bottom: 50,
                child: Padding(
                  padding: imagePadding ?? const EdgeInsets.all(15.0),
                  child: Transform.scale(
                    scale: imageScale,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          isLeft
                              ? Icons.sentiment_dissatisfied
                              : Icons.sentiment_satisfied_alt,
                          size: 80,
                          color: Colors.white.withOpacity(0.5),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Layer ข้อความ
              Positioned(
                bottom: 25,
                left: 0,
                right: 0,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

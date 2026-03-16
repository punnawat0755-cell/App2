import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --------------------------------------------------------
// 1. GetX Controller สำหรับจัดการ State
// --------------------------------------------------------
class QuizController extends GetxController {
  // -1 หมายถึงยังไม่ได้เลือกตัวเลือกใดเลย
  var selectedIndex = (-1).obs;

  void selectOption(int index) {
    selectedIndex.value = index;
  }
}

class QuizSelectionResult {
  const QuizSelectionResult({
    required this.selectedIndex,
    required this.selectedAnswer,
  });

  final int selectedIndex;
  final String selectedAnswer;
}

// --------------------------------------------------------
// 2. หน้าจอควิซหลัก
// --------------------------------------------------------
class QuizScreen extends StatelessWidget {
  QuizScreen({super.key});

  // เรียกใช้งาน Controller
  final QuizController controller = Get.put(QuizController());

  // รายการคำตอบ
  final List<String> options = ["ระเบิด", "ต้นไม้", "มือสองข้าง", "ค้างคาว"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // หัวข้อ
                Text(
                  "คุณเห็นอะไรในภาพนี้\nเป็นอย่างแรก",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4489D7),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 25),

                // รูปภาพ
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/quiz.png',
                      width: 230,
                      height: 270,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // เครดิตรูปภาพ (ตัวเล็กๆ ใต้รูป)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "ขอบคุณข้อมูลจาก : lovecampus honghongworld",
                    style: TextStyle(fontSize: 8, color: Color(0xFF4489D7)),
                  ),
                ),
                const SizedBox(height: 20),

                // ข้อความก่อนปุ่มเลือก
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      "โปรดเลือกคำตอบของคุณ", // อ้างอิงคำตามรูปภาพ
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4489D7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // สร้างปุ่มตัวเลือก
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    return _buildOptionButton(
                      context,
                      index,
                      options[index],
                      const Color(0xFF4489D7),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // 3. Widget สำหรับปุ่มแต่ละปุ่ม (เชื่อมกับ GetX)
  // --------------------------------------------------------
  Widget _buildOptionButton(
    BuildContext context,
    int index,
    String title,
    Color textColor,
  ) {
    return Obx(() {
      // ตรวจสอบว่าปุ่มนี้ถูกเลือกอยู่หรือไม่
      bool isSelected = controller.selectedIndex.value == index;

      return GestureDetector(
        onTap: () {
          controller.selectOption(index);
          Navigator.of(context).pop(
            QuizSelectionResult(
              selectedIndex: index,
              selectedAnswer: title,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          decoration: BoxDecoration(
            // สลับสีพื้นหลังถ้าถูกเลือก (ให้เหมือนปุ่ม 'มือสองข้าง' ในรูป)
            color:
                isSelected ? const Color(0xFF9CE2FE) : const Color(0xFFD6F0FF),
            borderRadius: BorderRadius.circular(30), // ขอบมนเป็นแคปซูล
            border: Border.all(
              color: const Color(0xFF86A8D6), // สีขอบปุ่ม
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 3),
                blurRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:get/get.dart';

class _RoleQuizController extends GetxController {
  var selectedIndex = (-1).obs;

  void selectOption(int index) {
    selectedIndex.value = index;
  }
}

class RoleQuizSelectionResult {
  const RoleQuizSelectionResult({
    required this.selectedIndex,
    required this.selectedAnswer,
  });

  final int selectedIndex;
  final String selectedAnswer;
}

class RoleQuizPage extends StatelessWidget {
  RoleQuizPage({super.key});

  final _RoleQuizController _controller = Get.put(_RoleQuizController());
  final List<String> _options = ["ระเบิด", "ต้นไม้", "มือสองข้าง", "ค้างคาว"];

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final imageWidth = (screenWidth - 80).clamp(180.0, 260.0);
    final optionHorizontalMargin = screenWidth < 360 ? 16.0 : 40.0;

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
                Text(
                  "คุณเห็นอะไรในภาพนี้\nเป็นอย่างแรก",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: scale.rf(26, min: 22, max: 26),
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4489D7),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 25),
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
                      width: imageWidth,
                      height: imageWidth * 1.17,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "ขอบคุณข้อมูลจาก : lovecampus honghongworld",
                    style: TextStyle(
                      fontSize: scale.rf(8, min: 7.5, max: 8.5),
                      color: Color(0xFF4489D7),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      "โปรดเลือกคำตอบของคุณ",
                      style: TextStyle(
                        fontSize: scale.rf(16, min: 14, max: 16.5),
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4489D7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    return _buildOptionButton(
                      context,
                      index,
                      _options[index],
                      const Color(0xFF4489D7),
                      horizontalMargin: optionHorizontalMargin,
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

  Widget _buildOptionButton(
      BuildContext context, int index, String title, Color textColor,
      {required double horizontalMargin}) {
    return Obx(() {
      final isSelected = _controller.selectedIndex.value == index;

      return GestureDetector(
        onTap: () {
          _controller.selectOption(index);
          Navigator.of(context).pop(
            RoleQuizSelectionResult(
              selectedIndex: index,
              selectedAnswer: title,
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: horizontalMargin,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFF9CE2FE) : const Color(0xFFD6F0FF),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFF86A8D6),
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

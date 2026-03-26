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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
            final isCompact = constraints.maxWidth < 360;
            final isShort = constraints.maxHeight < 760;

            final horizontalPadding = scale.rs(
              isCompact ? 16 : 22,
              min: 14,
              max: 28,
            );
            final verticalPadding = scale.rs(
              isShort ? 20 : 34,
              min: 16,
              max: 40,
            );
            final contentWidth =
                (constraints.maxWidth - (horizontalPadding * 2))
                    .clamp(180.0, 520.0)
                    .toDouble();
            final imageWidth = (contentWidth * (isCompact ? 0.76 : 0.64))
                .clamp(150.0, 250.0)
                .toDouble();
            final optionHorizontalMargin = scale.rs(
              isCompact ? 4 : 18,
              min: 2,
              max: 28,
            );
            final optionVerticalMargin = scale.rs(7, min: 5, max: 9);
            final imageRadius = scale.rs(18, min: 14, max: 22);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "คุณเห็นอะไรในภาพนี้\nเป็นอย่างแรก",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: scale.rf(26, min: 21, max: 26),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4489D7),
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: scale.rs(isShort ? 16 : 24)),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(imageRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: scale.rs(10, min: 8, max: 12),
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(imageRadius),
                            child: Image.asset(
                              'assets/images/quiz.png',
                              width: imageWidth,
                              height: imageWidth * 1.17,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: scale.rs(6, min: 4, max: 8)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "ขอบคุณข้อมูลจาก : lovecampus honghongworld",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: scale.rf(8, min: 7.2, max: 8.5),
                              color: const Color(0xFF4489D7),
                            ),
                          ),
                        ),
                        SizedBox(height: scale.rs(isShort ? 14 : 20)),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: scale.rs(10, min: 6, max: 16),
                            ),
                            child: Text(
                              "โปรดเลือกคำตอบของคุณ",
                              style: TextStyle(
                                fontSize: scale.rf(16, min: 14, max: 16.5),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4489D7),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: scale.rs(12, min: 10, max: 16)),
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
                              verticalMargin: optionVerticalMargin,
                              scale: scale,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptionButton(
      BuildContext context, int index, String title, Color textColor,
      {required double horizontalMargin,
      required double verticalMargin,
      required ResponsiveScale scale}) {
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
            vertical: verticalMargin,
            horizontal: horizontalMargin,
          ),
          padding: EdgeInsets.symmetric(
            vertical: scale.rs(13.5, min: 11, max: 16),
            horizontal: scale.rs(14, min: 10, max: 20),
          ),
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFF9CE2FE) : const Color(0xFFD6F0FF),
            borderRadius: BorderRadius.circular(
              scale.rs(28, min: 22, max: 32),
            ),
            border: Border.all(
              color: const Color(0xFF86A8D6),
              width: scale.rs(1.3, min: 1, max: 1.8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 3),
                blurRadius: scale.rs(5, min: 4, max: 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: scale.rf(17, min: 14.5, max: 18),
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

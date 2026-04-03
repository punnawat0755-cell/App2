import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/chat/view/chat_view.dart';
import 'package:flutter_application_1/module/chat/view/bot_chat_view.dart';
import 'package:get/get.dart';

class ChatWithBotScreen extends StatelessWidget {
  const ChatWithBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            final horizontalPadding = screenWidth < 360
                ? 16.0
                : screenWidth < 600
                ? 24.0
                : 32.0;
            final contentMaxWidth = screenWidth > 700 ? 560.0 : double.infinity;
            final titleFontSize = screenWidth < 360
                ? 18.0
                : screenWidth < 600
                ? 20.0
                : 24.0;
            final cardVerticalPadding = screenWidth < 360
                ? 18.0
                : screenWidth < 600
                ? 24.0
                : 28.0;
            final iconHeight = screenWidth < 360
                ? 52.0
                : screenWidth < 600
                ? 68.0
                : 80.0;
            final cardTitleFontSize = screenWidth < 360
                ? 15.0
                : screenWidth < 600
                ? 17.0
                : 18.0;
            final titleSpacing = screenHeight < 700 ? 24.0 : 40.0;
            final cardSpacing = screenHeight < 700 ? 16.0 : 24.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight - 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SpacerWidget(),
                        Text(
                          "คุณรอนานเกินไปแล้วนะ\nคุณอยากคุยกับแชทบอทก่อนไหม",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4489D7),
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: titleSpacing),
                        _buildChoiceCard(
                          title: "แชทกับบอท",
                          imagePath: "assets/images/robot.png",
                          fallbackIcon: Icons.smart_toy_rounded,
                          bgColor: const Color(0xFFDBEFFB),
                          borderColor: const Color(0xFFA8CEE6),
                          textColor: const Color(0xFF4A80C5),
                          padding: cardVerticalPadding,
                          iconHeight: iconHeight,
                          fontSize: cardTitleFontSize,
                          onTap: () {
                            Get.to(() => BotChatPage());
                          },
                        ),
                        SizedBox(height: cardSpacing),
                        _buildChoiceCard(
                          title: "คุยกับที่ปรึกษา",
                          imagePath: "assets/images/embrace.png",
                          fallbackIcon: Icons.volunteer_activism,
                          bgColor: const Color(0xFFF1D483),
                          borderColor: const Color(0xFFC7AA59),
                          textColor: const Color(0xFF5C4018),
                          padding: cardVerticalPadding,
                          iconHeight: iconHeight,
                          fontSize: cardTitleFontSize,
                          onTap: () {
                            Get.to(() => ChatPage());
                          },
                        ),
                        const SpacerWidget(),
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

  // --- Widget ย่อย: กล่องตัวเลือก ---
  Widget _buildChoiceCard({
    required String title,
    required String imagePath,
    required IconData fallbackIcon,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required double padding,
    required double iconHeight,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: padding),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20), // ขอบมน
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, 6),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath,
              height: iconHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(fallbackIcon, size: iconHeight, color: textColor),
            ),
            const SizedBox(height: 16),
            // ข้อความ
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpacerWidget extends StatelessWidget {
  const SpacerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 12);
  }
}

// Single File Implementation (Assessment 5 Steps)
import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/home/view/home_view.dart';
import 'package:flutter_application_1/module/test/view/coin_view.dart';
import 'package:get/get.dart';

// ========================================================
// 1. Controller สำหรับจัดการ State ของหน้าประเมิน
// ========================================================
class MoodTestController extends GetxController {
  // 💡 สร้างชุดข้อมูลคำถามทั้ง 5 ข้อตามลำดับรูปภาพ
  final List<Map<String, dynamic>> assessmentData = [
    {
      "question": "ช่วงสัปดาห์ที่ผ่านมา\nสภาพคลื่นหัวใจของคุณเป็นแบบไหนเอ่ย?",
      "options": [
        {
          "icon": "assets/images/m1.png",
          "localIcon": "🌊",
          "text": "คลื่นสงบ: สดใส จัดการอารมณ์ได้ดี",
          "score": 1,
        },
        {
          "icon": "assets/images/m2.png",
          "localIcon": "🛶",
          "text": "ลอยคอเรื่อยๆ: ปกติทั่วไป ไม่มีอะไรหวือหวา",
          "score": 2,
        },
        {
          "icon": "assets/images/m3.png",
          "localIcon": "🌧️",
          "text": "ฝนตกปรอยๆ: เหนื่อยล้า อ่อนไหวง่ายกว่าปกติ",
          "score": 3,
        },
        {
          "icon": "assets/images/m4.png",
          "localIcon": "🌪️",
          "text": "พายุเข้า: หนักอึ้ง เครียด ต้องการคนรับฟังด่วน",
          "score": 4,
        },
      ],
    },
    {
      "question":
          "สิ่งที่คุณคาดหวังที่สุดจากการเข้ามาในแอป\nHow are you คืออะไร?",
      "options": [
        {
          "icon": "assets/images/m5.png",
          "localIcon": "📝",
          "text": "อยากมีพื้นที่ปลอดภัยไว้บ่น/ระบายอารมณ์",
          "score": 1,
        },
        {
          "icon": "assets/images/m6.png",
          "localIcon": "🤲",
          "text": "อยากเป็นผู้ฟังและให้คำปรึกษาคนอื่น",
          "score": 2,
        },
        {
          "icon": "assets/images/m7.png",
          "localIcon": "🎬",
          "text": "อยากหาพลังบวกจากบทความและคลิปสั้นๆ",
          "score": 3,
        },
        {
          "icon": "assets/images/m8.png",
          "localIcon": "🐳",
          "text": "อยากหนีความวุ่นวายมาเลี้ยงสัตว์น้ำเพลินๆ",
          "score": 4,
        },
      ],
    },
    {
      "question": "วันนี้ระดับพลังงานในการเข้าสังคมของคุณ\nอยู่ที่ระดับไหน?",
      "options": [
        {
          "icon": "assets/images/m9.png",
          "localIcon": "🔋",
          "text": "ชาร์จเต็ม 100%: พร้อมคุย พร้อมแชร์เรื่องราว",
          "score": 1,
        },
        {
          "icon": "assets/images/m10.png",
          "localIcon": "🪫",
          "text": "แบตเตอรี่ต่ำ : ขออยู่เงียบๆ คนเดียวสักพัก",
          "score": 2,
        },
        {
          "icon": "assets/images/m11.png",
          "localIcon": "❤️‍🩹",
          "text": "โหมดประหยัดพลังงาน: อยากคุยนะ\nแต่ขอพิมพ์อย่างเดียว",
          "score": 3,
        },
      ],
    },
    {
      "question":
          "เรื่องไหนที่มักจะกวนใจและทำให้คุณ\nใช้พลังงานเยอะที่สุดในช่วงนี้?",
      "options": [
        {
          "icon": "assets/images/m12.png",
          "localIcon": "🎒",
          "text": "การเรียน / การทำงาน",
          "score": 1,
        },
        {
          "icon": "assets/images/m13.png",
          "localIcon": "💔",
          "text": "ความสัมพันธ์ / คนรอบข้าง",
          "score": 2,
        },
        {
          "icon": "assets/images/m14.png",
          "localIcon": "💸",
          "text": "การเงิน / อนาคต",
          "score": 3,
        },
        {
          "icon": "assets/images/m15.png",
          "localIcon": "🧠",
          "text": "ความกดดันจากตัวเอง",
          "score": 4,
        },
      ],
    },
    {
      "question":
          "สุดท้ายแล้ว... ช่วงนี้คุณภาพการนอนหลับ\nของคุณเป็นอย่างไรบ้าง?",
      "options": [
        {
          "icon": "assets/images/m16.png",
          "localIcon": "😴",
          "text": "หลับลึก ตื่นมาสดชื่น",
          "score": 1,
        },
        {
          "icon": "assets/images/m17.png",
          "localIcon": "😫",
          "text": "หลับๆ ตื่นๆ รู้สึกพักผ่อนไม่พอ",
          "score": 2,
        },
        {
          "icon": "assets/images/m18.png",
          "localIcon": "🦉",
          "text": "หัวแล่นตอนดึก นอนไม่ค่อยหลับ",
          "score": 3,
        },
      ],
    },
  ];

  var currentStep = 1.obs;
  final int totalSteps = 5;

  var selectedIndex = (-1).obs;
  var isProcessing = false.obs;

  // ตัวแปรสำหรับเก็บคะแนนสะสม
  var totalScore = 0.obs;
  List<Map<String, dynamic>> userAnswers = [];

  void selectOption(int index, int score, String text) {
    if (isProcessing.value) return;

    selectedIndex.value = index;
    isProcessing.value = true;

    // บันทึกคำตอบ
    userAnswers.add({
      "question": currentStep.value,
      "answer": text,
      "score": score,
    });
    totalScore.value += score;

    Future.delayed(const Duration(milliseconds: 600), () {
      currentStep.value++;
      selectedIndex.value = -1;

      if (currentStep.value > totalSteps) {
        // 💡 เมื่อ currentStep = 6 (วาฬชนหีบแล้ว)

        Get.off(
          () => const CoinRewardScreen(),
          transition: Transition
              .cupertino, // 💡 ใช้สไตล์สไลด์แบบ iOS (สมูทมากและภาพไม่จาง)
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
        );
      } else {
        isProcessing.value = false;
      }
    });
  }

  void skipTest() {
    Get.to(() => HomePage());
  }
}

// ========================================================
// 2. View หน้าจอ UI
// ========================================================
class MoodTestScreen extends StatelessWidget {
  MoodTestScreen({Key? key}) : super(key: key);

  final MoodTestController controller = Get.put(MoodTestController());

  // กำหนดชุดสีหลัก
  final Color mainTextColor = const Color(0xFF5384D6);
  final Color buttonUnselectedColor = const Color(0xFFD9F0FF);
  final Color buttonSelectedColor = const Color(0xFF8BE2FB);
  final Color buttonBorderColor = const Color(0xFF8BB5DF);
  final Color progressBarBgColor = const Color(0xFFD9F0FF);
  final Color progressBarFillColor = const Color(0xFF6AB6EB);

  @override
  Widget build(BuildContext context) {
    // 💡 1. ดึงขนาดหน้าจอมาเพื่อทำ Responsive
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 760;

    // 💡 2. ปรับตัวแปรต่างๆ ให้ยืดหยุ่นตามหน้าจอ
    final questionFontSize = isSmallScreen ? 18.0 : 20.0;
    final topQuestionSpacing = isSmallScreen ? 16.0 : 36.0;
    final questionOptionsSpacing = isSmallScreen ? 16.0 : 28.0;
    final verticalPaddingMain = isSmallScreen ? 10.0 : 14.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: verticalPaddingMain,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Progress Bar
              _buildProgressBar(),

              SizedBox(height: topQuestionSpacing),

              // 2. ข้อความหัวข้อ
              Obx(() {
                // ป้องกัน Error เวลาเข้าเส้นชัย (สเตป 6) ให้ค้างคำถามข้อ 5 ไว้
                int safeIndex = controller.currentStep.value - 1;
                if (safeIndex >= controller.totalSteps) {
                  safeIndex = controller.totalSteps - 1;
                }

                String currentQuestion =
                    controller.assessmentData[safeIndex]["question"];
                return Text(
                  currentQuestion,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: questionFontSize,
                    fontWeight: FontWeight.bold,
                    color: mainTextColor,
                    height: 1.35,
                  ),
                );
              }),

              SizedBox(height: questionOptionsSpacing),

              // 3. ปุ่มตัวเลือก
              Expanded(
                child: Obx(() {
                  // ป้องกัน Error เวลาเข้าเส้นชัย (สเตป 6) เช่นเดียวกัน
                  int safeIndex = controller.currentStep.value - 1;
                  if (safeIndex >= controller.totalSteps) {
                    safeIndex = controller.totalSteps - 1;
                  }

                  List<dynamic> currentOptions =
                      controller.assessmentData[safeIndex]["options"];

                  // 💡 ลดระยะห่างระหว่างปุ่มถ้าจอเล็ก
                  final gap = isSmallScreen
                      ? (currentOptions.length >= 4 ? 6.0 : 10.0)
                      : (currentOptions.length >= 4 ? 10.0 : 14.0);

                  return Column(
                    children: List.generate(currentOptions.length, (index) {
                      var option = currentOptions[index];
                      bool isSelected = controller.selectedIndex.value == index;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: index == currentOptions.length - 1
                                ? 0
                                : gap,
                          ),
                          child: _buildMoodOption(
                            index: index,
                            iconStr: option['icon'] ?? '',
                            localIconStr: option['localIcon'] ?? '',
                            text: option['text'] ?? '',
                            score: option['score'] ?? 0,
                            isSelected: isSelected,
                            optionCount: currentOptions.length,
                            isSmallScreen:
                                isSmallScreen, // ส่ง isSmallScreen เข้าไปคำนวณในฟังก์ชันปุ่ม
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
              SizedBox(height: 15),

              // 4. ปุ่ม "ข้าม"
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: controller.skipTest,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: buttonUnselectedColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "ข้าม",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: mainTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget ย่อย: Progress Bar ---
  Widget _buildProgressBar() {
    return Obx(() {
      double percent =
          (controller.currentStep.value - 1) / controller.totalSteps;
      if (percent > 1.0) percent = 1.0;
      if (percent < 0.0) percent = 0.0;

      return Container(
        height: 54,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth;

            const double outerHeight = 25.0;
            const double trackInset = 5.0;
            const double chestWidth = 50.0;
            const double whaleWidth = 55.0;
            const double whaleLeftPadding = 8.0;
            final double trackHeight = outerHeight - (trackInset * 2);

            // 1. คำนวณตำแหน่งซ้ายสุดของน้องวาฬก่อน
            final double maxWhaleLeft = maxWidth - chestWidth - whaleWidth;
            final double whaleLeft =
                whaleLeftPadding +
                ((maxWhaleLeft - whaleLeftPadding) * percent);

            // 💡 2. แก้ปัญหาหลอดสีฟ้าทะลุหน้า: ผูกความยาวหลอดเข้ากับตัวปลาวาฬเลย!
            // เอาตำแหน่งปลาวาฬ + ครึ่งนึงของความกว้างปลาวาฬ (whaleWidth * 0.5)
            // ทำให้ปลายหลอดสีฟ้า ซ่อนอยู่หลังช่วงกลางลำตัวปลาวาฬตลอดเวลา
            final double fillWidth = whaleLeft + (whaleWidth * 0.5);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // เลเยอร์ 1: พื้นหลังหลอด + เส้นขอบสีขาว (รวมร่างกันจะได้ไม่ทับวาฬ)
                Positioned(
                  top: 7,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: outerHeight,
                    decoration: BoxDecoration(
                      color: progressBarBgColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // เลเยอร์ 2: หลอดสีฟ้าเข้มที่ใช้วิ่ง
                Positioned(
                  top: 7 + trackInset,
                  left: trackInset,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    width: fillWidth, // 💡 ใช้สมการใหม่ที่ผูกกับตัววาฬ
                    height: trackHeight,
                    decoration: BoxDecoration(
                      color: progressBarFillColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),

                // เลเยอร์ 3: หีบสมบัติ
                Positioned(
                  right: 6,
                  top: 0,
                  child: Image.asset(
                    "assets/images/treasure.png",
                    height: 40,
                    width: chestWidth,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(height: 50, width: chestWidth),
                  ),
                ),

                // เลเยอร์ 4: น้องวาฬ (อยู่บนสุดของ Stack จะได้ทับหลอดสีฟ้ามิดชิด)
                Positioned(
                  left: whaleLeft,
                  top: 1,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                    child: Image.asset(
                      'assets/images/whale_happy.png',
                      height: 42,
                      width: whaleWidth,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(height: 42, width: whaleWidth),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  // --- Widget ย่อย: ปุ่มเลือกอารมณ์ ---
  // 💡 รับค่า isSmallScreen เข้ามาเพื่อปรับแต่ง UI ด้านใน
  Widget _buildMoodOption({
    required int index,
    required String iconStr,
    required String localIconStr,
    required String text,
    required int score,
    required bool isSelected,
    required int optionCount,
    required bool isSmallScreen,
  }) {
    final bool isDenseLayout = optionCount >= 4;

    // 💡 ปรับขนาดต่างๆ ตามหน้าจอ
    final double verticalPadding = isSmallScreen
        ? (isDenseLayout ? 6 : 10)
        : (isDenseLayout ? 10 : 14);
    final double horizontalPadding = isSmallScreen
        ? 10
        : (isDenseLayout ? 12 : 14);
    final double iconHeight = isSmallScreen
        ? (isDenseLayout ? 35 : 45)
        : (isDenseLayout ? 45 : 55);
    final double textFontSize = isSmallScreen ? 14 : 16;
    final double spacing = isSmallScreen ? 4 : (isDenseLayout ? 6 : 8);

    return GestureDetector(
      onTap: () => controller.selectOption(index, score, text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
        decoration: BoxDecoration(
          color: isSelected ? buttonSelectedColor : buttonUnselectedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: buttonBorderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconStr,
              height: iconHeight,
              errorBuilder: (context, error, stackTrace) =>
                  Text(localIconStr, style: TextStyle(fontSize: iconHeight)),
            ),
            SizedBox(height: spacing),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: textFontSize,
                fontWeight: FontWeight.bold,
                color: mainTextColor,
                height: 1.2,
              ),
              maxLines: isDenseLayout
                  ? 2
                  : 3, // ถ้าข้อเยอะให้บังคับแสดงแค่ 2 บรรทัด
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

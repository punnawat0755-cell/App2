import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/navigation/bottom_nav_bar.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/features/role_logic/view/pages/role_selection_page.dart';
import 'package:get/get.dart';

class EncouragementPage extends StatefulWidget {
  const EncouragementPage({super.key});

  @override
  State<EncouragementPage> createState() => _EncouragementPageState();
}

class _EncouragementPageState extends State<EncouragementPage> {
  Future<void> _goToRoleSelection() async {
    await Get.to<void>(() => const RoleSelectionPage());
    if (!mounted) {
      return;
    }

    Get.offAll(() => const BottomNavBar());
  }

  @override
  Widget build(BuildContext context) {
    const Color cardBgColor = Color(0xFFD6F0FF);
    const Color textColor = Color(0xFF4489D7);
    const Color buttonColor = Color(0xFF20C2FF);
    const Color cardShadowColor = Color(0xFFF3DDBC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
            final horizontalPadding = constraints.maxWidth < 360
                ? scale.rs(18, min: 14, max: 18)
                : scale.rs(30, min: 20, max: 34);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Image.asset(
                          'assets/images/whaletop.png',
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          errorBuilder: (context, error, stackTrace) =>
                              SizedBox(
                            height: scale.rs(250, min: 180, max: 250),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: scale.rs(12, min: 8, max: 14),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(
                                scale.rs(25, min: 18, max: 25),
                              ),
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(
                                  scale.rs(25, min: 20, max: 25),
                                ),
                                border: Border.all(
                                  color: textColor.withValues(alpha: 0.3),
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
                              child: Text(
                                'การอนุญาตให้ตัวเอง "ไม่โอเค" บ้างไม่ใช่เรื่องผิด\n'
                                'และวันที่ท้องฟ้ามืดครึ้มก็ไม่ได้แปลว่าดวงอาทิตย์จะ\n'
                                'ดับสูญไปตลอดกาล ในช่วงเวลาที่อารมณ์ขุ่นมัว\n'
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
                                  fontSize: scale.rf(12.5, min: 11, max: 13),
                                  height: 1.6,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: scale.rs(20, min: 16, max: 20)),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: _goToRoleSelection,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: scale.rs(16, min: 12, max: 18),
                                    vertical: scale.rs(8, min: 7, max: 10),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      scale.rs(30, min: 24, max: 30),
                                    ),
                                  ),
                                  elevation: 5,
                                ),
                                child: Text(
                                  'ถัดไป',
                                  style: TextStyle(
                                    fontSize: scale.rf(14, min: 13, max: 15),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Image.asset(
                          'assets/images/whalebottom.png',
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          errorBuilder: (context, error, stackTrace) =>
                              SizedBox(
                            height: scale.rs(240, min: 180, max: 240),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/home/view/home_view.dart';
import 'package:flutter_application_1/module/rolelogic/view/widget/choice_card.dart';
import 'package:flutter_application_1/module/test/view/test_view.dart';
import 'package:get/get.dart';

// --------------------------------------------------------
// 1. GetX สำหรับจัดการสถานะการเลือก 
// --------------------------------------------------------
class RoleLogic extends GetxController {
  // ตัวแปรเก็บค่าการเลือก: '' (ยังไม่เลือก), 'yes' (ต้องการ), 'no' (ไม่ต้องการ)
  var selectedRole = ''.obs;

  void selectRole(String role) {
    selectedRole.value = role;
    print("User selected: $role");
  }
}

// --------------------------------------------------------
// 2. หน้าจอ UI หลัก
// --------------------------------------------------------
class RoleSelection extends StatelessWidget {
  RoleSelection({super.key});

  // เรียกใช้งานโดยใช้ชื่อตัวแปรว่า logic แทน controller
  final RoleLogic logic = Get.put(RoleLogic());

  @override
  Widget build(BuildContext context) {
    // กำหนดโทนสีที่ดึงมาจากรูปภาพ
    const Color bgColor = Colors.white; // สีพื้นหลังขาว
    const Color primaryTextColor = Color(0xFF5A85C4); // สีตัวอักษรสีฟ้าหลัก
    const Color cardYesColor = Color(0xFFAEE4FC); // สีฟลอร์การ์ด "ต้องการ"
    const Color cardNoColor = Color(0xFFF5D586); // สีฟลอร์การ์ด "ไม่ต้องการ"

    return Scaffold(
      backgroundColor: bgColor,
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
                // ==========================================
                // ส่วนที่ 1: หัวข้อหลักและคำบรรยาย
                // ==========================================
                const Text(
                  "วันนี้คุณต้องการที่จะเป็น\nผู้ให้คำปรึกษาไหม",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4489D7),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 70),

                const Text(
                  "กรุณากดที่รูปเพื่อเลือกคำตอบของคุณ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4489D7),
                  ),
                ),
                const SizedBox(height: 20),

                // ==========================================
                // ส่วนที่ 2: การ์ดตัวเลือก 2 ฝั่ง (ต้องการ / ไม่ต้องการ)
                // ==========================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // การ์ดฝั่งซ้าย: ต้องการ
                    Expanded(
                      child: ChoiceCard(
                        id: 'yes',
                        title: 'ต้องการ',
                        imagePath: 'assets/images/role_yes.png',
                        bgColor: cardYesColor,
                        textColor: Color(0xff4489D7),
                        selectedRole: logic.selectedRole,
                        onSelect: (id) {
                          logic.selectRole(id);
                          Get.off(() => QuizScreen());
                        },
                      ),
                    ),
                    const SizedBox(width: 20), // ระยะห่างระหว่างการ์ด
                    Expanded(
                      child: ChoiceCard(
                        id: 'no',
                        title: 'ไม่ต้องการ',
                        imagePath: 'assets/images/role_no.png',
                        bgColor: cardNoColor,
                        textColor: const Color(0xFFC49A3E),
                        selectedRole: logic.selectedRole,
                        onSelect: (id) {
                          logic.selectRole(id);
                          Get.off(() => HomePage());
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // ==========================================
                // ส่วนที่ 3: ข้อความอธิบายด้านล่าง
                // ==========================================
                const Text(
                  '"ผู้ให้คำปรึกษา" คือใคร? คือผู้ที่เป็น "พื้นที่ปลอดภัย"\n'
                  'สำหรับใครสักคนที่กำลังต้องการคนรับฟัง\n'
                  'ผู้ให้คำปรึกษาในแอปของเราพร้อมที่จะเปิดใจรับฟังปัญหา ความเครียด\n'
                  'หรือความไม่สบายใจของผู้รับคำปรึกษาผ่านทางแชท\n'
                  'โดยไม่มีการตัดสิน หน้าที่ของคุณคือการอยู่เคียงข้าง ให้กำลังใจ\n'
                  'และชวนมองมุมกลับเพื่อให้เขารู้สึกดีขึ้น\n'
                  'และเมื่อจบการให้คำปรึกษาในแต่ละครั้ง คุณจะได้รับ "คอยน์"\n'
                  'เป็นการตอบแทนสำหรับความใส่ใจที่คุณมอบให้',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF639CDD),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

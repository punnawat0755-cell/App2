import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  // สถานะของ Checkbox แต่ละอัน
  bool isTermsAccepted = true;
  bool isHealthDataAccepted = true;
  bool isChatDataAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              // หัวข้อหลัก
              const Text(
                "นโยบายความเป็นส่วนตัว",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4489D7), // สีน้ำเงินหลักของแอป
                ),
              ),
              const SizedBox(height: 40),

              // รายการข้อตกลงที่ 1
              _buildPolicyItem(
                title:
                    "ฉันยอมรับ [ข้อกำหนดและเงื่อนไข]\nและรับทราบ [นโยบายความเป็นส่วนตัว]",
                subtitle:
                    "แอปพลิเคชัน Howareyou ให้ความสำคัญอย่างยิ่งกับความเป็นส่วนตัวและความปลอดภัยของข้อมูลผู้ใช้งาน ท่านนโยบายฉบับนี้จัดทำขึ้นเพื่อชี้แจงรายละเอียดเกี่ยวกับการเก็บรวบรวมใช้และเปิดเผยข้อมูลของท่านตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล (PDPA)",
                hasReadMore: true,
                value: isTermsAccepted,
                onChanged: (val) => setState(() => isTermsAccepted = val!),
              ),

              const Divider(height: 40, color: Color(0xFFE0E0E0)),

              _buildPolicyItem(
                title:
                    "ฉันยินยอมให้เก็บรวบรวมและใช้ \"ข้อมูลสุขภาพ\" (เช่น รอบเดือน, บันทึกอารมณ์) เพื่อใช้ในการประมวลผลและวิเคราะห์สุขภาพจิตภายในแอปพลิเคชัน",
                value: isHealthDataAccepted,
                onChanged: (val) => setState(() => isHealthDataAccepted = val!),
              ),

              const Divider(height: 40, color: Color(0xFFE0E0E0)),

              _buildPolicyItem(
                title:
                    "ฉันยินยอมให้นำข้อมูลการสนทนาไปใช้เพื่อวิเคราะห์และพัฒนาคุณภาพการให้คำปรึกษา",
                value: isChatDataAccepted,
                onChanged: (val) => setState(() => isChatDataAccepted = val!),
              ),

              const Spacer(),

              // ปุ่ม Accept All
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Action เมื่อกดยอมรับทั้งหมด
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20C2FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Accept All",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Widget ช่วยสร้างรายการนโยบายแต่ละแถว
  Widget _buildPolicyItem({
    required String title,
    String? subtitle,
    bool hasReadMore = false,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom Checkbox
        Transform.scale(
          scale: 1.5,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF64BFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(color: Color(0xFF64BFFF), width: 2),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A89D8),
                  height: 1.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF639CDD),
                    height: 1.4,
                  ),
                ),
              ],
              if (hasReadMore)
                GestureDetector(
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "อ่านข้อมูลเพิ่มเติม",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4489D7),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

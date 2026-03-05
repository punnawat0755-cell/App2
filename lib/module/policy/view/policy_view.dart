import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacyPolicyController extends GetxController {
  final RxBool isTermsAccepted = false.obs;
  final RxBool isHealthDataAccepted = false.obs;
  final RxBool isChatDataAccepted = false.obs;

  bool get isAllAccepted =>
      isTermsAccepted.value &&
      isHealthDataAccepted.value &&
      isChatDataAccepted.value;
}

class PrivacyPolicyPage extends StatelessWidget {
  PrivacyPolicyPage({super.key});

  final PrivacyPolicyController controller =
      Get.isRegistered<PrivacyPolicyController>()
          ? Get.find<PrivacyPolicyController>()
          : Get.put(PrivacyPolicyController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'นโยบายความเป็นส่วนตัว',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4489D7),
                  ),
                ),
                const SizedBox(height: 25),
                _buildPolicyItem(
                  title:
                      'ฉันยอมรับ [ข้อกำหนดและเงื่อนไข]\nและรับทราบ [นโยบายความเป็นส่วนตัว]',
                  subtitle:
                      'แอปพลิเคชัน Howareyou ให้ความสำคัญอย่างยิ่งกับความเป็นส่วนตัวและความปลอดภัยของข้อมูลผู้ใช้งาน ท่านนโยบายฉบับนี้จัดทำขึ้นเพื่อชี้แจงรายละเอียดเกี่ยวกับการเก็บรวบรวมใช้และเปิดเผยข้อมูลของท่านตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล (PDPA)',
                  hasReadMore: true,
                  value: controller.isTermsAccepted.value,
                  onChanged: (val) => controller.isTermsAccepted.value = val ?? false,
                ),
                const Divider(height: 40, color: Color(0xFFE0E0E0)),
                _buildPolicyItem(
                  title:
                      'ฉันยินยอมให้เก็บรวบรวมและใช้ "ข้อมูลสุขภาพ" (เช่น รอบเดือน, บันทึกอารมณ์) เพื่อใช้ในการประมวลผลและวิเคราะห์สุขภาพจิตภายในแอปพลิเคชัน',
                  value: controller.isHealthDataAccepted.value,
                  onChanged: (val) =>
                      controller.isHealthDataAccepted.value = val ?? false,
                ),
                const Divider(height: 40, color: Color(0xFFE0E0E0)),
                _buildPolicyItem(
                  title:
                      'ฉันยินยอมให้นำข้อมูลการสนทนาไปใช้เพื่อวิเคราะห์และพัฒนาคุณภาพการให้คำปรึกษา',
                  value: controller.isChatDataAccepted.value,
                  onChanged: (val) => controller.isChatDataAccepted.value = val ?? false,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: controller.isAllAccepted
                        ? () {
                            print('กดยอมรับนโยบายครบถ้วนแล้ว');
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF20C2FF),
                      disabledBackgroundColor:
                          const Color(0xFF20C2FF).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'ยินยอม',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color:
                            controller.isAllAccepted ? Colors.white : Colors.white70,
                      ),
                    ),
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
        Transform.scale(
          scale: 1.5,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF64BFFF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                  onTap: () => Get.to(() => const PrivacyDetailPage()),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'อ่านข้อมูลเพิ่มเติม',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4489D7),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF4489D7),
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

class PrivacyDetailPage extends StatelessWidget {
  const PrivacyDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color contentColor = Color(0xFF639CDD);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: -9,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset('assets/images/back.png', width: 24, height: 24),
          ),
        ),
        title: const Text(
          'นโยบายความเป็นส่วนตัว',
          style: TextStyle(
            color: Color(0xFF4A89D8),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'แอปพลิเคชัน Howareyou ให้ความสำคัญอย่างยิ่งกับความเป็นส่วนตัวและความปลอดภัยของข้อมูลผู้ใช้งาน ท่านนโยบายฉบับนี้จัดทำขึ้นเพื่อชี้แจงรายละเอียดเกี่ยวกับการเก็บรวบรวมใช้และเปิดเผยข้อมูลของท่านตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล (PDPA)',
              style: TextStyle(fontSize: 15, color: contentColor, height: 1.4),
            ),
            const SizedBox(height: 10),
            _buildHeader('1. ข้อมูลที่เราเก็บรวบรวม'),
            _buildSectionText(
              'เราเก็บรวบรวมข้อมูลเพื่อให้บริการและพัฒนาประสบการณ์การใช้งาน โดยแบ่งเป็นประเภทดังนี้:',
              contentColor,
            ),
            _buildSubHeader('1.1 ข้อมูลส่วนบุคคลทั่วไป (General Personal Data)'),
            _buildBullet('ข้อมูลระบุตัวตน: ชื่อ, นามสกุล, วันเดือนปีเกิด, เพศ', contentColor),
            _buildBullet(
              'ข้อมูลบัญชีผู้ใช้: ชื่อผู้ใช้งาน (Username), รหัสผ่าน (ที่เข้ารหัสแล้ว), รูปโปรไฟล์',
              contentColor,
            ),
            _buildSubHeader('1.2 ข้อมูลส่วนบุคคลที่อ่อนไหว (Sensitive Personal Data)'),
            _buildSectionText(
              'เราจะเก็บรวบรวมข้อมูลเหล่านี้ก็ต่อเมื่อได้รับความยินยอมโดยชัดแจ้ง (Explicit Consent) จากท่านเท่านั้น:',
              contentColor,
            ),
            _buildBullet(
              'ข้อมูลสุขภาพ: ข้อมูลรอบเดือน (Menstruation cycle), อาการที่เกี่ยวข้องกับประจำเดือน (PMS/Physical symptoms)',
              contentColor,
            ),
            _buildBullet(
              'ข้อมูลสุขภาพจิตและพฤติกรรม: บันทึกอารมณ์ประจำวัน (Mood tracking), ผลแบบสอบถามด้านอารมณ์',
              contentColor,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4A89D8),
        ),
      ),
    );
  }

  static Widget _buildSubHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4A89D8),
        ),
      ),
    );
  }

  static Widget _buildSectionText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, color: color, height: 1.5),
    );
  }

  static Widget _buildBullet(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 14, color: color)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

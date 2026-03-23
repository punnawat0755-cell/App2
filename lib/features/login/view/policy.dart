import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// 1. หน้ากดยอมรับนโยบาย (Main Privacy Page)
// ==========================================
class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  // ปรับเป็น false ให้หมดเพื่อให้ผู้ใช้เป็นคนเลือกเองตามหลัก PDPA ครับ
  bool isTermsAccepted = false;
  bool isHealthDataAccepted = false;
  bool isChatDataAccepted = false;
  bool _isLoading = false;

  Future<void> _acceptPdpa() async {
    setState(() => _isLoading = true);
    try {
      final sb = Supabase.instance.client;
      final userId = sb.auth.currentUser!.id;

      await sb.from('profiles').update({
        'pdpa_accepted_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // เช็กว่าติ๊กครบทุกช่องหรือยัง
    bool isAllAccepted =
        isTermsAccepted && isHealthDataAccepted && isChatDataAccepted;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 20.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    10,
                    horizontalPadding,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "นโยบายความเป็นส่วนตัว",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4489D7),
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildPolicyItem(
                        title:
                            "ฉันยอมรับ [ข้อกำหนดและเงื่อนไข]\nและรับทราบ [นโยบายความเป็นส่วนตัว]",
                        subtitle:
                            "แอปพลิเคชัน Howareyou ให้ความสำคัญอย่างยิ่งกับความเป็นส่วนตัวและความปลอดภัยของข้อมูลผู้ใช้งาน ท่านนโยบายฉบับนี้จัดทำขึ้นเพื่อชี้แจงรายละเอียดเกี่ยวกับการเก็บรวบรวมใช้และเปิดเผยข้อมูลของท่านตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล (PDPA)",
                        hasReadMore: true,
                        value: isTermsAccepted,
                        onChanged: (val) =>
                            setState(() => isTermsAccepted = val!),
                      ),
                      const Divider(height: 40, color: Color(0xFFE0E0E0)),
                      _buildPolicyItem(
                        title:
                            "ฉันยินยอมให้เก็บรวบรวมและใช้ \"ข้อมูลสุขภาพ\" (เช่น รอบเดือน, บันทึกอารมณ์) เพื่อใช้ในการประมวลผลและวิเคราะห์สุขภาพจิตภายในแอปพลิเคชัน",
                        value: isHealthDataAccepted,
                        onChanged: (val) =>
                            setState(() => isHealthDataAccepted = val!),
                      ),
                      const Divider(height: 40, color: Color(0xFFE0E0E0)),
                      _buildPolicyItem(
                        title:
                            "ฉันยินยอมให้นำข้อมูลการสนทนาไปใช้เพื่อวิเคราะห์และพัฒนาคุณภาพการให้คำปรึกษา",
                        value: isChatDataAccepted,
                        onChanged: (val) =>
                            setState(() => isChatDataAccepted = val!),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          // ถ้าติ๊กครบถึงจะรันโค้ดในปีกกา ถ้าไม่ครบส่ง null เพื่อให้ปุ่ม Disabled
                          onPressed: isAllAccepted
                              ? (_isLoading ? null : _acceptPdpa)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF20C2FF),
                            // เพิ่มสีตอนกดไม่ได้ให้ดูจางลง ผู้ใช้จะได้รู้ว่าต้องทำอะไรต่อ
                            disabledBackgroundColor: const Color(
                              0xFF20C2FF,
                            ).withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "ยินยอม",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    // ปรับสีตัวอักษรตามสถานะปุ่ม
                                    color: isAllAccepted
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
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
                  onTap: () => Get.to(() => const PrivacyDetailPage()),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "อ่านข้อมูลเพิ่มเติม",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4489D7),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(
                          0xFF4489D7,
                        ), // ล็อกสีเส้นใต้ให้ตรงกันที่นี่ครับ
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

// ==========================================
// 2. หน้าใหม่: รายละเอียดนโยบายความเป็นส่วนตัว
// ==========================================
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
            child: Image.asset("assets/images/back.png", width: 24, height: 24),
          ),
        ),
        title: const Text(
          "นโยบายความเป็นส่วนตัว",
          style: TextStyle(
            color: Color(0xFF4A89D8),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 24.0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "แอปพลิเคชัน Howareyou ให้ความสำคัญอย่างยิ่งกับความเป็นส่วนตัวและความปลอดภัยของข้อมูลผู้ใช้งาน ท่านนโยบายฉบับนี้จัดทำขึ้นเพื่อชี้แจงรายละเอียดเกี่ยวกับการเก็บรวบรวมใช้และเปิดเผยข้อมูลของท่านตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล (PDPA)",
                      style: TextStyle(
                        fontSize: 15,
                        color: contentColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildHeader("1. ข้อมูลที่เราเก็บรวบรวม"),
                    _buildSectionText(
                      "เราเก็บรวบรวมข้อมูลเพื่อให้บริการและพัฒนาประสบการณ์การใช้งาน โดยแบ่งเป็นประเภทดังนี้:",
                      contentColor,
                    ),
                    _buildSubHeader(
                      "1.1 ข้อมูลส่วนบุคคลทั่วไป (General Personal Data)",
                    ),
                    _buildBullet(
                      "ข้อมูลระบุตัวตน: ชื่อ, นามสกุล, วันเดือนปีเกิด, เพศ",
                      contentColor,
                    ),
                    _buildBullet(
                      "ข้อมูลบัญชีผู้ใช้: ชื่อผู้ใช้งาน (Username), รหัสผ่าน (ที่เข้ารหัสแล้ว), รูปโปรไฟล์",
                      contentColor,
                    ),
                    _buildSubHeader(
                      "1.2 ข้อมูลส่วนบุคคลที่อ่อนไหว (Sensitive Personal Data)",
                    ),
                    _buildSectionText(
                      "เราจะเก็บรวบรวมข้อมูลเหล่านี้ก็ต่อเมื่อได้รับความยินยอมโดยชัดแจ้ง (Explicit Consent) จากท่านเท่านั้น:",
                      contentColor,
                    ),
                    _buildBullet(
                      "ข้อมูลสุขภาพ: ข้อมูลรอบเดือน (Menstruation cycle), อาการที่เกี่ยวข้องกับประจำเดือน (PMS/Physical symptoms)",
                      contentColor,
                    ),
                    _buildBullet(
                      "ข้อมูลสุขภาพจิตและพฤติกรรม: บันทึกอารมณ์ประจำวัน (Mood tracking), ผลแบบสอบถามด้านอารมณ์",
                      contentColor,
                    ),
                    _buildSubHeader("1.3 ข้อมูลการสนทนา (Chat Logs)"),
                    _buildBullet(
                      "เราทำการบันทึกข้อความการสนทนาระหว่าง \"ผู้ขอคำปรึกษา\" และ \"ผู้ให้คำปรึกษา\" ภายในแอปพลิเคชัน",
                      contentColor,
                    ),
                    const SizedBox(height: 10),
                    _buildHeader("2. วัตถุประสงค์การใช้ข้อมูล"),
                    _buildSectionText(
                      "เรานำข้อมูลของท่านไปใช้เพื่อวัตถุประสงค์ดังต่อไปนี้:",
                      contentColor,
                    ),
                    _buildBullet(
                      "เพื่อการให้บริการหลัก: ใช้คำนวณและคาดการณ์รอบเดือน, แสดงผลสถิติอารมณ์ย้อนหลัง, และจับคู่ผู้ให้คำปรึกษาที่เหมาะสม",
                      contentColor,
                    ),
                    _buildBullet(
                      "เพื่อการวิเคราะห์และพัฒนา (สำคัญ): เรานำข้อมูลการสนทนา (Chat Logs) มาวิเคราะห์ในภาพรวม (โดยไม่ระบุตัวตน) เพื่อทำความเข้าใจหัวข้อการสนทนาส่วนใหญ่ เทรนด์ของปัญหาด้านอารมณ์ และนำผลลัพธ์ไปปรับปรุงคุณภาพการให้คำปรึกษา หรือพัฒนาฟีเจอร์ใหม่ ๆ ในอนาคต",
                      contentColor,
                    ),
                    const SizedBox(height: 10),
                    _buildHeader("3. การเปิดเผยและส่งต่อข้อมูล"),
                    _buildBullet("ได้รับความยินยอมจากท่าน", contentColor),
                    _buildBullet(
                      "เป็นการปฏิบัติตามกฎหมาย หรือคำสั่งจากหน่วยงานรัฐ",
                      contentColor,
                    ),
                    const SizedBox(height: 10),
                    _buildHeader("4. การเก็บรักษาและความปลอดภัย"),
                    _buildBullet(
                      "เราจัดเก็บข้อมูลของท่านด้วยมาตรฐานความปลอดภัยทางเทคโนโลยี",
                      contentColor,
                    ),
                    _buildBullet(
                      "ข้อมูลสุขภาพและข้อมูลแชทจะถูกเก็บเป็นความลับอย่างเคร่งครัด",
                      contentColor,
                    ),
                    const SizedBox(height: 10),
                    _buildHeader("5. สิทธิของเจ้าของข้อมูลส่วนบุคคล"),
                    _buildBullet(
                        "สิทธิขอเข้าถึงและขอรับสำเนาข้อมูล", contentColor),
                    _buildBullet("สิทธิขอให้ลบหรือทำลายข้อมูล", contentColor),
                    _buildBullet("สิทธิในการถอนความยินยอม", contentColor),
                    const SizedBox(height: 10),
                    _buildHeader("6. ช่องทางการติดต่อ"),
                    _buildBullet("ผู้ดูแลแอปพลิเคชัน Howareyou", contentColor),
                    _buildBullet(
                        "บริษัท ไทเกอร์ซอฟท์ (1998) จำกัด", contentColor),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Helpers (ไม่มีการเปลี่ยนแปลงในส่วนนี้แต่รวมมาให้ครบ) ---
  Widget _buildHeader(String text) => Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF639CDD),
          ),
        ),
      );

  Widget _buildSubHeader(String text) => Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF639CDD),
          ),
        ),
      );

  Widget _buildSectionText(String text, Color textColor) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
        ),
      );

  Widget _buildBullet(String text, Color textColor) => Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "• ",
              style: TextStyle(
                color: Color(0xFF4A89D8),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
              ),
            ),
          ],
        ),
      );
}

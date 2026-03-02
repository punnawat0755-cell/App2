import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdpaDialog extends StatefulWidget {
  const PdpaDialog({super.key});

  @override
  State<PdpaDialog> createState() => _PdpaDialogState();
}

class _PdpaDialogState extends State<PdpaDialog> {
  bool _isLoading = false;
  bool _isTermsAccepted = false;
  bool _isHealthDataAccepted = false;
  bool _isChatDataAccepted = false;

  bool get _isAllAccepted =>
      _isTermsAccepted && _isHealthDataAccepted && _isChatDataAccepted;

  Future<void> _acceptPdpa() async {
    if (!_isAllAccepted) return;
    setState(() => _isLoading = true);
    try {
      final sb = Supabase.instance.client;
      final userId = sb.auth.currentUser!.id;

      // บันทึกเวลาลง DB
      await sb.from('profiles').update({
        'pdpa_accepted_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (!mounted) return;
      // ส่งค่า true กลับไปบอกหน้า Login ว่า "ยอมรับแล้ว"
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 8, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'นโยบายความเป็นส่วนตัว',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A89D8),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    // ส่งค่า false กลับไปบอกหน้า Login ว่า "ปฏิเสธ/ปิดหน้าต่าง"
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "แอปพลิเคชัน Howareyou ให้ความสำคัญอย่างยิ่งกับความเป็นส่วนตัวและความปลอดภัยของข้อมูลผู้ใช้งาน นโยบายฉบับนี้จัดทำขึ้นเพื่อชี้แจงรายละเอียดเกี่ยวกับการเก็บรวบรวม ใช้ และเปิดเผยข้อมูลของท่านตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล (PDPA)",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF639CDD),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPolicyItem(
                      title:
                          "ฉันยอมรับ [ข้อกำหนดและเงื่อนไข] และรับทราบ [นโยบายความเป็นส่วนตัว]",
                      value: _isTermsAccepted,
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _isTermsAccepted = val);
                      },
                      hasReadMore: true,
                    ),
                    const Divider(height: 28, color: Color(0xFFE0E0E0)),
                    _buildPolicyItem(
                      title:
                          "ฉันยินยอมให้เก็บรวบรวมและใช้ \"ข้อมูลสุขภาพ\" (เช่น รอบเดือน, บันทึกอารมณ์) เพื่อใช้ในการประมวลผลและวิเคราะห์สุขภาพจิตภายในแอปพลิเคชัน",
                      value: _isHealthDataAccepted,
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _isHealthDataAccepted = val);
                      },
                    ),
                    const Divider(height: 28, color: Color(0xFFE0E0E0)),
                    _buildPolicyItem(
                      title:
                          "ฉันยินยอมให้นำข้อมูลการสนทนาไปใช้เพื่อวิเคราะห์และพัฒนาคุณภาพการให้คำปรึกษา",
                      value: _isChatDataAccepted,
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _isChatDataAccepted = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || !_isAllAccepted ? null : _acceptPdpa,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'ฉันยอมรับเงื่อนไข (PDPA)',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyItem({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool hasReadMore = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF64BFFF),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: const BorderSide(color: Color(0xFF64BFFF), width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A89D8),
                  height: 1.4,
                ),
              ),
              if (hasReadMore)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PrivacyDetailPage()),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      "อ่านข้อมูลเพิ่มเติม",
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
        title: const Text(
          "นโยบายความเป็นส่วนตัว",
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
              "แอปพลิเคชัน Howareyou ให้ความสำคัญอย่างยิ่งกับความเป็นส่วนตัวและความปลอดภัยของข้อมูลผู้ใช้งาน ท่านนโยบายฉบับนี้จัดทำขึ้นเพื่อชี้แจงรายละเอียดเกี่ยวกับการเก็บรวบรวมใช้และเปิดเผยข้อมูลของท่านตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล (PDPA)",
              style: TextStyle(fontSize: 15, color: contentColor, height: 1.4),
            ),
            const SizedBox(height: 10),
            _buildHeader("1. ข้อมูลที่เราเก็บรวบรวม"),
            _buildSectionText(
              "เราเก็บรวบรวมข้อมูลเพื่อให้บริการและพัฒนาประสบการณ์การใช้งาน โดยแบ่งเป็นประเภทดังนี้:",
              contentColor,
            ),
            _buildSubHeader(
                "1.1 ข้อมูลส่วนบุคคลทั่วไป (General Personal Data)"),
            _buildBullet("ข้อมูลระบุตัวตน: ชื่อ, นามสกุล, วันเดือนปีเกิด, เพศ",
                contentColor),
            _buildBullet(
              "ข้อมูลบัญชีผู้ใช้: ชื่อผู้ใช้งาน (Username), รหัสผ่าน (ที่เข้ารหัสแล้ว), รูปโปรไฟล์",
              contentColor,
            ),
            _buildSubHeader(
                "1.2 ข้อมูลส่วนบุคคลที่อ่อนไหว (Sensitive Personal Data)"),
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
            _buildBullet("เป็นการปฏิบัติตามกฎหมาย หรือคำสั่งจากหน่วยงานรัฐ",
                contentColor),
            const SizedBox(height: 10),
            _buildHeader("4. การเก็บรักษาและความปลอดภัย"),
            _buildBullet(
                "เราจัดเก็บข้อมูลของท่านด้วยมาตรฐานความปลอดภัยทางเทคโนโลยี",
                contentColor),
            _buildBullet(
                "ข้อมูลสุขภาพและข้อมูลแชทจะถูกเก็บเป็นความลับอย่างเคร่งครัด",
                contentColor),
            const SizedBox(height: 10),
            _buildHeader("5. สิทธิของเจ้าของข้อมูลส่วนบุคคล"),
            _buildBullet("สิทธิขอเข้าถึงและขอรับสำเนาข้อมูล", contentColor),
            _buildBullet("สิทธิขอให้ลบหรือทำลายข้อมูล", contentColor),
            _buildBullet("สิทธิในการถอนความยินยอม", contentColor),
            const SizedBox(height: 10),
            _buildHeader("6. ช่องทางการติดต่อ"),
            _buildBullet("ผู้ดูแลแอปพลิเคชัน Howareyou", contentColor),
            _buildBullet("บริษัท ไทเกอร์ซอฟท์ (1998) จำกัด", contentColor),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

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

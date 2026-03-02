import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdpaDialog extends StatefulWidget {
  const PdpaDialog({super.key});

  @override
  State<PdpaDialog> createState() => _PdpaDialogState();
}

class _PdpaDialogState extends State<PdpaDialog> {
  bool _isLoading = false;

  Future<void> _acceptPdpa() async {
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 8, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ข้อตกลงและเงื่อนไข',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    _buildSection('1. ข้อมูลที่เราเก็บ', 'แอปพลิเคชันของเรามีการเก็บรวบรวมข้อมูลส่วนบุคคล เช่น อีเมลและข้อมูลการใช้งาน...'),
                    _buildSection('2. วัตถุประสงค์', 'เพื่อนำไปใช้ในการให้บริการ ปรับปรุงประสบการณ์การใช้งาน...'),
                    _buildSection('3. การเปิดเผยข้อมูล', 'เราจะไม่เปิดเผยข้อมูลของคุณแก่บุคคลที่สาม เว้นแต่จะได้รับความยินยอม...'),
                    _buildSection('4. สิทธิของคุณ', 'คุณมีสิทธิในการเข้าถึง แก้ไข หรือร้องขอให้ลบข้อมูลส่วนบุคคลได้...'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _acceptPdpa,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'ฉันยอมรับเงื่อนไข (PDPA)',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(content, style: TextStyle(color: Colors.grey[800], height: 1.5)),
        ],
      ),
    );
  }
}
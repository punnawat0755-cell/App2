import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/service/user_mode_status_service.dart';
import 'package:flutter_application_1/rolelogic/view/widget/choice_card.dart';
import 'package:flutter_application_1/rolelogic/view/widget/role_quiz_view.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  static const Color _backgroundColor = Colors.white;
  static const Color _cardListenerColor = Color(0xFFAEE4FC);
  static const Color _cardSeekerColor = Color(0xFFF5D586);

  String _selectedMode = '';
  bool _isSaving = false;

  Future<void> _openListenerQuiz() async {
    final result = await Navigator.of(context).push<QuizSelectionResult>(
      MaterialPageRoute(
        builder: (_) => QuizScreen(),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    await _saveMode(
      'listener',
      successMessage:
          'เลือกคำตอบ "${result.selectedAnswer}" และบันทึกโหมดวันนี้แล้ว: ผู้รับฟัง',
    );
  }

  Future<void> _saveMode(
    String currentMode, {
    String? successMessage,
  }) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _selectedMode = currentMode;
      _isSaving = true;
    });

    try {
      await UserModeStatusService.saveCurrentMode(currentMode);
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(successMessage ?? _messageForMode(currentMode));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกโหมดวันนี้ไม่สำเร็จ: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  String _messageForMode(String currentMode) {
    return currentMode == 'listener'
        ? 'บันทึกโหมดวันนี้แล้ว: ผู้รับฟัง'
        : 'บันทึกโหมดวันนี้แล้ว: ยังไม่พร้อมเป็นผู้รับฟัง';
  }

  void _showLockedExitHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กรุณาเลือกบทบาทของวันนี้ก่อน จึงจะไปต่อได้'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }

        _showLockedExitHint();
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'วันนี้คุณพร้อมเป็น\nผู้รับฟังไหม',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4489D7),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ถ้าเลือกพร้อมรับฟัง ระบบจะพาไปทำแบบทดสอบก่อน\nจากนั้นค่อยบันทึก current_mode และพาไปทำ Daily Mood ต่อ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF639CDD),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                const Text(
                  'กรุณาเลือกคำตอบของคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4489D7),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ChoiceCard(
                        id: 'listener',
                        title: 'พร้อมรับฟัง',
                        imagePath: 'assets/images/fine.png',
                        bgColor: _cardListenerColor,
                        textColor: const Color(0xFF4489D7),
                        isSelected: _selectedMode == 'listener',
                        onTap: _openListenerQuiz,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ChoiceCard(
                        id: 'seeker',
                        title: 'ยังไม่พร้อม',
                        imagePath: 'assets/images/sad.png',
                        bgColor: _cardSeekerColor,
                        textColor: const Color(0xFFC49A3E),
                        isSelected: _selectedMode == 'seeker',
                        onTap: () => _saveMode('seeker'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 18),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text(
                          'กำลังบันทึกบทบาทของวันนี้...',
                          style: TextStyle(
                            color: Color(0xFF4489D7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                const Text(
                  '"ผู้รับฟัง" คือผู้ที่พร้อมเป็นพื้นที่ปลอดภัยให้ใครสักคน\n'
                  'รับฟังอย่างไม่ตัดสิน อยู่ข้างเขา และช่วยประคองใจผ่านการแชท\n'
                  'เมื่อกด "พร้อมรับฟัง" จะเข้าสู่แบบทดสอบก่อน ส่วนถ้ายังไม่พร้อม ระบบจะบันทึก role ของวันนี้ทันที',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF639CDD),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

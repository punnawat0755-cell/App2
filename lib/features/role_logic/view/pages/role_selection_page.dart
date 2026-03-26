import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/features/home/service/user_mode_status_service.dart';
import 'package:flutter_application_1/features/role_logic/view/pages/role_quiz_page.dart';
import 'package:flutter_application_1/features/role_logic/view/widgets/choice_card.dart';

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
    final result = await Navigator.of(context).push<RoleQuizSelectionResult>(
      MaterialPageRoute(
        builder: (_) => RoleQuizPage(),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
              final isCompact = constraints.maxWidth < 390;
              final isShort = constraints.maxHeight < 760;
              final horizontalPadding = scale.rs(
                isCompact ? 14 : 22,
                min: 12,
                max: 28,
              );
              final verticalPadding = scale.rs(
                isShort ? 24 : 36,
                min: 18,
                max: 44,
              );
              final sectionGap = scale.rs(
                isShort ? 18 : 24,
                min: 14,
                max: 28,
              );
              final titleToCardsGap = scale.rs(
                isShort ? 32 : 44,
                min: 24,
                max: 48,
              );
              final cardsGap = scale.rs(
                isCompact ? 12 : 16,
                min: 10,
                max: 20,
              );
              final rowCardGap = scale.rs(16, min: 12, max: 22);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'วันนี้คุณพร้อมเป็น\nผู้รับฟังไหม',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: scale.rf(26, min: 22, max: 26),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4489D7),
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        Text(
                          'ถ้าเลือกพร้อมรับฟัง ระบบจะพาไปทำแบบทดสอบก่อน\nจากนั้นค่อยบันทึก current_mode และพาไปทำ Daily Mood ต่อ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: scale.rf(14, min: 12.5, max: 14.5),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF639CDD),
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: titleToCardsGap),
                        Text(
                          'กรุณาเลือกคำตอบของคุณ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: scale.rf(14, min: 12.5, max: 14.5),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4489D7),
                          ),
                        ),
                        SizedBox(height: cardsGap),
                        if (isCompact) ...[
                          ChoiceCard(
                            id: 'listener',
                            title: 'พร้อมรับฟัง',
                            imagePath: 'assets/images/fine.png',
                            bgColor: _cardListenerColor,
                            textColor: const Color(0xFF4489D7),
                            isSelected: _selectedMode == 'listener',
                            onTap: _openListenerQuiz,
                          ),
                          SizedBox(height: cardsGap),
                          ChoiceCard(
                            id: 'seeker',
                            title: 'ยังไม่พร้อม',
                            imagePath: 'assets/images/sad.png',
                            bgColor: _cardSeekerColor,
                            textColor: const Color(0xFFC49A3E),
                            isSelected: _selectedMode == 'seeker',
                            onTap: () => _saveMode('seeker'),
                          ),
                        ] else
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
                              SizedBox(width: rowCardGap),
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
                        SizedBox(height: scale.rs(isShort ? 20 : 28)),
                        if (_isSaving)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: scale.rs(14, min: 10, max: 18),
                            ),
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                SizedBox(height: scale.rs(8, min: 6, max: 10)),
                                Text(
                                  'กำลังบันทึกบทบาทของวันนี้...',
                                  style: TextStyle(
                                    fontSize:
                                        scale.rf(13, min: 11.5, max: 13.8),
                                    color: Color(0xFF4489D7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: scale.rs(isShort ? 16 : 24)),
                        Text(
                          '"ผู้รับฟัง" คือผู้ที่พร้อมเป็นพื้นที่ปลอดภัยให้ใครสักคน\n'
                          'รับฟังอย่างไม่ตัดสิน อยู่ข้างเขา และช่วยประคองใจผ่านการแชท\n'
                          'เมื่อกด "พร้อมรับฟัง" จะเข้าสู่แบบทดสอบก่อน ส่วนถ้ายังไม่พร้อม ระบบจะบันทึก role ของวันนี้ทันที',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: scale.rf(12, min: 10.8, max: 12.5),
                            height: 1.7,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF639CDD),
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
      ),
    );
  }
}

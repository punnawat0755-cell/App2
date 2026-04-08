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
    if (_isSaving) {
      return;
    }

    try {
      final todayState = await UserModeStatusService.getTodayAssessmentState();
      if (!mounted) {
        return;
      }

      if (todayState.assessmentPassedToday) {
        await _saveMode(
          'listener',
          successMessage: 'บันทึกโหมดวันนี้แล้ว: ผู้รับฟัง',
        );
        return;
      }

      if (todayState.completedToday && !todayState.assessmentPassedToday) {
        await _saveMode(
          'seeker',
          successMessage:
              'วันนี้คุณทำแบบประเมินแล้ว แต่ผลยังไม่ผ่าน จึงบันทึกโหมดวันนี้เป็นผู้ขอรับคำปรึกษาแล้ว',
        );
        return;
      }

      final result = await Navigator.of(context).push<RoleQuizSelectionResult>(
        MaterialPageRoute(
          builder: (_) => const RoleQuizPage(),
        ),
      );

      if (!mounted || result == null) {
        return;
      }

      if (result.assessmentUnavailable) {
        await _saveMode(
          'seeker',
          successMessage:
              'ยังไม่มีแบบประเมินที่เปิดใช้งาน จึงบันทึกโหมดวันนี้เป็นผู้ขอรับคำปรึกษา',
        );
        return;
      }

      if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage!)),
        );
        return;
      }

      if (!result.isPass) {
        await _saveMode(
          'seeker',
          successMessage:
              'ผล assessment วันนี้ยังไม่ผ่าน จึงบันทึกโหมดวันนี้เป็นผู้ขอรับคำปรึกษาแล้ว',
        );
        return;
      }

      final passedToday =
          await UserModeStatusService.hasPassedAssessmentToday();
      if (!mounted) {
        return;
      }

      if (!passedToday) {
        await _saveMode(
          'seeker',
          successMessage:
              'ผ่าน assessment แล้ว แต่สถานะรายวันยังไม่อัปเดต จึงบันทึกเป็นผู้ขอรับคำปรึกษาก่อน',
        );
        return;
      }

      await _saveMode(
        'listener',
        successMessage:
            'ผ่าน assessment วันนี้แล้ว (คะแนน ${result.totalScore}) และบันทึกโหมดวันนี้แล้ว: ผู้รับฟัง',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปิดแบบประเมินไม่สำเร็จ: $e')),
      );
    }
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
                isCompact ? 14 : 20,
                min: 12,
                max: 24,
              );
              final verticalPadding = scale.rs(
                isShort ? 10 : 16,
                min: 8,
                max: 22,
              );
              final topLeadGap = scale.rs(
                isShort ? 14 : 28,
                min: 10,
                max: 34,
              );
              final titleToHintGap = scale.rs(
                isShort ? 26 : 40,
                min: 20,
                max: 48,
              );
              final hintToCardsGap = scale.rs(
                isShort ? 14 : 22,
                min: 10,
                max: 28,
              );
              final cardsGap = scale.rs(
                isCompact ? 10 : 14,
                min: 8,
                max: 18,
              );
              final rowCardGap = scale.rs(16, min: 12, max: 22);
              final cardsToDetailGap = scale.rs(
                isShort ? 24 : 44,
                min: 18,
                max: 56,
              );
              final cardHeight = scale.rs(
                isShort ? 214 : 244,
                min: 196,
                max: 256,
              );

              return Align(
                alignment: Alignment.topCenter,
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
                        SizedBox(height: topLeadGap),
                        Text(
                          'วันนี้คุณต้องการที่จะเป็น\nผู้ให้คำปรึกษาไหม',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: scale.rf(27, min: 22, max: 30),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4489D7),
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: titleToHintGap),
                        Text(
                          'กรุณากดที่รูปเพื่อเลือกคำตอบของคุณ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: scale.rf(13.6, min: 12, max: 15),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4489D7),
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: hintToCardsGap),
                        if (isCompact) ...[
                          ChoiceCard(
                            id: 'listener',
                            title: 'ต้องการ',
                            imagePath: 'assets/images/fine.png',
                            bgColor: _cardListenerColor,
                            textColor: const Color(0xFF4489D7),
                            isSelected: _selectedMode == 'listener',
                            onTap: _openListenerQuiz,
                            height: cardHeight,
                          ),
                          SizedBox(height: cardsGap),
                          ChoiceCard(
                            id: 'seeker',
                            title: 'ไม่ต้องการ',
                            imagePath: 'assets/images/sad.png',
                            bgColor: _cardSeekerColor,
                            textColor: const Color(0xFFC49A3E),
                            isSelected: _selectedMode == 'seeker',
                            onTap: () => _saveMode('seeker'),
                            height: cardHeight,
                          ),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ChoiceCard(
                                  id: 'listener',
                                  title: 'ต้องการ',
                                  imagePath: 'assets/images/fine.png',
                                  bgColor: _cardListenerColor,
                                  textColor: const Color(0xFF4489D7),
                                  isSelected: _selectedMode == 'listener',
                                  onTap: _openListenerQuiz,
                                  height: cardHeight,
                                ),
                              ),
                              SizedBox(width: rowCardGap),
                              Expanded(
                                child: ChoiceCard(
                                  id: 'seeker',
                                  title: 'ไม่ต้องการ',
                                  imagePath: 'assets/images/sad.png',
                                  bgColor: _cardSeekerColor,
                                  textColor: const Color(0xFFC49A3E),
                                  isSelected: _selectedMode == 'seeker',
                                  onTap: () => _saveMode('seeker'),
                                  height: cardHeight,
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: cardsToDetailGap),
                        if (_isSaving)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: scale.rs(10, min: 8, max: 14),
                            ),
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                SizedBox(height: scale.rs(8, min: 6, max: 10)),
                                Text(
                                  'กำลังบันทึกบทบาทของวันนี้...',
                                  style: TextStyle(
                                    fontSize: scale.rf(13, min: 11, max: 13.8),
                                    color: const Color(0xFF4489D7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: scale.rs(isShort ? 8 : 12)),
                        Text(
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
                            fontSize: scale.rf(11.9, min: 10.4, max: 13.2),
                            height: 1.5,
                            fontWeight: FontWeight.w700,
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

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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: topLeadGap),
                        Text(
                          'วันนี้คุณอยากเป็นแบบไหน',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF4489D7),
                            fontSize: scale.rf(28, min: 24, max: 31),
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: titleToHintGap),
                        Text(
                          'เลือกได้ 1 บทบาทสำหรับวันนี้',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF6B7280),
                            fontSize: scale.rf(15, min: 13, max: 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: hintToCardsGap),
                        Flex(
                          direction:
                              isCompact ? Axis.vertical : Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ChoiceCard(
                                id: 'listener',
                                title: 'ผู้รับฟัง',
                                imagePath: 'assets/images/fine.png',
                                bgColor: _cardListenerColor,
                                textColor: const Color(0xFF4489D7),
                                isSelected: _selectedMode == 'listener',
                                height: cardHeight,
                                onTap: _openListenerQuiz,
                              ),
                            ),
                            SizedBox(
                              width: isCompact ? 0 : rowCardGap,
                              height: isCompact ? cardsGap : 0,
                            ),
                            Expanded(
                              child: ChoiceCard(
                                id: 'seeker',
                                title: 'ผู้ขอรับคำปรึกษา',
                                imagePath: 'assets/images/sad.png',
                                bgColor: _cardSeekerColor,
                                textColor: const Color(0xFFC49A3E),
                                isSelected: _selectedMode == 'seeker',
                                height: cardHeight,
                                onTap: () => _saveMode('seeker'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: cardsToDetailGap),
                        Container(
                          padding: EdgeInsets.all(
                            scale.rs(18, min: 14, max: 20),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFF),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFD9E8FF),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'หมายเหตุ',
                                style: TextStyle(
                                  color: const Color(0xFF4489D7),
                                  fontSize: scale.rf(15, min: 14, max: 16),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: scale.rs(10, min: 8, max: 12)),
                              Text(
                                'หากเลือกบทบาทผู้รับฟัง ระบบอาจให้ทำแบบประเมินก่อนเพื่อความเหมาะสมของการสนทนา',
                                style: TextStyle(
                                  color: const Color(0xFF5C667A),
                                  fontSize: scale.rf(13.5, min: 12.5, max: 14),
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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

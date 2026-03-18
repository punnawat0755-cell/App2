import 'package:flutter/material.dart';

class ListenerQuizResult {
  const ListenerQuizResult({
    required this.score,
    required this.totalQuestions,
  });

  final int score;
  final int totalQuestions;
}

class ListenerQuizPage extends StatefulWidget {
  const ListenerQuizPage({super.key});

  @override
  State<ListenerQuizPage> createState() => _ListenerQuizPageState();
}

class _ListenerQuizPageState extends State<ListenerQuizPage> {
  static const List<_QuizQuestion> _questions = [
    _QuizQuestion(
      prompt:
          'เมื่ออีกฝ่ายเริ่มเล่าเรื่องหนักใจ สิ่งแรกที่ผู้รับฟังควรทำคืออะไร',
      choices: [
        'เปิดพื้นที่ให้เขาเล่าและรับฟังอย่างไม่ตัดสิน',
        'รีบสรุปว่าปัญหาของเขาคืออะไร',
        'บอกให้หยุดคิดมากทันที',
        'รีบเปลี่ยนเรื่องเพื่อให้เขาลืม',
      ],
      correctIndex: 0,
    ),
    _QuizQuestion(
      prompt:
          'ถ้าเรายังไม่แน่ใจว่าเข้าใจความรู้สึกของอีกฝ่ายถูกไหม ควรทำอย่างไร',
      choices: [
        'เดาเอาเองแล้วพูดต่อ',
        'สะท้อนสิ่งที่ได้ยินและถามยืนยันอย่างสุภาพ',
        'ข้ามเรื่องนี้ไปก่อน',
        'ตอบแค่ว่าโอเค',
      ],
      correctIndex: 1,
    ),
    _QuizQuestion(
      prompt: 'ข้อใดเป็นพฤติกรรมที่ไม่เหมาะสมสำหรับผู้รับฟัง',
      choices: [
        'รับฟังด้วยความตั้งใจ',
        'ถามเพื่อทำความเข้าใจเพิ่ม',
        'ตัดสินว่าเขาผิดและควรทำตามเรา',
        'ให้เวลาอีกฝ่ายได้คิดและพูด',
      ],
      correctIndex: 2,
    ),
    _QuizQuestion(
      prompt:
          'ถ้าประเด็นที่คุยหนักเกินกำลังของเรา แนวทางที่เหมาะสมที่สุดคืออะไร',
      choices: [
        'รับปากว่าจะแก้ปัญหาให้เองทั้งหมด',
        'หายออกจากแชททันที',
        'ฝืนคุยต่อทั้งที่ไม่พร้อม',
        'แนะนำให้ติดต่อผู้เชี่ยวชาญหรือช่องทางช่วยเหลือที่เหมาะสม',
      ],
      correctIndex: 3,
    ),
  ];

  late final List<int?> _selectedAnswers =
      List<int?>.filled(_questions.length, null);
  int _currentIndex = 0;

  Future<void> _submitQuiz() async {
    if (_selectedAnswers.any((answer) => answer == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาตอบคำถามให้ครบก่อนส่งแบบทดสอบ'),
        ),
      );
      return;
    }

    var score = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i].correctIndex) {
        score++;
      }
    }

    Navigator.of(context).pop(
      ListenerQuizResult(
        score: score,
        totalQuestions: _questions.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentIndex];
    final selectedAnswer = _selectedAnswers[_currentIndex];
    final isLastQuestion = _currentIndex == _questions.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF4489D7),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'แบบทดสอบผู้รับฟัง',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF4489D7),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/quiz.png',
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'คำถาม ${_currentIndex + 1} / ${_questions.length}',
                      style: const TextStyle(
                        color: Color(0xFF7BA6DE),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (_currentIndex + 1) / _questions.length,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0xFF5CD9FF),
                      backgroundColor: const Color(0xFFE6F4FF),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      question.prompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2E5B97),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              for (var index = 0; index < question.choices.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QuizChoiceTile(
                    label: question.choices[index],
                    isSelected: selectedAnswer == index,
                    onTap: () {
                      setState(() {
                        _selectedAnswers[_currentIndex] = index;
                      });
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentIndex == 0
                          ? null
                          : () {
                              setState(() => _currentIndex--);
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF9CC7F5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('ก่อนหน้า'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLastQuestion) {
                          _submitQuiz();
                          return;
                        }

                        setState(() {
                          _currentIndex++;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A89D8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(isLastQuestion ? 'ส่งแบบทดสอบ' : 'ข้อต่อไป'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'ตอนนี้แบบทดสอบถูกเปิดไว้เพื่อให้ทุกคนลองกดและทดสอบ flow ได้',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6D93C7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizChoiceTile extends StatelessWidget {
  const _QuizChoiceTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDDF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF4A89D8) : const Color(0xFFD8E7F6),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? const Color(0xFF4A89D8)
                  : const Color(0xFF95B8DE),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF315E99),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.prompt,
    required this.choices,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> choices;
  final int correctIndex;
}

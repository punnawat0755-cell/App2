import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:get/get.dart';

class RoleQuizSelectionResult {
  const RoleQuizSelectionResult({
    required this.totalScore,
    required this.answers,
    required this.isPass,
    this.errorMessage,
  });

  final int totalScore;
  final List<Map<String, dynamic>> answers;
  final bool isPass;
  final String? errorMessage;
}

class QuizController extends GetxController {
  static const String _clientVersion = 'assessment_v1';
  static const int _passScore = 11;
  static const int _maxScore = 20;

  static const List<Map<String, dynamic>> _localQuestionBank = [
    {
      'id': 'q1',
      'image': 'assets/images/image-1.png',
      'options': [
        {'text': 'นกพิราบ', 'score': 1},
        {'text': 'ปู', 'score': 1},
        {'text': 'ตั๊กแตนตำข้าว', 'score': 1},
        {'text': 'ไก่', 'score': 0},
        {'text': 'ผีเสื้อ', 'score': 0},
        {'text': 'หมาป่า', 'score': 0},
        {'text': 'ม้า', 'score': 0},
      ],
    },
    {
      'id': 'q2',
      'image': 'assets/images/image-2.png',
      'options': [
        {'text': 'ต้นไม้', 'score': 1},
        {'text': 'มือ 2 ข้าง', 'score': 0},
        {'text': 'ระเบิด', 'score': 0},
      ],
    },
    {
      'id': 'q3',
      'image': 'assets/images/image-3.png',
      'options': [
        {'text': 'ผู้หญิง', 'score': 1},
        {'text': 'ผู้ชาย', 'score': 0},
      ],
    },
    {
      'id': 'q4',
      'image': 'assets/images/image-4.png',
      'options': [
        {'text': 'จระเข้', 'score': 0},
        {'text': 'เรือ', 'score': 1},
      ],
    },
    {
      'id': 'q5',
      'image': 'assets/images/image-5.png',
      'options': [
        {'text': 'หัวกะโหลก', 'score': 0},
        {'text': 'ผู้หญิง (ส่องกระจก)', 'score': 1},
      ],
    },
    {
      'id': 'q6',
      'image': 'assets/images/image-6.png',
      'options': [
        {'text': 'ผู้หญิงเป่าเครื่องดนตรี', 'score': 1},
        {'text': 'หน้าคน', 'score': 0},
      ],
    },
    {
      'id': 'q7',
      'image': 'assets/images/image-7.png',
      'options': [
        {'text': 'ต้นไม้', 'score': 1},
        {'text': 'หน้าคน', 'score': 0},
      ],
    },
    {
      'id': 'q8',
      'image': 'assets/images/image-8.png',
      'options': [
        {'text': 'หน้าคน', 'score': 1},
        {'text': 'คนสองคน', 'score': 0},
      ],
    },
    {
      'id': 'q9',
      'image': 'assets/images/image-9.png',
      'options': [
        {'text': 'ต้นไม้', 'score': 1},
        {'text': 'เสือ', 'score': 0},
      ],
    },
    {
      'id': 'q10',
      'image': 'assets/images/image-10.png',
      'options': [
        {'text': 'ผู้หญิงสาว', 'score': 1},
        {'text': 'ผู้หญิงแก่', 'score': 0},
      ],
    },
    {
      'id': 'q11',
      'image': 'assets/images/image-11.png',
      'options': [
        {'text': 'เป็ด', 'score': 1},
        {'text': 'กระต่าย', 'score': 0},
        {'text': 'ทั้งเป็ดและกระต่าย', 'score': 1},
      ],
    },
    {
      'id': 'q12',
      'image': 'assets/images/image-12.png',
      'options': [
        {'text': 'แมวขึ้นบันได', 'score': 0},
        {'text': 'แมวลงบันได', 'score': 1},
      ],
    },
    {
      'id': 'q13',
      'image': 'assets/images/image-13.png',
      'options': [
        {'text': 'ต้นไม้', 'score': 0},
        {'text': 'กอริลลา', 'score': 0},
        {'text': 'สิงโต', 'score': 1},
        {'text': 'ปลา', 'score': 1},
      ],
    },
    {
      'id': 'q14',
      'image': 'assets/images/image-14.png',
      'options': [
        {'text': 'เด็กทารก', 'score': 0},
        {'text': 'คู่รัก', 'score': 1},
        {'text': 'ต้นไม้', 'score': 1},
      ],
    },
    {
      'id': 'q15',
      'image': 'assets/images/image-15.png',
      'options': [
        {'text': 'ห่าน หรือ หงส์', 'score': 1},
        {'text': 'ชายที่นั่งอยู่ริมน้ำ', 'score': 0},
        {'text': 'ใบหน้าชายแก่', 'score': 1},
      ],
    },
    {
      'id': 'q16',
      'image': 'assets/images/image-16.png',
      'options': [
        {'text': 'เด็กผู้หญิง', 'score': 1},
        {'text': 'หัวกะโหลก', 'score': 0},
        {'text': 'ผีเสื้อ', 'score': 1},
      ],
    },
    {
      'id': 'q17',
      'image': 'assets/images/image-17.png',
      'options': [
        {'text': 'คนเล่นกีต้าร์', 'score': 1},
        {'text': 'คนใส่เสื้อผ้าสีขาว', 'score': 1},
        {'text': 'คนใส่เสื้อผ้าสีแดง', 'score': 0},
        {'text': 'ใบหน้า', 'score': 0},
      ],
    },
    {
      'id': 'q18',
      'image': 'assets/images/image-18.png',
      'options': [
        {'text': 'เด็กผู้หญิงสองคน', 'score': 1},
        {'text': 'เงาโครงหน้า', 'score': 0},
      ],
    },
    {
      'id': 'q19',
      'image': 'assets/images/image-19.png',
      'options': [
        {'text': 'เด็กผู้หญิง', 'score': 1},
        {'text': 'กะโหลก', 'score': 0},
        {'text': 'ทิวทัศน์หน้าถ้ำ', 'score': 0},
      ],
    },
    {
      'id': 'q20',
      'image': 'assets/images/image-20.png',
      'options': [
        {'text': 'ป่า', 'score': 0},
        {'text': 'ใบหน้าคน', 'score': 1},
        {'text': 'ฝูงนก', 'score': 0},
        {'text': 'หมี', 'score': 0},
      ],
    },
    {
      'id': 'q21',
      'image': 'assets/images/image-21.png',
      'options': [
        {'text': 'ภูเขา', 'score': 0},
        {'text': 'ใบหน้าคน', 'score': 1},
      ],
    },
    {
      'id': 'q22',
      'image': 'assets/images/image-22.png',
      'options': [
        {'text': 'ผู้ชายที่โดนมัด', 'score': 1},
        {'text': 'รั้ว', 'score': 0},
        {'text': 'เรือ', 'score': 0},
        {'text': 'กะโหลก', 'score': 0},
      ],
    },
    {
      'id': 'q23',
      'image': 'assets/images/image-23.png',
      'options': [
        {'text': 'แอปเปิ้ล', 'score': 1},
        {'text': 'คู่รัก', 'score': 0},
      ],
    },
    {
      'id': 'q24',
      'image': 'assets/images/image-24.png',
      'options': [
        {'text': 'รูปคู่รัก', 'score': 1},
        {'text': 'รูปแอปเปิ้ลแหว่ง', 'score': 0},
      ],
    },
    {
      'id': 'q25',
      'image': 'assets/images/image-25.png',
      'options': [
        {'text': 'แจกัน', 'score': 0},
        {'text': 'ผีเสื้อ', 'score': 1},
        {'text': 'เงาคู่รัก', 'score': 0},
      ],
    },
    {
      'id': 'q26',
      'image': 'assets/images/image-26.png',
      'options': [
        {'text': 'ยูเอฟโอ', 'score': 0},
        {'text': 'หน้าเอเลี่ยน', 'score': 0},
        {'text': 'ถ้ำ', 'score': 1},
      ],
    },
    {
      'id': 'q27',
      'image': 'assets/images/image-27.png',
      'options': [
        {'text': 'ใบหน้าคน', 'score': 0},
        {'text': 'หมี', 'score': 1},
        {'text': 'ป่า และ ดวงจันทร์', 'score': 0},
      ],
    },
    {
      'id': 'q28',
      'image': 'assets/images/image-28.png',
      'options': [
        {'text': 'ใบหน้าคนสองคน', 'score': 1},
        {'text': 'ผีเสื้อ', 'score': 0},
        {'text': 'เห็นวงกลม', 'score': 1},
      ],
    },
    {
      'id': 'q29',
      'image': 'assets/images/image-29.png',
      'options': [
        {'text': 'ต้นไม้', 'score': 0},
        {'text': 'นก', 'score': 1},
      ],
    },
    {
      'id': 'q30',
      'image': 'assets/images/image-30.png',
      'options': [
        {'text': 'เสือ', 'score': 1},
        {'text': 'ลิง', 'score': 0},
      ],
    },
  ];

  final quizList = <Map<String, dynamic>>[].obs;
  final mediaUrlByName = <String, String>{}.obs;
  final selectedAnswers = <String, Map<String, dynamic>>{};

  final currentQuestionIndex = 0.obs;
  final totalScore = 0.obs;
  final selectedIndex = (-1).obs;
  final isProcessing = false.obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  String? _activeAssessmentId;
  String? _attemptId;

  @override
  void onInit() {
    super.onInit();
    _bootstrapAssessment();
  }

  Future<void> _bootstrapAssessment() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _prepareRandomLocalQuiz();

      // Warm up assessment id if available, but do not block showing quiz.
      _activeAssessmentId = await _fetchActiveAssessmentId();
    } catch (error) {
      errorMessage.value = 'โหลดแบบประเมินในระบบไม่สำเร็จ: $error';
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> _fetchActiveAssessmentId() async {
    final assessmentRow = await supabase
        .from('assessments')
        .select('id')
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final assessmentId = assessmentRow?['id']?.toString().trim() ?? '';
    if (assessmentId.isEmpty) {
      return null;
    }
    return assessmentId;
  }

  Future<String?> _ensureAttemptId() async {
    if (_attemptId != null && _attemptId!.isNotEmpty) {
      return _attemptId;
    }

    var assessmentId = _activeAssessmentId;
    if (assessmentId == null || assessmentId.isEmpty) {
      assessmentId = await _fetchActiveAssessmentId();
      _activeAssessmentId = assessmentId;
    }
    if (assessmentId == null || assessmentId.isEmpty) {
      return null;
    }

    final attemptRaw = await supabase.rpc(
      'start_my_assessment_attempt',
      params: {'p_assessment_id': assessmentId},
    );
    final attemptId = _extractAttemptId(attemptRaw);
    if (attemptId == null || attemptId.isEmpty) {
      throw StateError(
        'รูปแบบผลลัพธ์ start_my_assessment_attempt ไม่ถูกต้อง: '
        'คาดหวัง UUID แต่ได้ ${attemptRaw.runtimeType}',
      );
    }

    _attemptId = attemptId;
    return attemptId;
  }

  String? _extractAttemptId(Object? raw) {
    if (raw == null) {
      return null;
    }

    if (raw is String) {
      final value = raw.trim();
      return value.isEmpty ? null : value;
    }

    if (raw is List) {
      if (raw.isEmpty) {
        return null;
      }

      final first = raw.first;
      if (first is String) {
        final value = first.trim();
        return value.isEmpty ? null : value;
      }
      if (first is Map) {
        final row = Map<String, dynamic>.from(first);
        final idValue = row['id']?.toString().trim() ?? '';
        return idValue.isEmpty ? null : idValue;
      }
      return null;
    }

    if (raw is Map) {
      final row = Map<String, dynamic>.from(raw);
      final idValue = row['id']?.toString().trim() ?? '';
      return idValue.isEmpty ? null : idValue;
    }

    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _prepareRandomLocalQuiz() async {
    final shuffledQuestions =
        List<Map<String, dynamic>>.from(_localQuestionBank)..shuffle();
    final selectedQuestions = shuffledQuestions.take(5).toList();

    final mappedQuestions = selectedQuestions.map((raw) {
      final sourceOptions = List<Map<String, dynamic>>.from(
        raw['options'] ?? const [],
      );
      final options = sourceOptions.asMap().entries.map((entry) {
        final index = entry.key;
        final opt = entry.value;
        return {
          'id': null,
          'key': _optionKey(index),
          'text': opt['text']?.toString() ?? '-',
          'score': (opt['score'] as int?) ?? 0,
        };
      }).toList();

      return {
        'id': raw['id']?.toString() ?? '',
        'prompt': 'คุณเห็นอะไรในภาพนี้เป็นอย่างแรก',
        'image': raw['image']?.toString() ?? '',
        'options': options,
      };
    }).toList();

    quizList.assignAll(mappedQuestions);
    currentQuestionIndex.value = 0;
    totalScore.value = 0;
    selectedIndex.value = -1;
    isProcessing.value = false;
    selectedAnswers.clear();
    await _loadAssessmentImagesForCurrentQuiz();
  }

  String _optionKey(int index) {
    final codeUnit = 97 + index; // a, b, c, ...
    return String.fromCharCode(codeUnit);
  }

  String resolveImageUrl(String imagePath) {
    final normalized = imagePath.trim();
    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    final fileName = _fileNameFromPath(normalized);
    if (fileName.isEmpty) {
      return '';
    }

    return mediaUrlByName[fileName] ?? '';
  }

  Future<void> _loadAssessmentImagesForCurrentQuiz() async {
    try {
      final currentQuizFileNames = quizList
          .map((question) =>
              _fileNameFromPath(question['image']?.toString() ?? ''))
          .where((fileName) => fileName.isNotEmpty)
          .toSet();

      if (currentQuizFileNames.isEmpty) {
        return;
      }

      final missingFileNames = currentQuizFileNames
          .where((fileName) => !mediaUrlByName.containsKey(fileName))
          .toList();

      if (missingFileNames.isEmpty) {
        return;
      }

      final resolvedEntries = await Future.wait(
        missingFileNames.map((fileName) async {
          final storagePath = 'assessment/$fileName';
          final signedUrl = await _tryCreateSignedUrl(storagePath);
          final imageUrl = signedUrl ??
              supabase.storage.from('app_media').getPublicUrl(storagePath);
          return MapEntry(fileName, imageUrl);
        }),
      );

      final nextMapping = Map<String, String>.from(mediaUrlByName);
      for (final entry in resolvedEntries) {
        if (entry.value.isNotEmpty) {
          nextMapping[entry.key] = entry.value;
        }
      }
      mediaUrlByName.assignAll(nextMapping);
    } catch (error) {
      debugPrint('Role quiz cannot load storage assessment images: $error');
    }
  }

  Future<String?> _tryCreateSignedUrl(String storagePath) async {
    try {
      final signedUrl = await supabase.storage
          .from('app_media')
          .createSignedUrl(storagePath, 24 * 60 * 60);
      if (signedUrl.trim().isNotEmpty) {
        return signedUrl;
      }
    } catch (_) {}

    return null;
  }

  String _fileNameFromPath(String rawPath) {
    var value = rawPath.trim();
    if (value.isEmpty) {
      return '';
    }

    final queryIndex = value.indexOf('?');
    if (queryIndex >= 0) {
      value = value.substring(0, queryIndex);
    }

    final hashIndex = value.indexOf('#');
    if (hashIndex >= 0) {
      value = value.substring(0, hashIndex);
    }

    if (value.contains('/')) {
      value = value.split('/').last;
    }

    return value;
  }

  Future<void> selectOption(int optionIndex) async {
    if (isProcessing.value) {
      return;
    }

    final currentIndex = currentQuestionIndex.value;
    if (currentIndex < 0 || currentIndex >= quizList.length) {
      return;
    }

    final currentQuiz = quizList[currentIndex];
    final options = List<Map<String, dynamic>>.from(currentQuiz['options']);
    if (optionIndex < 0 || optionIndex >= options.length) {
      return;
    }

    final selectedOption = options[optionIndex];
    final questionId = currentQuiz['id']?.toString().trim() ?? '';
    final optionId = selectedOption['id']?.toString().trim();
    final answerKey = selectedOption['key']?.toString().trim() ?? '';
    final text = selectedOption['text']?.toString() ?? '';
    final scoreValue = selectedOption['score'];
    final score = scoreValue is int
        ? scoreValue
        : int.tryParse(scoreValue?.toString() ?? '') ?? 0;

    if (questionId.isEmpty || answerKey.isEmpty) {
      errorMessage.value = 'ข้อมูลคำถามไม่ถูกต้อง';
      return;
    }

    isProcessing.value = true;
    selectedIndex.value = optionIndex;

    try {
      selectedAnswers[questionId] = {
        'question_id': questionId,
        'answer_key': answerKey,
        'option_id': optionId,
        'selected_text': text,
        'score': score,
      };
      totalScore.value = _calculateTotalScore();

      await Future<void>.delayed(const Duration(milliseconds: 350));

      if (currentQuestionIndex.value < quizList.length - 1) {
        currentQuestionIndex.value++;
        selectedIndex.value = -1;
        return;
      }

      final submitResult = await _submitAssessmentResult();
      final payload = _buildAssessmentPayload();
      final answers = List<Map<String, dynamic>>.from(
        (payload['answers'] as List<dynamic>? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );
      final result = RoleQuizSelectionResult(
        totalScore: submitResult.submittedScore ?? totalScore.value,
        answers: answers,
        isPass: submitResult.isPass,
        errorMessage: submitResult.errorMessage,
      );

      Get.back(result: result);
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isProcessing.value = false;
    }
  }

  Future<_SubmitAssessmentResult> _submitAssessmentResult() async {
    try {
      final computedTotalScore = _calculateTotalScore();
      final maxRawScore = _calculateMaxRawScore();
      final backendScore = _normalizeScoreForBackend(
        rawScore: computedTotalScore,
        rawMaxScore: maxRawScore,
      );
      final payload = _buildAssessmentPayload(
        rawTotalScore: computedTotalScore,
        rawMaxScore: maxRawScore,
      );

      final attemptId = await _ensureAttemptId();
      if (attemptId == null || attemptId.isEmpty) {
        return const _SubmitAssessmentResult(
          isPass: false,
          errorMessage:
              'ยังไม่มีแบบประเมินที่เปิดใช้งาน จึงยังบันทึกคะแนนไม่ได้',
        );
      }

      final passRaw = await supabase.rpc(
        'finish_assessment_from_client',
        params: {
          'p_attempt_id': attemptId,
          'p_total_score': backendScore,
          'p_payload': payload,
          'p_client_version': _clientVersion,
          'p_pass_score': _passScore,
          'p_max_score': _maxScore,
        },
      );

      return _SubmitAssessmentResult(
        isPass: _toBool(passRaw),
        submittedScore: backendScore,
      );
    } catch (error) {
      return _SubmitAssessmentResult(
        isPass: false,
        errorMessage: 'บันทึกคะแนน assessment ไม่สำเร็จ: $error',
      );
    }
  }

  Map<String, dynamic> _buildAssessmentPayload({
    int? rawTotalScore,
    int? rawMaxScore,
  }) {
    final computedRawTotalScore = rawTotalScore ?? _calculateTotalScore();
    final computedRawMaxScore = rawMaxScore ?? _calculateMaxRawScore();
    final answers = selectedAnswers.values
        .map(
          (item) => {
            'question_id': item['question_id'],
            'answer_key': item['answer_key'],
            'score': item['score'],
          },
        )
        .toList();

    return {
      'answers': answers,
      'meta': {
        'total_questions': quizList.length,
        'answered_questions': answers.length,
        'raw_total_score': computedRawTotalScore,
        'raw_max_score': computedRawMaxScore,
      },
    };
  }

  int _calculateTotalScore() {
    return selectedAnswers.values.fold<int>(
      0,
      (sum, item) => sum + ((item['score'] as int?) ?? 0),
    );
  }

  int _calculateMaxRawScore() {
    return quizList.fold<int>(0, (sum, question) {
      final options =
          List<Map<String, dynamic>>.from(question['options'] ?? const []);
      final maxOptionScore = options.fold<int>(0, (maxScore, option) {
        final value = option['score'];
        final score =
            value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
        return score > maxScore ? score : maxScore;
      });
      return sum + maxOptionScore;
    });
  }

  int _normalizeScoreForBackend({
    required int rawScore,
    required int rawMaxScore,
  }) {
    if (rawMaxScore <= 0) {
      return 0;
    }

    final scaled = ((rawScore / rawMaxScore) * _maxScore).round();
    return scaled.clamp(0, _maxScore);
  }

  bool _toBool(Object? raw) {
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw != 0;
    }
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 't';
    }
    return false;
  }
}

class _SubmitAssessmentResult {
  const _SubmitAssessmentResult({
    required this.isPass,
    this.errorMessage,
    this.submittedScore,
  });

  final bool isPass;
  final String? errorMessage;
  final int? submittedScore;
}

class RoleQuizPage extends StatefulWidget {
  const RoleQuizPage({super.key});

  @override
  State<RoleQuizPage> createState() => _RoleQuizPageState();
}

class _RoleQuizPageState extends State<RoleQuizPage> {
  late final QuizController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(QuizController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<QuizController>()) {
      Get.delete<QuizController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xFF5883C4);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4489D7)),
            );
          }

          final error = controller.errorMessage.value;
          if (error != null && controller.quizList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFF4489D7), size: 48),
                    const SizedBox(height: 12),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF4489D7)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      child: const Text('กลับ'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (controller.currentQuestionIndex.value >=
              controller.quizList.length) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4489D7)),
            );
          }

          final currentQuiz =
              controller.quizList[controller.currentQuestionIndex.value];
          final imagePath = currentQuiz['image']?.toString() ?? '';
          final imageUrl = controller.resolveImageUrl(imagePath);
          final prompt = currentQuiz['prompt']?.toString() ??
              'คุณเห็นอะไรในภาพนี้เป็นอย่างแรก';
          final options = List<Map<String, dynamic>>.from(
              currentQuiz['options'] ?? const []);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    prompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4489D7),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _buildQuizImage(
                        rawImagePath: imagePath,
                        imageUrl: imageUrl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Text(
                        'โปรดเลือกคำตอบของคุณ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4489D7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final optionText =
                          options[index]['text']?.toString() ?? '-';
                      final isSelected =
                          controller.selectedIndex.value == index;

                      return _buildOptionButton(
                        index,
                        optionText,
                        textColor,
                        isSelected,
                        controller,
                      );
                    },
                  ),
                  if (controller.errorMessage.value != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      controller.errorMessage.value!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuizImage({
    required String rawImagePath,
    required String imageUrl,
  }) {
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: 230,
        height: 270,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            width: 230,
            height: 270,
            color: Colors.grey[100],
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: Color(0xFF4489D7),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackAssetImage(rawImagePath);
        },
      );
    }

    return _buildFallbackAssetImage(rawImagePath);
  }

  Widget _buildFallbackAssetImage(String rawImagePath) {
    final normalized = rawImagePath.trim();
    if (normalized.startsWith('assets/')) {
      return Image.asset(
        normalized,
        width: 230,
        height: 270,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildBrokenImage(),
      );
    }

    return _buildBrokenImage();
  }

  Widget _buildBrokenImage() {
    return Container(
      width: 230,
      height: 270,
      color: Colors.grey[200],
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildOptionButton(
    int index,
    String title,
    Color textColor,
    bool isSelected,
    QuizController controller,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF8BE2FB) : const Color(0xFFCEEFFE),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF5883C4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: controller.isProcessing.value
              ? null
              : () {
                  controller.selectOption(index);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

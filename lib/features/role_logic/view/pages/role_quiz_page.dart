import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:get/get.dart';

class RoleQuizSelectionResult {
  const RoleQuizSelectionResult({
    required this.totalScore,
    required this.answers,
  });

  final int totalScore;
  final List<Map<String, dynamic>> answers;
}

// --------------------------------------------------------
// 1. GetX Controller สำหรับจัดการ State
// --------------------------------------------------------
class QuizController extends GetxController {
  static final RegExp _quizImageNamePattern = RegExp(r'^image-\d+\.png$');

  final List<Map<String, dynamic>> allQuestions = [
    {
      "image": "assets/images/image-1.png",
      "options": [
        {"text": "นกพิราบ", "score": 1},
        {"text": "ปู", "score": 1},
        {"text": "ตั๊กแตนตำข้าว", "score": 1},
        {"text": "ไก่", "score": 0},
        {"text": "ผีเสื้อ", "score": 0},
        {"text": "หมาป่า", "score": 0},
        {"text": "ม้า", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-2.png",
      "options": [
        {"text": "ต้นไม้", "score": 1},
        {"text": "มือ 2 ข้าง", "score": 0},
        {"text": "ระเบิด", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-3.png",
      "options": [
        {"text": "ผู้หญิง", "score": 1},
        {"text": "ผู้ชาย", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-4.png",
      "options": [
        {"text": "จระเข้", "score": 0},
        {"text": "เรือ", "score": 1},
      ],
    },
    {
      "image": "assets/images/image-5.png",
      "options": [
        {"text": "หัวกะโหลก", "score": 0},
        {"text": "ผู้หญิง (ส่องกระจก)", "score": 1},
      ],
    },
    {
      "image": "assets/images/image-6.png",
      "options": [
        {"text": "ผู้หญิงเป่าเครื่องดนตรี", "score": 1},
        {"text": "หน้าคน", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-7.png",
      "options": [
        {"text": "ต้นไม้", "score": 1},
        {"text": "หน้าคน", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-8.png",
      "options": [
        {"text": "หน้าคน", "score": 1},
        {"text": "คนสองคน", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-9.png",
      "options": [
        {"text": "ต้นไม้", "score": 1},
        {"text": "เสือ", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-10.png",
      "options": [
        {"text": "ผู้หญิงสาว", "score": 1},
        {"text": "ผู้หญิงแก่", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-11.png",
      "options": [
        {"text": "เป็ด", "score": 1},
        {"text": "กระต่าย", "score": 0},
        {"text": "ทั้งเป็ดและกระต่าย", "score": 1},
      ],
    },
    {
      "image": "assets/images/image-12.png",
      "options": [
        {"text": "แมวขึ้นบันได", "score": 0},
        {"text": "แมวลงบันได", "score": 1},
      ],
    },
    {
      "image": "assets/images/image-13.png",
      "options": [
        {"text": "ต้นไม้", "score": 0},
        {"text": "กอริลลา", "score": 0},
        {"text": "สิงโต", "score": 1},
        {"text": "ปลา", "score": 1},
      ],
    },
    {
      "image": "assets/images/image-14.png",
      "options": [
        {"text": "เด็กทารก", "score": 0},
        {"text": "คู่รัก", "score": 1},
        {"text": "ต้นไม้", "score": 1},
      ],
    },
    {
      "image": "assets/images/image-15.png",
      "options": [
        {"text": "ห่าน หรือ หงส์", "score": 1},
        {"text": "ชายที่นั่งอยู่ริมน้ำ", "score": 0},
        {"text": "ใบหน้าชายแก่", "score": 1},
      ],
    },
    {
      "image": "assets/images/image-16.png",
      "options": [
        {"text": "เด็กผู้หญิง", "score": 1},
        {"text": "หัวกะโหลก", "score": 0},
        {"text": "ผีเสื้อ", "score": 1},
      ],
    },
    {
      "image": "assets/images/image-17.png",
      "options": [
        {"text": "คนเล่นกีต้าร์", "score": 1},
        {"text": "คนใส่เสื้อผ้าสีขาว", "score": 1},
        {"text": "คนใส่เสื้อผ้าสีแดง", "score": 0},
        {"text": "ใบหน้า", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-18.png",
      "options": [
        {"text": "เด็กผู้หญิงสองคน", "score": 1},
        {"text": "เงาโครงหน้า", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-19.png",
      "options": [
        {"text": "เด็กผู้หญิง", "score": 1},
        {"text": "กะโหลก", "score": 0},
        {"text": "ทิวทัศน์หน้าถ้ำ", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-20.png",
      "options": [
        {"text": "ป่า", "score": 0},
        {"text": "ใบหน้าคน", "score": 1},
        {"text": "ฝูงนก", "score": 0},
        {"text": "หมี", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-21.png",
      "options": [
        {"text": "ภูเขา", "score": 0},
        {"text": "ใบหน้าคน", "score": 1},
      ],
    },
    {
      "image": "assets/images/image-22.png",
      "options": [
        {"text": "ผู้ชายที่โดนมัด", "score": 1},
        {"text": "รั้ว", "score": 0},
        {"text": "เรือ", "score": 0},
        {"text": "กะโหลก", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-23.png",
      "options": [
        {"text": "แอปเปิ้ล", "score": 1},
        {"text": "คู่รัก", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-24.png",
      "options": [
        {"text": "รูปคู่รัก", "score": 1},
        {"text": "รูปแอปเปิ้ลแหว่ง", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-25.png",
      "options": [
        {"text": "แจกัน", "score": 0},
        {"text": "ผีเสื้อ", "score": 1},
        {"text": "เงาคู่รัก", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-26.png",
      "options": [
        {"text": "ยูเอฟโอ", "score": 0},
        {"text": "หน้าเอเลี่ยน", "score": 0},
        {"text": "ถ้ำ", "score": 1},
      ],
    },
    {
      "image": "assets/images/image-27.png",
      "options": [
        {"text": "ใบหน้าคน", "score": 0},
        {"text": "หมี", "score": 1},
        {"text": "ป่า และ ดวงจันทร์", "score": 0},
      ],
    },
    {
      "image": "assets/images/image-28.png",
      "options": [
        {"text": "ใบหน้าคนสองคน", "score": 1},
        {"text": "ผีเสื้อ", "score": 0},
        {"text": "เห็นวงกลม", "score": 1},
      ],
    },
    {
      "image": "assets/images/image-29.png",
      "options": [
        {"text": "ต้นไม้", "score": 0},
        {"text": "นก", "score": 1},
      ],
    },
    {
      "image": "assets/images/image-30.png",
      "options": [
        {"text": "เสือ", "score": 1},
        {"text": "ลิง", "score": 0},
      ],
    },
  ];

  var quizList = <Map<String, dynamic>>[].obs;
  var mediaUrlByName = <String, String>{}.obs;

  // สร้างตัวแปรเก็บคำตอบและคะแนนแต่ละข้อ เพื่อเตรียมส่งให้ Backend
  var userAnswersForBackend = <Map<String, dynamic>>[].obs;

  var currentQuestionIndex = 0.obs;
  var totalScore = 0.obs;
  var selectedIndex = (-1).obs;
  var isProcessing = false.obs;
  late final Set<String> _lockedQuizImageFileNames =
      _buildLockedQuizImageFileNames();

  @override
  void onInit() {
    super.onInit();
    generateRandomQuiz();
  }

  void generateRandomQuiz() {
    final shuffledList = List<Map<String, dynamic>>.from(allQuestions)
      ..shuffle();
    quizList.assignAll(shuffledList.take(5).toList());

    currentQuestionIndex.value = 0;
    totalScore.value = 0;
    selectedIndex.value = -1;
    isProcessing.value = false;
    userAnswersForBackend.clear(); // เคลียร์ข้อมูลเก่าเผื่อทำซ้ำ
    _loadAssessmentImagesForCurrentQuiz();
  }

  String resolveImageUrl(String assetPath) {
    final fileName = _resolveLockedQuizFileName(assetPath);
    if (fileName.isEmpty) {
      return '';
    }
    return mediaUrlByName[fileName] ?? '';
  }

  Future<void> _loadAssessmentImagesForCurrentQuiz() async {
    try {
      final currentQuizFileNames = quizList
          .map((question) => _resolveLockedQuizFileName(
                question['image']?.toString() ?? '',
              ))
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

  Set<String> _buildLockedQuizImageFileNames() {
    final fileNames = <String>{};

    for (final question in allQuestions) {
      final fileName = _fileNameFromPath(question['image']?.toString() ?? '');
      if (_isLockedQuizFileName(fileName)) {
        fileNames.add(fileName);
      }
    }

    return fileNames;
  }

  String _resolveLockedQuizFileName(String rawPath) {
    final fileName = _fileNameFromPath(rawPath);
    if (!_lockedQuizImageFileNames.contains(fileName)) {
      return '';
    }
    return fileName;
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

  bool _isLockedQuizFileName(String fileName) {
    if (fileName.isEmpty) {
      return false;
    }
    return _quizImageNamePattern.hasMatch(fileName);
  }

  void selectOption(int optionIndex, String text, int score) {
    if (isProcessing.value) return;

    isProcessing.value = true;
    selectedIndex.value = optionIndex;
    totalScore.value += score;

    // เก็บข้อมูลทีละข้อไว้ส่ง Backend
    userAnswersForBackend.add({
      'questionIndex': currentQuestionIndex.value + 1,
      'imagePath': quizList[currentQuestionIndex.value]['image'],
      'selectedText': text,
      'score': score,
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (currentQuestionIndex.value < 4) {
        currentQuestionIndex.value++;
        selectedIndex.value = -1; // รีเซ็ตสีปุ่มกลับ
        isProcessing.value = false;
      } else {
        // ครบ 5 ข้อ
        final result = RoleQuizSelectionResult(
          totalScore: totalScore.value,
          answers: List<Map<String, dynamic>>.from(userAnswersForBackend),
        );
        isProcessing.value = false;
        Get.back(result: result);
      }
    });
  }
}

// --------------------------------------------------------
// 2. หน้าจอ UI หลัก
// --------------------------------------------------------
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
          if (controller.quizList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4489D7)),
            );
          }

          if (controller.currentQuestionIndex.value >= 5) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4489D7)),
            );
          }

          final currentQuiz =
              controller.quizList[controller.currentQuestionIndex.value];
          final String imagePath = currentQuiz['image'];
          final String imageUrl = controller.resolveImageUrl(imagePath);
          final List<Map<String, dynamic>> options =
              List<Map<String, dynamic>>.from(currentQuiz['options']);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "คุณเห็นอะไรในภาพนี้\nเป็นอย่างแรก",
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                        assetPath: imagePath,
                        imageUrl: imageUrl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "ขอบคุณข้อมูลจาก : lovecampus honghongworld",
                      style: TextStyle(fontSize: 8, color: Color(0xFF4489D7)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Text(
                        "โปรดเลือกคำตอบของคุณ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4489D7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ใช้ ListView.builder ที่ไม่มีปัญหาการ Scroll ซ้อนกัน
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      String optionText = options[index]['text'];
                      int optionScore = options[index]['score'];

                      // 💡 เช็คค่า isSelected ตรงนี้ เพื่อให้ตัว Obx หลักรับรู้และทำงาน!
                      bool isSelected = controller.selectedIndex.value == index;

                      return _buildOptionButton(
                        index,
                        optionText,
                        optionScore,
                        textColor,
                        isSelected, // 💡 ส่งค่า true/false เข้าไปแทน
                        controller,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // --------------------------------------------------------
  // 3. Widget สำหรับปุ่มแต่ละปุ่ม
  // --------------------------------------------------------
  Widget _buildQuizImage({
    required String assetPath,
    required String imageUrl,
  }) {
    if (imageUrl.isEmpty) {
      return _buildFallbackAssetImage(assetPath);
    }

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
        return _buildFallbackAssetImage(assetPath);
      },
    );
  }

  Widget _buildFallbackAssetImage(String assetPath) {
    return Image.asset(
      assetPath,
      width: 230,
      height: 270,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 230,
        height: 270,
        color: Colors.grey[200],
        child: const Icon(
          Icons.broken_image,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    int index,
    String title,
    int score,
    Color textColor,
    bool isSelected,
    QuizController controller,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40),
      decoration: BoxDecoration(
        // 💡 กำหนดสีปุ่มตรงนี้ครับ
        color: isSelected
            ? const Color(0xFF8BE2FB) // สีตอนกด (Selected)
            : const Color(0xFFCEEFFE), // สีก่อนกด (Unselected)
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF5883C4), // สีขอบ (ปรับเปลี่ยนได้ถ้าต้องการ)
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
          onTap: () {
            controller.selectOption(index, title, score);
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

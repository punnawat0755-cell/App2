import 'package:flutter/material.dart';
import 'package:get/get.dart';
// อย่าลืมเช็ค path ของ Encouragement ให้ตรงกับโปรเจกต์ของคุณด้วยนะครับ
import 'package:flutter_application_1/module/encouragement/view/encouragement_view.dart';
import 'package:flutter_application_1/module/rolelogic/view/widget/rolelogic_view.dart';

// ==========================================
// 1. Controller สำหรับจัดการข้อมูลและ Logic
// ==========================================
class PulsecheckController extends GetxController {
  final RxInt selectedMoodIndex = (-1).obs;
  final RxList<String> selectedTags = <String>[].obs;

  final TextEditingController storyController = TextEditingController();
  final TextEditingController healingController = TextEditingController();

  final List<Map<String, String>> moods = const [
    {"image": "assets/images/whale_cry.png", "label": "แย่มาก"},
    {"image": "assets/images/whale_sad.png", "label": "รู้สึกแย่"},
    {"image": "assets/images/whale_impassible.png", "label": "ปกติ"}, // Index 2
    {"image": "assets/images/whale_happy.png", "label": "พอใจ"},
    {"image": "assets/images/whale_love.png", "label": "มีความสุขมาก"},
  ];

  final List<List<String>> moodTags = const [
    [
      'เศร้า',
      'มีความหวัง',
      'หดหู่',
      'พยายามปรับ',
      'สู้ต่อ',
      'ใจเย็นลง',
      'น้อยใจ',
      'โกรธ',
    ],
    [
      'วิตกกังวล',
      'ปล่อยวาง',
      'เสียใจ',
      'ผิดหวัง',
      'สงบนิ่ง',
      'เหนื่อย',
      'โมโห',
      'ดีขึ้น',
    ],
    [
      'เรื่อยๆ',
      'สบายใจ',
      'มีกำลังใจ',
      'ภูมิใจ',
      'สงบนิ่ง',
      'เหนื่อย',
      'เบื่อ',
      'อ่อนเพลีย',
    ], // โชว์อันนี้ก่อน
    [
      'เบิกบาน',
      'ร่าเริง',
      'วิตกกังวล',
      'เฉยๆ',
      'สงบนิ่ง',
      'เหนื่อย',
      'งานเยอะ',
      'สนุกสนาน',
    ],
    [
      'กดดัน',
      'ร่าเริง',
      'ตื่นเต้น',
      'อ่อนล้า',
      'สงบนิ่ง',
      'เหนื่อย',
      'แรงบันดาลใจ',
      'ดีใจ',
    ],
  ];

  final Color mainBlue = const Color(0xFF4A89D8);
  final Color lightFillBlue = const Color(0xFFE0F2FE);
  final Color tagFillBlue = const Color(0xFF93C5FD);

  // 💡 ดึงแท็กมาแสดง: ถ้ายังไม่เลือกวาฬ (-1) ให้ใช้แท็กของ "ปกติ" (index 2) โชว์ไปก่อน
  List<String> get currentTags {
    final index = selectedMoodIndex.value < 0 ? 2 : selectedMoodIndex.value;
    if (index >= moodTags.length) {
      return const [];
    }
    return moodTags[index];
  }

  void selectMood(int index) {
    selectedMoodIndex.value = index;
    selectedTags.clear(); // ล้างแท็กที่เลือกไว้ทิ้งเมื่อเปลี่ยนอารมณ์
  }

  void resetSelection() {
    selectedMoodIndex.value = -1;
    selectedTags.clear();
  }

  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
  }

  void submit() {
    // 💡 เช็คก่อนส่ง: ถ้ายังไม่เลือกวาฬ ให้แจ้งเตือนและหยุดการทำงาน
    if (selectedMoodIndex.value < 0) {
      Get.snackbar(
        "เดี๋ยวก่อน!",
        "อย่าลืมเลือกน้องวาฬบอกความรู้สึกก่อนกดส่งน้า 🐳",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(15),
      );
      return;
    }

    print('อารมณ์: ${moods[selectedMoodIndex.value]['label']}');
    print('แท็ก: ${selectedTags.join(', ')}');
    print('บันทึก: ${storyController.text}');
    print('ฮีลใจ: ${healingController.text}');

    // ถ้ารู้สึกแย่ ให้ไปหน้าให้กำลังใจ
    final isNegativeMood =
        selectedMoodIndex.value == 0 || selectedMoodIndex.value == 1;
    if (isNegativeMood) {
      Get.to(() => Encouragement());
    } else {
      Get.to(() => RoleSelection());
    }
  }

  @override
  void onClose() {
    storyController.dispose();
    healingController.dispose();
    super.onClose();
  }
}

// ==========================================
// 2. หน้าจอ UI (View)
// ==========================================
class Pulsecheck extends StatelessWidget {
  // 💡 เอา controller.resetSelection(); ออกจากตรงนี้แล้ว เพื่อกันปุ่มหายตอนคีย์บอร์ดเด้ง
  Pulsecheck({super.key});

  final PulsecheckController controller =
      Get.isRegistered<PulsecheckController>()
      ? Get.find<PulsecheckController>()
      : Get.put(PulsecheckController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // หัวข้อ
                Text(
                  'วันนี้คุณรู้สึกยังไง ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: controller.mainBlue,
                  ),
                ),
                const SizedBox(height: 24),

                // แถวเลือกน้องวาฬ
                Row(
                  children: List.generate(controller.moods.length, (index) {
                    final isSelected =
                        controller.selectedMoodIndex.value == index;
                    final hasSelection =
                        controller.selectedMoodIndex.value != -1;

                    // 💡 ถ้ายังไม่เลือกใครเลย สว่าง 100% หมด | ถ้าเลือกแล้ว ตัวอื่นจะดรอปสีลงเหลือ 40%
                    final currentOpacity = isSelected
                        ? 1.0
                        : (hasSelection ? 0.4 : 1.0);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => controller.selectMood(index),
                        child: Column(
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: currentOpacity,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 200),
                                scale: isSelected
                                    ? 1.4
                                    : 1.0, // ตัวที่เลือกจะใหญ่ขึ้นนิดนึง
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Image.asset(
                                    controller.moods[index]['image']!,
                                    width: 50,
                                    height: 50,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.pets,
                                          color: controller.mainBlue,
                                          size: 45,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                controller.moods[index]['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: controller.mainBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // ปุ่มแท็กอารมณ์ (จะโชว์ของคำว่า "ปกติ" ขึ้นมาก่อนเสมอ)
                if (controller.currentTags.isNotEmpty)
                  Column(
                    children: [
                      _buildTagRow(controller.currentTags.sublist(0, 4)),
                      const SizedBox(height: 12),
                      _buildTagRow(controller.currentTags.sublist(4, 8)),
                    ],
                  ),
                const SizedBox(height: 32),

                // กล่องบันทึกเรื่องราว
                Text(
                  'บันทึกเรื่องราวของวันนี้',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: controller.mainBlue,
                  ),
                ),
                const SizedBox(height: 10),
                _buildCustomTextField(
                  controller: controller.storyController,
                  hintText: 'มาเริ่มการบันทึกกันเถอะ......',
                  height: 120,
                  maxLength: 200,
                ),
                const SizedBox(height: 24),

                // กล่องประโยคฮีลใจ + เหรียญ
                Row(
                  children: [
                    Text(
                      'ประโยคฮีลใจประจำวัน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: controller.mainBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '+2 coin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Image.asset(
                      'assets/images/coin2.png',
                      height: 18,
                      width: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildCustomTextField(
                  controller: controller.healingController,
                  hintText: 'มาเริ่มการบันทึกกันเถอะ......',
                  height: 80,
                  maxLength: 50,
                ),
                const SizedBox(height: 50),

                // ปุ่มส่งพลังใจ
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: controller.submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB5EFFF),
                        elevation: 6,
                        shadowColor: Colors.black.withOpacity(0.35),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/heartpulse.png',
                            height: 40,
                            width: 40,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.favorite, color: Colors.red),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'ส่งพลังใจ (Energy)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w500, // ปรับให้ตัวหนาขึ้นนิดนึง
                              color: Color(0xFF4489D7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // Widget ย่อย: สร้างแถวของปุ่มแท็ก (Tag Row)
  // ----------------------------------------------------
  Widget _buildTagRow(List<String> rowTags) {
    return Row(
      children: rowTags.map((tag) {
        final isSelected = controller.selectedTags.contains(tag);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () => controller.toggleTag(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? controller.tagFillBlue
                      : controller.lightFillBlue,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: controller.mainBlue, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: controller.mainBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ----------------------------------------------------
  // Widget ย่อย: สร้างกล่องพิมพ์ข้อความ (Text Field)
  // ----------------------------------------------------
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required double height,
    required int maxLength,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: this.controller.lightFillBlue,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: this.controller.mainBlue, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: TextField(
                controller: controller,
                maxLength: maxLength,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: TextStyle(color: this.controller.mainBlue, fontSize: 16),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(color: Colors.black38),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(
                    left: 15,
                    right: 15,
                    top: 15,
                    bottom: 25,
                  ),
                  counterText: '',
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 12,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  return Text(
                    '${value.text.length}/$maxLength',
                    style: TextStyle(
                      color: this.controller.mainBlue.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

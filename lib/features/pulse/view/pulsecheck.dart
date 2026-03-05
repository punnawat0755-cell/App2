import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Pulsecheck extends StatefulWidget {
  const Pulsecheck({super.key});

  @override
  State<Pulsecheck> createState() => _PulsecheckState();
}

class _PulsecheckState extends State<Pulsecheck> {
  // ตัวแปรเก็บค่าที่เลือก
  int selectedMoodIndex = 2; // ค่าเริ่มต้น (ปกติ)
  List<String> selectedTags = [];

  final TextEditingController storyController = TextEditingController();
  final TextEditingController healingController = TextEditingController();

  // ข้อมูลอารมณ์ (รูปวาฬ และ ข้อความ)
  final List<Map<String, String>> moods = [
    {"image": "assets/images/whale_cry.png", "label": "แย่มาก"},
    {"image": "assets/images/whale_sad.png", "label": "รู้สึกแย่"},
    {"image": "assets/images/whale_impassible.png", "label": "ปกติ"},
    {"image": "assets/images/whale_happy.png", "label": "พอใจ"},
    {"image": "assets/images/whale_love.png", "label": "มีความสุขมาก"},
  ];

  // 🌟 ปรับข้อมูลแท็กให้เป็น List ซ้อน List เพื่อแยกตามแต่ละอารมณ์ (Index ตรงกับ moods)
  final List<List<String>> moodTags = [
    // 0: แย่มาก
    [
      "เศร้า",
      "มีความหวัง",
      "หดหู่",
      "พยายามปรับ",
      "สู้ต่อ",
      "ใจเย็นลง",
      "น้อยใจ",
      "โกรธ",
    ],
    // 1: รู้สึกแย่
    [
      "วิตกกังวล",
      "ปล่อยวาง",
      "เสียใจ",
      "ผิดหวัง",
      "สงบนิ่ง",
      "เหนื่อย",
      "โมโห",
      "ดีขึ้น",
    ],
    // 2: ปกติ
    [
      "เรื่อยๆ",
      "สบายใจ",
      "มีกำลังใจ",
      "ภูมิใจ",
      "สงบนิ่ง",
      "เหนื่อย",
      "เบื่อ",
      "อ่อนเพลีย",
    ],
    // 3: พอใจ
    [
      "เบิกบาน",
      "ร่าเริง",
      "วิตกกังวล",
      "เฉยๆ",
      "สงบนิ่ง",
      "เหนื่อย",
      "งานเยอะ",
      "สนุกสนาน",
    ],
    // 4: มีความสุขมาก
    [
      "กดดัน",
      "ร่าเริง",
      "ตื่นเต้น",
      "อ่อนล้า",
      "สงบนิ่ง",
      "เหนื่อย",
      "แรงบันดาลใจ",
      "ดีใจ",
    ],
  ];

  // โทนสีหลักของแอป
  final Color mainBlue = const Color(0xFF4A89D8);
  final Color lightFillBlue = const Color(0xFFE0F2FE);
  final Color tagFillBlue = const Color(0xFF93C5FD);

  @override
  Widget build(BuildContext context) {
    // 🌟 ดึงชุดคำ (Tags) ปัจจุบันที่ต้องแสดงผล ตามอารมณ์ที่เลือกไว้
    List<String> currentTags = moodTags[selectedMoodIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. หัวข้อ ---
              Text(
                "วันนี้คุณรู้สึกยังไง ?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: mainBlue,
                ),
              ),
              const SizedBox(height: 24),

              // --- 2. แถวเลือกอารมณ์ (น้องวาฬ) ---
              Row(
                children: List.generate(moods.length, (index) {
                  bool isSelected = selectedMoodIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedMoodIndex = index; // เปลี่ยนอารมณ์วาฬ
                          selectedTags
                              .clear(); // 🌟 เคลียร์แท็กที่เคยเลือกไว้เมื่อเปลี่ยนอารมณ์หลัก
                        });
                      },
                      child: Column(
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isSelected ? 1.0 : 0.4,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: isSelected ? 1.5 : 1.0,
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Image.asset(
                                  moods[index]["image"]!,
                                  width: 50,
                                  height: 50,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.pets,
                                        color: mainBlue,
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
                              moods[index]["label"]!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: mainBlue,
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

              // --- 3. แท็กความรู้สึก ---
              Column(
                children: [
                  _buildTagRow(currentTags.sublist(0, 4)),
                  const SizedBox(height: 12),
                  _buildTagRow(currentTags.sublist(4, 8)),
                ],
              ),
              const SizedBox(height: 32),

              // --- 4. บันทึกเรื่องราวของวันนี้ ---
              Text(
                "บันทึกเรื่องราวของวันนี้",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainBlue,
                ),
              ),
              const SizedBox(height: 10),
              _buildCustomTextField(
                controller: storyController,
                hintText: "มาเริ่มการบันทึกกันเถอะ......",
                height: 120,
                maxLength: 200, // 🌟 เพิ่มอันนี้ให้แล้ว
              ),
              const SizedBox(height: 24),

              // --- 5. ประโยคฮีลใจประจำวัน + Coin ---
              Row(
                children: [
                  Text(
                    "ประโยคฮีลใจประจำวัน",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mainBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "+2 coin",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Image.asset("assets/images/coin2.png", height: 18, width: 18),
                ],
              ),
              const SizedBox(height: 10),
              _buildCustomTextField(
                controller: healingController,
                hintText: "มาเริ่มการบันทึกกันเถอะ......",
                height: 80,
                maxLength: 50, // 🌟 เพิ่มอันนี้ให้แล้ว
              ),
              const SizedBox(height: 40),

              // --- 6. ปุ่มส่งพลังใจ ---
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (kDebugMode) {
                        debugPrint(
                          "อารมณ์: ${moods[selectedMoodIndex]['label']}",
                        );
                        debugPrint("แท็ก: $selectedTags");
                        debugPrint("บันทึก: ${storyController.text}");
                        debugPrint("ฮีลใจ: ${healingController.text}");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB5EFFF),
                      elevation: 6,
                      shadowColor: Colors.black.withAlpha(89),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/heartpulse.png",
                          height: 40,
                          width: 40,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "ส่งพลังใจ (Energy)",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4489D7),
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
    );
  }

  // --- Widget ย่อย: สร้างแถวของ Tag ความรู้สึก ---
  Widget _buildTagRow(List<String> rowTags) {
    return Row(
      children: rowTags.map((tag) {
        bool isSelected = selectedTags.contains(tag);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedTags.remove(tag);
                  } else {
                    selectedTags.add(tag);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? tagFillBlue : lightFillBlue,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: mainBlue, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: mainBlue,
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

  // --- Widget ย่อย: สร้างช่องกรอกข้อความสไตล์ Custom ---
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required double height,
    required int maxLength,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: lightFillBlue,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: mainBlue, width: 1),
      ),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            maxLength: maxLength,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: TextStyle(color: mainBlue, fontSize: 16),
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
              counterText: "",
            ),
          ),
          Positioned(
            bottom: 8,
            right: 12,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                return Text(
                  "${value.text.length}/$maxLength",
                  style: TextStyle(
                    color: mainBlue.withAlpha(128),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }, // 🌟 ปิดวงเล็บที่หายไปตรงนี้
            ), // 🌟 และตรงนี้
          ), // 🌟 และตรงนี้
        ],
      ),
    );
  }
}

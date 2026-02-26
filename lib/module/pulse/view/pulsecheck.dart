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

  // ข้อมูลแท็กความรู้สึก
  final List<String> tags = [
    "เศร้า",
    "มีความหวัง",
    "หดหู่",
    "พยายามปรับ",
    "สู้ต่อ",
    "ใจเย็นลง",
    "น้อยใจ",
    "โกรธ",
  ];

  // โทนสีหลักของแอป
  final Color mainBlue = const Color(0xFF4A89D8);
  final Color lightFillBlue = const Color(0xFFE0F2FE); // สีฟ้าน้ำทะเลอ่อนๆ
  final Color tagFillBlue = const Color(
    0xFF93C5FD,
  ); // สีฟ้าเข้มสำหรับปุ่มที่เลือก

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // สีพื้นหลังแอปออกเทาขาวนิดๆ
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 30,
          ), // ลดขอบซ้ายขวานิดนึงให้มีพื้นที่
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
                      onTap: () => setState(() => selectedMoodIndex = index),
                      child: Column(
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isSelected ? 1.0 : 0.4,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: isSelected
                                  ? 1.3
                                  : 1.0, // ปรับ scale ลงนิดนึงไม่ให้เบียดกันเกินไป
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.asset(
                                  moods[index]["image"]!,
                                  width: 45,
                                  height: 45,
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

              // --- 3. แท็กความรู้สึก (แยกฟังก์ชันเพื่อลดความซ้ำซ้อน) ---
              Column(
                children: [
                  _buildTagRow(
                    tags.sublist(0, 4),
                  ), // ดึง 4 คำแรกมาสร้างเป็นบรรทัดที่ 1
                  const SizedBox(height: 12),
                  _buildTagRow(
                    tags.sublist(4, 8),
                  ), // ดึง 4 คำหลังมาสร้างเป็นบรรทัดที่ 2
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
                      color: Color(0xFFFBBF24), // สีเหลืองทอง
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.monetization_on,
                    color: Color(0xFFFBBF24),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildCustomTextField(
                controller: healingController,
                hintText: "มาเริ่มการบันทึกกันเถอะ......",
                height: 80,
              ),
              const SizedBox(height: 40),

              // --- 6. ปุ่มส่งพลังใจ ---
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: ทำการบันทึกข้อมูลเข้า Database
                      print("อารมณ์: ${moods[selectedMoodIndex]['label']}");
                      print("แท็ก: $selectedTags");
                      print("บันทึก: ${storyController.text}");
                      print("ฮีลใจ: ${healingController.text}");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB5EFFF), // สีฟ้าพาสเทล
                      elevation: 0, // เอาเงาออกให้ดูคลีนมินิมอล
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: Colors.black12, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Color(0xFFEF4444),
                          size: 28,
                        ), // หัวใจสีแดง
                        const SizedBox(width: 10),
                        Text(
                          "ส่งพลังใจ (Energy)",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: mainBlue,
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
              // ใช้ AnimatedContainer เพื่อให้ตอนกดสลับสีดูนุ่มนวลขึ้น
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
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: TextStyle(color: mainBlue, fontSize: 16),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.black38),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(15),
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Icon(
              Icons.signal_cellular_4_bar_rounded,
              color: Colors.grey.withOpacity(0.4),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

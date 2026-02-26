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
    "เครียด",
    "เหนื่อย",
    "เฉย ๆ",
    "หงุดหงิด",
    "งานเยอะ",
    "นอนไม่พอ",
    "รถติด",
    "ป่วย",
  ];

  // โทนสีหลักของแอป
  final Color mainBlue = const Color(0xFF4A89D8);
  final Color lightFillBlue = const Color(0xFFE0F2FE); // สีฟ้าน้ำทะเลอ่อนๆ
  final Color tagFillBlue = const Color(
    0xFF93C5FD,
  ); // สีฟ้าเข้มขึ้นมาหน่อยสำหรับปุ่มที่เลือก

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF9FAFB,
      ), // สีพื้นหลังแอปออกเทาขาวนิดๆ ตามรูป
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
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
              const SizedBox(height: 20),

              // --- 2. แถวเลือกอารมณ์ (น้องวาฬ) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(moods.length, (index) {
                  bool isSelected = selectedMoodIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => selectedMoodIndex = index),
                    child: Column(
                      children: [
                        // กล่องใส่รูปวาฬ (ใส่เอฟเฟกต์เด้ง/เปลี่ยนสีตอนเลือกได้)
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? lightFillBlue
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? mainBlue : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Image.asset(
                            moods[index]["image"]!,
                            width: 50, // ปรับขนาดรูปวาฬตรงนี้
                            height: 50,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.pets,
                              color: mainBlue,
                              size: 90,
                            ), // เผื่อหาไฟล์ไม่เจอ
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          moods[index]["label"]!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: mainBlue,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),

              // --- 3. แท็กความรู้สึก (เลือกได้หลายอัน) ---
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: tags.map((tag) {
                  bool isSelected = selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedTags.remove(tag);
                        } else {
                          selectedTags.add(tag);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? tagFillBlue : lightFillBlue,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: mainBlue, width: 1),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.white : mainBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

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
              const SizedBox(height: 20),

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
                  const SizedBox(width: 10),
                  const Text(
                    "+2 coin",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFBBF24), // สีเหลืองทอง
                    ),
                  ),
                  const SizedBox(width: 2),
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
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(
                          color: Colors.black12,
                          width: 1,
                        ), // ขอบบางๆ
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
                          "ส่งพลังใจ(Energy)",
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

  // --- Widget ช่วยสร้างช่องกรอกข้อความสไตล์ตามรูป ---
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: lightFillBlue, // พื้นหลังสีฟ้าอ่อน
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: mainBlue, width: 1), // ขอบสีฟ้า
      ),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            maxLines: null, // พิมพ์ได้หลายบรรทัด
            keyboardType: TextInputType.multiline,
            style: const TextStyle(color: Color(0xFF4A89D8), fontSize: 16),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.black38),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(15),
            ),
          ),
          // ลายเส้นเฉียงๆ ที่มุมขวาล่างเหมือนในรูป
          Positioned(
            bottom: 5,
            right: 5,
            child: Icon(
              Icons
                  .signal_cellular_4_bar_rounded, // ใช้ไอคอนนี้แทนลายเส้นมุมกล่องได้เนียนๆ
              color: Colors.grey.withOpacity(0.5),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

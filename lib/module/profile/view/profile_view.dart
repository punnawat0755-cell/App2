import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ==========================================
// 1. Controller: จัดการข้อมูล
// ==========================================
class ProfileController extends GetxController {
  // --- ส่วนเดิม ---
  var coins = 138.obs;
  var currentMonth = "มกราคม".obs;
  var selectedDate = 20.obs;
  final List<int> periodDays = [29, 30, 31];

  final Map<int, String> whaleMoods = {
    1: 'whale_happy',
    2: 'whale_cry',
    3: 'whale_happy',
    4: 'whale_happy',
    5: 'whale_happy',
    7: 'whale_sad',
    11: 'whale_impassible',
    12: 'whale_love',
    13: 'whale_happy',
    14: 'whale_happy',
    15: 'whale_happy',
    16: 'whale_impassible',
    17: 'whale_love',
    18: 'whale_love',
    19: 'whale_love',
    20: 'whale_love',
    21: 'whale_sad',
    22: 'whale_sad',
    24: 'whale_happy',
    25: 'whale_happy',
    26: 'whale_happy',
    28: 'whale_happy',
    29: 'whale_love',
    30: 'whale_love',
    31: 'whale_love',
  };

  String getWhaleImage(int day) {
    String? type = whaleMoods[day];
    // * อย่าลืมเช็ค path รูปภาพในเครื่องนะครับ *
    if (type == 'whale_happy') return 'assets/images/whale_happy.png';
    if (type == 'whale_love') return 'assets/images/whale_love.png';
    if (type == 'whale_impassible') return 'assets/images/whale_impassible.png';
    if (type == 'whale_sad') return 'assets/images/whale_sad.png';
    if (type == 'whale_cry') return 'assets/images/whale_cry.png';
    return 'assets/images/whale_happy.png';
  }

  // --- ส่วนที่เพิ่มใหม่ (สำหรับบันทึกอาการ) ---

  // สถานะประจำเดือน (true = เป็น, false = ไม่เป็น)
  var isPeriodStatus = true.obs;

  // รายการอาการที่เลือก
  var selectedSymptoms = <String>[].obs;

  // ข้อมูลอาการและรูปภาพ (คุณต้องหารูปไอคอนมาใส่ใน assets นะครับ)
  final List<Map<String, String>> symptomsList = [
    {'name': 'ปวดท้อง', 'img': 'assets/images/sym_pain.png'},
    {'name': 'แปรปรวน', 'img': 'assets/images/sym_mood.png'},
    {'name': 'ท้องอืด', 'img': 'assets/images/sym_bloat.png'},
    {'name': 'ปวดหัวไมเกรน', 'img': 'assets/images/sym_headache.png'},
    {'name': 'หงุดหงิด', 'img': 'assets/images/sym_angry.png'},
    {'name': 'เป็นไข้', 'img': 'assets/images/sym_fever.png'},
    {'name': 'หิวบ่อย', 'img': 'assets/images/sym_hungry.png'},
    {'name': 'สิวขึ้น', 'img': 'assets/images/sym_acne.png'},
  ];

  void toggleSymptom(String name) {
    if (selectedSymptoms.contains(name)) {
      selectedSymptoms.remove(name);
    } else {
      selectedSymptoms.add(name);
    }
  }
}

// ==========================================
// 2. View: หน้าจอ ProfilePage
// ==========================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------
              // 1. ส่วนหัว: เหรียญ และ รูปโปรไฟล์
              // ---------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDA7B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/k1.png',
                          width: 35,
                          height: 30,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.error, size: 30),
                        ),
                        const SizedBox(width: 1),
                        Obx(
                          () => Text(
                            "${controller.coins}",
                            style: const TextStyle(
                              color: Color(0xFF5D4037),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ---------------------------------------------------
              // 2. หัวข้อปฏิทิน
              // ---------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "รอบเดือนและอาการ",
                    style: TextStyle(
                      color: Color(0xFF4489D7),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Obx(
                        () => Text(
                          controller.currentMonth.value,
                          style: const TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF757575),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ---------------------------------------------------
              // 3. ปฏิทิน
              // ---------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCEEFFE).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF90CAF9),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"]
                          .map(
                            (day) => SizedBox(
                              width: 35,
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF4489D7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 35,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 0.65,
                            mainAxisSpacing: 5,
                            crossAxisSpacing: 0,
                          ),
                      itemBuilder: (context, index) {
                        int offset = 4;
                        int day = index - offset + 1;
                        if (day < 1 || day > 31) return const SizedBox();

                        return Obx(() {
                          bool isSelected =
                              controller.selectedDate.value == day;
                          bool isPeriod = controller.periodDays.contains(day);
                          String? whaleIcon = controller.whaleMoods[day];

                          BorderRadius? periodRadius;
                          if (isPeriod) {
                            if (day == controller.periodDays.first)
                              periodRadius = const BorderRadius.horizontal(
                                left: Radius.circular(20),
                              );
                            else if (day == controller.periodDays.last)
                              periodRadius = const BorderRadius.horizontal(
                                right: Radius.circular(20),
                              );
                            else
                              periodRadius = BorderRadius.zero;
                          }

                          return Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFFD54F)
                                      : (isPeriod
                                            ? const Color(0xFFFFCCBC)
                                            : Colors.transparent),
                                  shape: isSelected
                                      ? BoxShape.circle
                                      : BoxShape.rectangle,
                                  borderRadius: isSelected
                                      ? null
                                      : periodRadius,
                                ),
                                child: Text(
                                  "$day",
                                  style: const TextStyle(
                                    color: Color(0xFF4489D7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (whaleIcon != null)
                                Image.asset(
                                  controller.getWhaleImage(day),
                                  width: 33,
                                  height: 33,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const SizedBox(),
                                )
                              else
                                const SizedBox(height: 24),
                            ],
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ===================================================
              // ส่วนที่ 4: บันทึกอาการ (ปรับปรุงใหม่ตามรูป)
              // ===================================================
              const Text(
                "บันทึกอาการ",
                style: TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // 4.1 ปุ่มเลือกสถานะประจำเดือน (ซ้าย/ขวา)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ปุ่ม: เป็นประจำเดือน
                  InkWell(
                    onTap: () => controller.isPeriodStatus.value = true,
                    child: Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: controller.isPeriodStatus.value
                              ? const Color(0xFF90CAF9)
                              : Colors.transparent, // ฟ้าเมื่อเลือก
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                          border: Border.all(
                            color: const Color(0xFF5D4037),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "เป็นประจำเดือน",
                          style: TextStyle(
                            color: const Color(0xFF5D4037),
                            fontWeight: controller.isPeriodStatus.value
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ปุ่ม: ไม่เป็นประจำเดือน
                  InkWell(
                    onTap: () => controller.isPeriodStatus.value = false,
                    child: Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: !controller.isPeriodStatus.value
                              ? const Color(0xFFFFE082)
                              : Colors.transparent, // เหลืองเมื่อเลือก
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          border: Border.all(
                            color: const Color(0xFF5D4037),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "ไม่เป็นประจำเดือน",
                          style: TextStyle(
                            color: const Color(0xFF5D4037),
                            fontWeight: !controller.isPeriodStatus.value
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4.2 ตารางไอคอนอาการป่วย (Grid)
              Obx(
                () => Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  alignment: WrapAlignment.center,
                  children: controller.symptomsList.map((item) {
                    bool isSelected = controller.selectedSymptoms.contains(
                      item['name'],
                    );
                    return InkWell(
                      onTap: () => controller.toggleSymptom(item['name']!),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFFE082,
                              ), // สีพื้นหลังไอคอนเหลืองอ่อน
                              borderRadius: BorderRadius.circular(15),
                              border: isSelected
                                  ? Border.all(color: Colors.red, width: 2)
                                  : Border.all(
                                      color: Colors.black12,
                                    ), // ขอบแดงถ้าเลือก
                            ),
                            child: Image.asset(
                              item['img']!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.brown,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item['name']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5D4037),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 30),

              // 4.3 ปุ่มบันทึก (ด้านล่างขวา)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    // Logic บันทึกข้อมูล
                    Get.snackbar(
                      "สำเร็จ",
                      "บันทึกข้อมูลอาการเรียบร้อย",
                      backgroundColor: const Color(0xFF1E3A8A),
                      colorText: Colors.white,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C5282), // สีน้ำเงินเข้ม
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    "บันทึก",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

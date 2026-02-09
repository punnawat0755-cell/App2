import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ==========================================
// 1. Controller: จัดการข้อมูล
// ==========================================
class ProfileController extends GetxController {
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
    if (type == 'whale_happy') return 'assets/images/whale_happy.png';
    if (type == 'whale_love') return 'assets/images/whale_love.png';
    if (type == 'whale_impassible') return 'assets/images/whale_impassible.png';
    if (type == 'whale_sad') return 'assets/images/whale_sad.png';
    if (type == 'whale_cry') return 'assets/images/whale_cry.png';
    return 'assets/images/whale_happy.png';
  }

  var isPeriodStatus = true.obs;
  var selectedSymptoms = <String>[].obs;

  final List<Map<String, String>> symptomsList = [
    {'name': 'ปวดท้อง', 'img': 'assets/images/thunder 1.png'},
    {'name': 'แปรปรวน', 'img': 'assets/images/thunder 2.png'},
    {'name': 'ท้องอืด', 'img': 'assets/images/thunder 3.png'},
    {'name': 'ปวดหัวไมเกรน', 'img': 'assets/images/thunder 4.png'},
    {'name': 'หงุดหงิด', 'img': 'assets/images/thunder 5.png'},
    {'name': 'เป็นไข้', 'img': 'assets/images/thunder 6.png'},
    {'name': 'หิวบ่อย', 'img': 'assets/images/thunder 7.png'},
    {'name': 'สิวขึ้น', 'img': 'assets/images/thunder 8.png'},
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
              // 1. ส่วนหัว
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

              // 2. หัวข้อปฏิทิน
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

              // 3. ปฏิทิน
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
                            if (day == controller.periodDays.first) {
                              periodRadius = const BorderRadius.horizontal(
                                left: Radius.circular(20),
                              );
                            } else if (day == controller.periodDays.last) {
                              periodRadius = const BorderRadius.horizontal(
                                right: Radius.circular(20),
                              );
                            } else {
                              periodRadius = BorderRadius.zero;
                            }
                          }

                          return Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFFD348)
                                      : (isPeriod
                                            ? const Color(0xFFFFBCB5)
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
                                const SizedBox(height: 33),
                            ],
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 4. บันทึกอาการ
              const Text(
                "บันทึกอาการ",
                style: TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 20, // ปรับขนาดตามภาพ
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // ส่วนปุ่มที่แยกกัน มีเงา และสีตามภาพ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatusButton(
                    controller,
                    "เป็นประจำเดือน",
                    const Color(0xFFA6E3F9), // สีฟ้าเมื่อเลือก
                    true,
                  ),
                  _buildStatusButton(
                    controller,
                    "ไม่เป็นประจำเดือน",
                    const Color(0xFFA6E3F9), // สีฟ้าเมื่อเลือก
                    false,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 4.2 ตารางไอคอนอาการป่วย (Grid/Wrap)
              Obx(
                () => Center(
                  // ครอบด้วย Center เพื่อให้ Wrap ทั้งแผงอยู่กลาง
                  child: Wrap(
                    spacing: 15, // ระยะห่างระหว่างไอคอนแนวนอน
                    runSpacing: 20, // ระยะห่างระหว่างแถวแนวตั้ง
                    alignment: WrapAlignment.center, // จัดไอคอนในแถวให้อยู่กลาง
                    children: controller.symptomsList.map((item) {
                      bool isSelected = controller.selectedSymptoms.contains(
                        item['name'],
                      );
                      return InkWell(
                        onTap: () => controller.toggleSymptom(item['name']!),
                        child: SizedBox(
                          width:
                              75, // กำหนดความกว้างที่แน่นอนเพื่อให้ Center/Wrap คำนวณได้แม่นยำ
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFDA7B,
                                  ).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(15),
                                  border: isSelected
                                      ? Border.all(color: Colors.red, width: 2)
                                      : Border.all(color: Colors.black12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  item['img']!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.brown,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['name']!,
                                textAlign: TextAlign
                                    .center, // จัดตัวอักษรให้อยู่กลางใต้ไอคอน
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF5D4037),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Get.snackbar(
                      "สำเร็จ",
                      "บันทึกข้อมูลอาการเรียบร้อย",
                      backgroundColor: const Color(0xFF1E3A8A),
                      colorText: Colors.white,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C5282),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                  ),
                  child: const Text(
                    "บันทึก",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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

  // ฟังก์ชันช่วยสร้างปุ่มที่มีเงาและขอบมนรอบด้าน
  // ฟังก์ชันสร้างปุ่ม บันทึกอาการ (พื้นหลังขาวเมื่อไม่เลือก / ฟ้าเมื่อเลือก / ขอบชัดตลอด)
  Widget _buildStatusButton(
    ProfileController controller,
    String title,
    Color activeColor,
    bool isPeriodTab,
  ) {
    return Obx(() {
      // ตรวจสอบสถานะการเลือก
      bool isSelected = controller.isPeriodStatus.value == isPeriodTab;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.isPeriodStatus.value = isPeriodTab,
          borderRadius: BorderRadius.circular(15),
          // เอฟเฟกต์ตอนกดให้เป็นสีฟ้าอ่อนๆ
          splashColor: const Color(0xFFA6E3F9).withOpacity(0.3),
          highlightColor: const Color(0xFFA6E3F9).withOpacity(0.1),
          child: Ink(
            width: Get.width * 0.42,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              // เงื่อนไข: ถ้าเลือกใช้สีฟ้า (activeColor) ถ้าไม่เลือกใช้สีขาวสะอาด
              color: isSelected ? activeColor : Colors.white,
              borderRadius: BorderRadius.circular(15),
              // ขอบสีเทาเข้มเพื่อให้เห็นทรงปุ่มชัดเจนตลอดเวลาตามรูป
              border: Border.all(color: const Color(0xFF757575), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 4), // เงาด้านล่างเพิ่มมิติ
                ),
              ],
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF424242), // สีตัวอักษรเทาเข้มอ่านง่าย
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    });
  }
}

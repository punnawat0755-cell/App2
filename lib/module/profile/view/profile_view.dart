import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ==========================================
// 1. Controller: จัดการข้อมูลแยกตาม ปี-เดือน-วัน
// ==========================================
class ProfileController extends GetxController {
  var coins = 138.obs;
  var today = DateTime.now().day.obs;
  var selectedMonth = DateTime.now().month.obs;
  var selectedYear = DateTime.now().year.obs;
  var selectedDate = 0.obs;

  final List<int> periodDays = [29, 30, 31];
  var dailyPeriodStatus = <String, bool>{}.obs;
  var dailySymptoms = <String, List<String>>{}.obs;

  String get dateKey =>
      "${selectedYear.value}-${selectedMonth.value}-${selectedDate.value}";

  final List<String> monthNames = [
    "มกราคม",
    "กุมภาพันธ์",
    "มีนาคม",
    "เมษายน",
    "พฤษภาคม",
    "มิถุนายน",
    "กรกฎาคม",
    "สิงหาคม",
    "กันยายน",
    "ตุลาคม",
    "พฤศจิกายน",
    "ธันวาคม",
  ];

  int get daysInMonth =>
      DateTime(selectedYear.value, selectedMonth.value + 1, 0).day;
  int get firstDayOffset =>
      DateTime(selectedYear.value, selectedMonth.value, 1).weekday % 7;

  void changeMonth(String? monthName) {
    if (monthName != null) {
      selectedMonth.value = monthNames.indexOf(monthName) + 1;
      selectedDate.value = 0;
    }
  }

  bool getPeriodStatusForSelectedDay() => dailyPeriodStatus[dateKey] ?? true;
  List<String> getSymptomsForSelectedDay() => dailySymptoms[dateKey] ?? [];

  void setPeriodStatus(bool status) {
    if (selectedDate.value != 0) dailyPeriodStatus[dateKey] = status;
  }

  void toggleSymptom(String symptomName) {
    if (selectedDate.value == 0) return;
    List<String> currentList = List.from(getSymptomsForSelectedDay());
    currentList.contains(symptomName)
        ? currentList.remove(symptomName)
        : currentList.add(symptomName);
    dailySymptoms[dateKey] = currentList;
  }

  void saveDailyData() {
    Get.snackbar(
      "สำเร็จ",
      "บันทึกเรียบร้อย",
      backgroundColor: const Color(0xFF2C5282),
      colorText: Colors.white,
    );
  }

  // --- ฟังก์ชันแสดง Modal คำแนะนำ ---
  void showAdviceModal() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFCEEFFE),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "แนะนำวิธีการดูแลตัวเองช่วงเป็นประจำเดือน",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF4489D7),
                  fontFamily: 'Kanit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildAdviceItem(
                "-พักผ่อนและขยับกายเบาๆ: นอนหลับให้เพียงพอ และอาจโยคะหรือเดินเล่นเบาๆเพื่อช่วยให้ร่างกายหลั่งสารเอ็นดอร์ฟิน ลดความเครียด",
              ),
              _buildAdviceItem(
                "-รักษาความสะอาด: เปลี่ยนผ้าอนามัยทุก 3-4 ชั่วโมง เพื่อป้องกันความอับชื้นและการสะสมของเชื้อแบคทีเรีย",
              ),
              _buildAdviceItem(
                "-ดื่มน้ำอุ่นและเลี่ยงคาเฟอีน: น้ำอุ่นช่วยให้เลือดไหลเวียนดีขึ้น ส่วนการงดกาแฟหรือชาจะช่วยลดอาการคัดตึงหน้าอกและอาการหงุดหงิด",
              ),
              _buildAdviceItem(
                "-เลือกอาหารย่อยง่าย: เน้นทานผัก ผลไม้ และอาหารที่มีธาตุเหล็ก (เช่น ตับ ไข่แดง) เพื่อทดแทนเลือดที่เสียไป และเลี่ยงอาหารรสจัดที่ทำให้ท้องอืด",
              ),
              _buildAdviceItem(
                "-อาหารที่มีแมกนีเซียมสูง: เช่น กล้วย ถั่ว อัลมอนด์ หรือดาร์กช็อกโกแลต ช่วยลดอาการเกร็งของกล้ามเนื้อและบรรเทาอาการ ปวดท้องได้ดี",
              ),
              _buildAdviceItem(
                "-ผลไม้รสเปรี้ยว: เช่น ส้ม มะนาว หรือเบอร์รี่ มีวิตามินซีสูง ช่วยให้ร่างกายดูดซึมธาตุเหล็กได้ดีขึ้น และช่วยลดอาการเหนื่อยล้า",
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CD9FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  "ปิด",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdviceItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF4489D7),
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  final Map<int, String> whaleMoods = {
    1: 'whale_happy',
    2: 'whale_cry',
    12: 'whale_love',
    19: 'whale_love',
    20: 'whale_love',
    30: 'whale_love',
  };

  String getWhaleImage(int day) {
    String? type = whaleMoods[day];
    if (type == 'whale_love') return 'assets/images/whale_love.png';
    if (type == 'whale_cry') return 'assets/images/whale_cry.png';
    return 'assets/images/whale_happy.png';
  }

  String getDefaultSymptomImage(String symptomName) {
    final symptom = symptomsList.firstWhere(
      (e) => e['name'] == symptomName,
      orElse: () => {},
    );
    return symptom['img'] ?? 'assets/images/thunder 1.png';
  }

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
}

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
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.stars,
                            size: 25,
                            color: Colors.brown,
                          ),
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
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(
                      'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 2. เลือกเดือน
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
                  Obx(
                    () => DropdownButton<String>(
                      value: controller
                          .monthNames[controller.selectedMonth.value - 1],
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF757575),
                      ),
                      underline: const SizedBox(),
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (val) => controller.changeMonth(val),
                      items: controller.monthNames
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                    ),
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
                    Obx(
                      () => GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            controller.daysInMonth + controller.firstDayOffset,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 0.65,
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 0,
                            ),
                        itemBuilder: (context, index) {
                          int day = index - controller.firstDayOffset + 1;
                          if (day < 1 || day > controller.daysInMonth)
                            return const SizedBox();

                          return Obx(() {
                            bool isSelected =
                                controller.selectedDate.value == day;
                            bool isToday =
                                controller.today.value == day &&
                                controller.selectedMonth.value ==
                                    DateTime.now().month &&
                                controller.selectedYear.value ==
                                    DateTime.now().year;
                            bool isPeriod = controller.periodDays.contains(day);

                            BorderRadius periodRadius = BorderRadius.zero;
                            if (isPeriod) {
                              if (day == controller.periodDays.first)
                                periodRadius = const BorderRadius.horizontal(
                                  left: Radius.circular(20),
                                );
                              else if (day == controller.periodDays.last)
                                periodRadius = const BorderRadius.horizontal(
                                  right: Radius.circular(20),
                                );
                            }

                            return GestureDetector(
                              onTap: () => controller.selectedDate.value = day,
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (isPeriod)
                                        Container(
                                          width: double.infinity,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFBCB5),
                                            borderRadius: periodRadius,
                                          ),
                                        ),
                                      Container(
                                        width: 36,
                                        height: 36,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFFFD348)
                                              : (isToday
                                                    ? const Color(0xFFCCCCCC)
                                                    : Colors.transparent),
                                          shape: BoxShape.circle,
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
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Image.asset(
                                    controller.getWhaleImage(day),
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) =>
                                        const SizedBox(height: 32),
                                  ),
                                ],
                              ),
                            );
                          });
                        },
                      ),
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              Obx(() {
                if (controller.selectedDate.value == 0) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDA7B),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const Text(
                      "กรุณาเลือกวันที่ต้องการ",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF5D4037),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatusButton(
                          controller,
                          "เป็นประจำเดือน",
                          const Color(0xFFA6E3F9),
                          true,
                        ),
                        const SizedBox(width: 15),
                        _buildStatusButton(
                          controller,
                          "ไม่เป็นประจำเดือน",
                          const Color(0xFFA6E3F9),
                          false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Wrap(
                      spacing: 15,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: controller.symptomsList.map((item) {
                        bool isSelected = controller
                            .getSymptomsForSelectedDay()
                            .contains(item['name']);
                        return GestureDetector(
                          onTap: () => controller.toggleSymptom(item['name']!),
                          child: Column(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFA6E3F9)
                                      : const Color(
                                          0xFFFFDA7B,
                                        ).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF4489D7)
                                        : Colors.black12,
                                    width: 1.5,
                                  ),
                                ),
                                child: Image.asset(
                                  item['img']!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => Image.asset(
                                    controller.getDefaultSymptomImage(
                                      item['name']!,
                                    ),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['name']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF5D4037),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 25),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.saveDailyData();
                          if (controller.getPeriodStatusForSelectedDay() ==
                              true) {
                            controller.showAdviceModal();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C5282),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "บันทึก",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    ProfileController controller,
    String title,
    Color activeColor,
    bool isPeriodTab,
  ) {
    return Obx(() {
      bool isSelected =
          controller.getPeriodStatusForSelectedDay() == isPeriodTab;
      return GestureDetector(
        onTap: () => controller.setPeriodStatus(isPeriodTab),
        child: Container(
          width: Get.width * 0.42,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF757575), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF424242),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }
}

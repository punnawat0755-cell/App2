import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// 1. Controller: จัดการข้อมูลแยกตาม ปี-เดือน-วัน
// ==========================================
class ProfileController extends GetxController {
  var coins = 138.obs;
  var today = DateTime.now().day.obs;
  var selectedMonth = DateTime.now().month.obs;
  var selectedYear = DateTime.now().year.obs;
  var selectedDate = 0.obs;

  // ข้อมูลที่ "บันทึก" ลงเครื่องแล้วจริงๆ
  var dailyPeriodStatus = <String, bool>{}.obs;
  var dailySymptoms = <String, List<String>>{}.obs;

  // ตัวแปรเก็บสถานะ "ชั่วคราว" ขณะกดปุ่ม (จะยังไม่ขึ้นสีแดงในปฏิทินจนกว่าจะกดบันทึก)
  var tempPeriodStatus = false.obs;

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

  // ดึงข้อมูลอาการ
  List<String> getSymptomsForSelectedDay() => dailySymptoms[dateKey] ?? [];

  void toggleSymptom(String symptomName) {
    if (selectedDate.value == 0) return;
    List<String> currentList = List.from(getSymptomsForSelectedDay());
    currentList.contains(symptomName)
        ? currentList.remove(symptomName)
        : currentList.add(symptomName);
    dailySymptoms[dateKey] = currentList;
  }

  // แก้ไขฟังก์ชันบันทึก: ให้นำค่าจาก temp มาใส่ใน daily จริงๆ
  void saveDailyData() {
    if (selectedDate.value == 0) return;

    dailyPeriodStatus[dateKey] = tempPeriodStatus.value;

    Get.snackbar(
      "สำเร็จ",
      "บันทึกเรียบร้อย",
      backgroundColor: const Color(0xFF2C5282),
      colorText: Colors.white,
    );

    if (tempPeriodStatus.value) {
      showAdviceModal();
    }
  }

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
              Text(
                "แนะนำวิธีการดูแลตัวเองช่วงเป็นประจำเดือน",
                textAlign: TextAlign.center,
                style: GoogleFonts.mitr(
                  textStyle: const TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildAdviceItem("-พักผ่อนและขยับกายเบาๆ"),
              _buildAdviceItem("-รักษาความสะอาด เปลี่ยนผ้าอนามัยบ่อยๆ"),
              _buildAdviceItem("-ดื่มน้ำอุ่นและเลี่ยงคาเฟอีน"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CD9FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "ปิด",
                  style: TextStyle(
                    color: Colors.white,
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
        style: const TextStyle(color: Color(0xFF4489D7), fontSize: 14),
      ),
    );
  }

  String getWhaleImage(int day) {
    return 'assets/images/whale_happy.png';
  }
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
              // 1. Coins & Header
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

              // 2. Month Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "รอบเดือนและอาการ",
                    style: GoogleFonts.mitr(
                      textStyle: const TextStyle(
                        color: Color(0xFF4489D7),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
                      style: GoogleFonts.mitr(
                        textStyle: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onChanged: (val) => controller.changeMonth(val),
                      items: controller.monthNames
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(m, style: GoogleFonts.mitr()),
                            ),
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
                            ),
                        itemBuilder: (context, index) {
                          int day = index - controller.firstDayOffset + 1;
                          if (day < 1 || day > controller.daysInMonth)
                            return const SizedBox();

                          return Obx(() {
                            String dayKey =
                                "${controller.selectedYear.value}-${controller.selectedMonth.value}-$day";
                            bool isSelected =
                                controller.selectedDate.value == day;
                            bool isToday =
                                controller.today.value == day &&
                                controller.selectedMonth.value ==
                                    DateTime.now().month;

                            // เช็คสถานะที่บันทึกแล้วจริงๆ
                            bool isSavedPeriod =
                                controller.dailyPeriodStatus[dayKey] ?? false;

                            Color bgColor = Colors.transparent;
                            Color textColor = const Color(0xFF4489D7);

                            if (isSelected) {
                              bgColor = const Color(
                                0xFFFFD348,
                              ); // เลือกอยู่ -> สีเหลือง
                            } else if (isSavedPeriod) {
                              bgColor = const Color(
                                0xFFF05A42,
                              ); // บันทึกแล้ว -> สีแดงเข้ม
                              textColor = Colors.white;
                            } else if (isToday) {
                              bgColor = const Color(
                                0xFFCCCCCC,
                              ); // วันนี้ -> สีเทา
                            }

                            return GestureDetector(
                              onTap: () {
                                controller.selectedDate.value = day;
                                // เมื่อเปลี่ยนวัน ให้ดึงค่าที่เคยบันทึกไว้มาใส่ใน temp
                                controller.tempPeriodStatus.value =
                                    controller.dailyPeriodStatus[dayKey] ??
                                    false;
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "$day",
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Image.asset(
                                    controller.getWhaleImage(day),
                                    width: 32,
                                    height: 32,
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
              Text(
                "บันทึกอาการ",
                style: GoogleFonts.mitr(
                  textStyle: const TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                if (controller.selectedDate.value == 0)
                  return const Center(child: Text("กรุณาเลือกวันที่ต้องการ"));

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ปุ่มสถานะ: กดแล้วเปลี่ยนเป็นฟ้า (temp)
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
                    // ... Wrap อาการ (ส่วนเดิม) ...
                    Wrap(
                      spacing: 15,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: controller.symptomsList.map((item) {
                        bool isSymptomSelected = controller
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
                                  color: isSymptomSelected
                                      ? const Color(0xFFA6E3F9)
                                      : const Color(
                                          0xFFFFDA7B,
                                        ).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: isSymptomSelected
                                        ? const Color(0xFF4489D7)
                                        : Colors.black12,
                                    width: 1.5,
                                  ),
                                ),
                                child: Image.asset(
                                  item['img']!,
                                  fit: BoxFit.contain,
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
                        onPressed: () => controller.saveDailyData(),
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
    bool isPeriodValue,
  ) {
    return Obx(() {
      // เช็คจาก temp เพื่อให้กดแล้วเปลี่ยนเป็นสีฟ้าทันที
      bool isSelected = controller.tempPeriodStatus.value == isPeriodValue;
      return GestureDetector(
        onTap: () => controller.tempPeriodStatus.value = isPeriodValue,
        child: Container(
          width: Get.width * 0.42,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFF757575),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 4),
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

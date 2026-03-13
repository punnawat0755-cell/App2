import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/module/setting/view/setting_view.dart';
import 'package:flutter_application_1/module/user_Profile/widget/app_profile_avatar.dart';

// ==========================================
// 1. Controller: จัดการข้อมูลแยกตาม ปี-เดือน-วัน
// ==========================================
class ProfileController extends GetxController {
  static const int maxSymptomsPerSave = 2;

  var coins = 138.obs;
  var whaleStreakStack = <int>[].obs;
  var today = DateTime.now().day.obs;
  var selectedMonth = DateTime.now().month.obs;
  var selectedYear = DateTime.now().year.obs;
  var selectedDate = 0.obs;

  final List<int> periodDays = [1, 2, 3, 4, 5];
  var dailyPeriodStatus = <String, bool>{}.obs;
  var draftPeriodStatus = <String, bool>{}.obs;
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

  int get currentWhaleStreak =>
      whaleStreakStack.isEmpty ? 0 : whaleStreakStack.last;

  @override
  void onInit() {
    super.onInit();
    recalculateWhaleStreakStack();
  }

  void recalculateWhaleStreakStack() {
    final now = _todayDate;
    final selectedMonthDate = DateTime(selectedYear.value, selectedMonth.value);
    final currentMonthDate = DateTime(now.year, now.month);

    int lastDayToCount;
    if (selectedMonthDate.isAfter(currentMonthDate)) {
      lastDayToCount = 0;
    } else if (selectedMonthDate.isAtSameMomentAs(currentMonthDate)) {
      lastDayToCount = now.day;
    } else {
      lastDayToCount = daysInMonth;
    }

    final stack = <int>[];
    var streak = 0;
    for (var day = 1; day <= lastDayToCount; day++) {
      final hasWhale = getWhaleImage(day) != null;
      if (hasWhale) {
        streak++;
      } else if (streak > 0) {
        stack.add(streak);
        streak = 0;
      }
    }
    if (streak > 0) stack.add(streak);
    whaleStreakStack.assignAll(stack);
  }

  DateTime get _todayDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime dateForDay(int day) =>
      DateTime(selectedYear.value, selectedMonth.value, day);

  bool isFutureDay(int day) => dateForDay(day).isAfter(_todayDate);

  bool get isSelectedDateInFuture {
    final day = selectedDate.value;
    if (day == 0) return false;
    return isFutureDay(day);
  }

  void changeMonth(String? monthName) {
    if (monthName != null) {
      final newMonth = monthNames.indexOf(monthName) + 1;
      selectedMonth.value = newMonth;
      selectedDate.value = 0;
      recalculateWhaleStreakStack();
    }
  }

  bool getPeriodStatusForSelectedDay() {
    if (draftPeriodStatus.containsKey(dateKey)) {
      return draftPeriodStatus[dateKey] ?? false;
    }
    return dailyPeriodStatus[dateKey] ?? false;
  }

  List<String> getSymptomsForSelectedDay() => dailySymptoms[dateKey] ?? [];

  void setPeriodStatus(bool status) {
    if (selectedDate.value == 0) return;
    if (isSelectedDateInFuture) {
      Get.snackbar(
        "แจ้งเตือน",
        "ไม่สามารถบันทึกล่วงหน้าได้",
        backgroundColor: const Color(0xFF2C5282),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    draftPeriodStatus[dateKey] = status;
  }

  void toggleSymptom(String symptomName) {
    if (selectedDate.value == 0) return;
    if (isSelectedDateInFuture) {
      Get.snackbar(
        "แจ้งเตือน",
        "ไม่สามารถบันทึกล่วงหน้าได้",
        backgroundColor: const Color(0xFF2C5282),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    List<String> currentList = List.from(getSymptomsForSelectedDay());
    if (currentList.contains(symptomName)) {
      currentList.remove(symptomName);
    } else {
      if (currentList.length >= maxSymptomsPerSave) {
        Get.snackbar(
          "แจ้งเตือน",
          "เลือกอาการได้ไม่เกิน $maxSymptomsPerSave รายการต่อการบันทึก",
          backgroundColor: const Color(0xFF2C5282),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }
      currentList.add(symptomName);
    }
    dailySymptoms[dateKey] = currentList;
  }

  bool saveDailyData() {
    if (selectedDate.value == 0) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกวันที่ต้องการ",
        backgroundColor: const Color(0xFF2C5282),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
    if (isSelectedDateInFuture) {
      Get.snackbar(
        "แจ้งเตือน",
        "ไม่สามารถบันทึกล่วงหน้าได้ (บันทึกได้เฉพาะวันนี้และย้อนหลัง)",
        backgroundColor: const Color(0xFF2C5282),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    final selectedSymptoms = getSymptomsForSelectedDay();
    if (selectedSymptoms.length > maxSymptomsPerSave) {
      Get.snackbar(
        "แจ้งเตือน",
        "บันทึกได้ไม่เกิน $maxSymptomsPerSave อาการต่อครั้ง",
        backgroundColor: const Color(0xFF2C5282),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    dailyPeriodStatus[dateKey] = getPeriodStatusForSelectedDay();
    draftPeriodStatus.remove(dateKey);

    Get.snackbar(
      "สำเร็จ",
      "บันทึกเรียบร้อย",
      backgroundColor: const Color(0xFF2C5282),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    return true;
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: Get.height * 0.55,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
                ),
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

  void showSymptomAdviceModal(List<String> selectedSymptoms) {
    final uniqueSymptoms = selectedSymptoms.toSet().toList();
    final sections = uniqueSymptoms
        .map((name) => MapEntry(name, symptomAdvice[name] ?? const <String>[]))
        .where((e) => e.value.isNotEmpty)
        .toList();

    if (sections.isEmpty) {
      showAdviceModal();
      return;
    }

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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: Get.height * 0.55,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in sections) ...[
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Color(0xFF4489D7),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final bullet in entry.value)
                          _buildAdviceItem(bullet),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
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
    final normalized = text
        .replaceFirst(RegExp(r'^\s*[-•]\s*'), '')
        .trimRight();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              "•",
              style: TextStyle(
                color: Color(0xFF4489D7),
                fontSize: 16,
                height: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              normalized,
              style: const TextStyle(
                color: Color(0xFF4489D7),
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  final Map<String, List<String>> symptomAdvice = {
    "ปวดท้อง": [
      "ประคบร้อน: ใช้กระเป๋าน้ำร้อนหรือแผ่นแปะลดปวดท้องบริเวณท้องน้อย",
      "ยาแก้ปวดกลุ่ม NSAIDs (ตามคำแนะนำแพทย์/ฉลากยา) เพื่อบรรเทาปวดเกร็ง",
      "ยาคลายกล้ามเนื้อ (เช่น Buscopan) ช่วยลดการเกร็งมดลูกได้บางราย",
      "ดื่มน้ำอุ่น และหลีกเลี่ยงน้ำเย็นจัด",
      "เลี่ยงคาเฟอีน/ชา/แอลกอฮอล์ที่อาจกระตุ้นอาการปวดเพิ่ม",
    ],
    "แปรปรวน": [
      "กินอาหารเชิงซ้อน (เช่น ข้าวกล้อง ธัญพืช) ช่วยให้พลังงานคงที่",
      "ลดน้ำตาลและคาเฟอีน ถ้ากระตุ้นอารมณ์แปรปรวน/นอนไม่หลับ",
      "พักผ่อนให้พอ และทำกิจกรรมเบาๆ เช่น เดิน/ยืดเหยียด",
    ],
    "หงุดหงิด": [
      "Box Breathing: หายใจเข้า 4 วินาที, กลั้น 4 วินาที, ออก 4 วินาที, กลั้น 4 วินาที ทำวนไป 3-4 รอบ เพื่อลดการทำงานของระบบประสาท Sympathetic ที่ทำให้เรารู้สึก \"อยากปะทะ\"",
      "ลดสิ่งเร้า: ปิดเสียงแจ้งเตือน หรือใส่หูฟังตัดเสียงรบกวน (Noise Cancelling) เพื่อลดภาระของสมองในการรับข้อมูล",
    ],
    "ท้องอืด": [
      "ขยับร่างกายเบาๆ เช่น เดินเล่น 10–15 นาที",
      "เลี่ยงอาหารก่อแก๊ส เช่น บรอกโคลี กะหล่ำปลี ถั่วบางชนิด",
      "ลดอาหารรสจัดและของเค็มเพื่อลดบวมน้ำ",
    ],
    "ปวดหัวไมเกรน": [
      "อยู่ในที่เงียบ/แสงน้อย ประคบเย็นบริเวณหน้าผากหรือขมับ",
      "พักสายตา และนอนให้พอ",
      "ดื่มน้ำให้เพียงพอ ลดภาวะขาดน้ำที่กระตุ้นไมเกรน",
      "ยาแก้ปวดตามฉลาก/คำแนะนำแพทย์ หากอาการรุนแรงควรปรึกษาแพทย์",
    ],
    "เป็นไข้": [
      "เช็ดตัว: ใช้ผ้าชุบน้ำอุณหภูมิห้องเช็ดตามข้อพับเพื่อระบายความร้อน",
      "ดื่มน้ำเยอะๆ: ไข้ทำให้ร่างกายเสียน้ำง่าย การดื่มน้ำช่วยลดอุณหภูมิและช่วยให้ระบบภูมิคุ้มกันทำงานดีขึ้น",
      "พักผ่อนแบบ 100%: หยุดกิจกรรมทุกอย่าง เพราะร่างกายต้องใช้พลังงานทั้งหมดไปกับการซ่อมแซม",
    ],
    "หิวจุกจิก": [
      "เน้นโปรตีนและใยอาหาร: กินไข่ต้ม ถั่ว หรือผัก เพื่อให้อิ่มนานขึ้นและน้ำตาลในเลือดนิ่ง",
      "จิบน้ำก่อนกิน: บางครั้งสมองแยกไม่ออกระหว่าง \"หิวน้ำ\" กับ \"หิวข้าว\" ลองดื่มน้ำดูก่อน 1 แก้ว",
      "ดาร์กช็อกโกแลต: ถ้าอยากของหวาน ให้เลือกอันที่มีโกโก้สูงๆ จะช่วยลดความอยากได้ดีกว่าขนมหวานจัดๆ",
    ],
    "สิวขึ้น": [
      "งดสัมผัสใบหน้า: มือเราสกปรกกว่าที่คิด ยิ่งจับยิ่งอักเสบ",
      "ล้างปลอกหมอน: ถ้าสิวขึ้นซ้ำซาก ลองเช็กความสะอาดของที่นอน",
      "ลดนมและน้ำตาล: งานวิจัยหลายฉบับชี้ว่านมวัวและของหวานกระตุ้นการอักเสบของผิว",
    ],
  };

  final Map<int, String> whaleMoods = {
    1: 'whale_happy',
    2: 'whale_cry',
    12: 'whale_love',
    19: 'whale_love',
    20: 'whale_love',
    30: 'whale_love',
  };

  int? get periodStartDayForSelectedMonth {
    int? startDay;
    for (final entry in dailyPeriodStatus.entries) {
      if (entry.value != true) continue;
      final parts = entry.key.split('-');
      if (parts.length != 3) continue;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year == null || month == null || day == null) continue;
      if (year != selectedYear.value || month != selectedMonth.value) continue;
      if (startDay == null || day < startDay) startDay = day;
    }
    return startDay;
  }

  bool isPredictedPeriodDay(int day, int? periodStartDay) {
    final start = periodStartDay ?? 1;
    final end = start + 6;
    return day >= start && day <= end;
  }

  bool shouldShowWhaleOnDay(int day) {
    final isWhaleDay = (day >= 1 && day <= 8) || (day >= 15 && day <= 18);
    if (!isWhaleDay) return false;

    final now = DateTime.now();
    final isFutureMonth =
        selectedYear.value > now.year ||
        (selectedYear.value == now.year && selectedMonth.value > now.month);
    if (isFutureMonth) return false;

    final isCurrentMonth =
        selectedYear.value == now.year && selectedMonth.value == now.month;
    if (!isCurrentMonth) return true;

    return day <= now.day;
  }

  String? getWhaleImage(int day) {
    if (!shouldShowWhaleOnDay(day)) return null;
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
    {'name': 'หิวจุกจิก', 'img': 'assets/images/thunder 7.png'},
    {'name': 'สิวขึ้น', 'img': 'assets/images/thunder 8.png'},
  ];
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: Colors.white,
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
                        ),
                        const SizedBox(width: 1),
                        Obx(
                          () => Text(
                            "${controller.currentWhaleStreak}",
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
                  GestureDetector(
                    onTap: () => Get.to(() => const SettingPage()),
                    child: const AppProfileAvatar(
                      radius: 25,
                      showNotificationDot: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 2. เลือกเดือน
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "รอบเดือนและอาการ",
                    style: GoogleFonts.mitr(
                      textStyle: const TextStyle(
                        color: Color(0xFF4489D7),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Obx(
                    () => DropdownButton<String>(
                      value: controller
                          .monthNames[controller.selectedMonth.value - 1],
                      icon: const SizedBox.shrink(),
                      underline: const SizedBox(),
                      isDense: true,
                      style: GoogleFonts.mitr(
                        textStyle: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selectedItemBuilder: (context) => controller.monthNames
                          .map(
                            (m) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  m,
                                  style: GoogleFonts.mitr(
                                    textStyle: const TextStyle(
                                      color: Color(0xFF757575),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF757575),
                                ),
                              ],
                            ),
                          )
                          .toList(),
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
                    Obx(() {
                      final periodStartDay =
                          controller.periodStartDayForSelectedMonth;
                      return GridView.builder(
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
                            String dayKey =
                                "${controller.selectedYear.value}-${controller.selectedMonth.value}-$day";
                            final hasSavedPeriodStatus = controller
                                .dailyPeriodStatus
                                .containsKey(dayKey);
                            bool isSelected =
                                controller.selectedDate.value == day;
                            bool isToday =
                                controller.today.value == day &&
                                controller.selectedMonth.value ==
                                    DateTime.now().month;
                            final savedIsPeriod =
                                controller.dailyPeriodStatus[dayKey] == true;
                            final isPredictedPeriodDay =
                                controller.isPredictedPeriodDay(
                                  day,
                                  periodStartDay,
                                ) &&
                                !hasSavedPeriodStatus;
                            final isFutureDay = controller.isFutureDay(day);

                            Color bgColor = Colors.transparent;
                            Color textColor = const Color(0xFF4489D7);

                            if (isSelected) {
                              bgColor = const Color(
                                0xFFFFD348,
                              ); // สีเหลืองเมื่อจิ้ม
                            } else if (savedIsPeriod) {
                              bgColor = const Color(
                                0xFFF05A42,
                              ); // สีแดงเมื่อบันทึกแล้ว
                              textColor = Colors.white;
                            } else if (isPredictedPeriodDay) {
                              bgColor = const Color(
                                0xFFF8A5B8,
                              ); // สีชมพู (คาดการณ์)
                              textColor = Colors.white;
                            } else if (isToday) {
                              bgColor = const Color(0xFFCCCCCC);
                            } else if (isFutureDay) {
                              textColor = const Color(0xFFBDBDBD);
                            }

                            return GestureDetector(
                              onTap: () {
                                if (isFutureDay) {
                                  Get.snackbar(
                                    "แจ้งเตือน",
                                    "ไม่สามารถบันทึกล่วงหน้าได้",
                                    backgroundColor: const Color(0xFF2C5282),
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 3),
                                  );
                                  return;
                                }
                                controller.selectedDate.value = day;
                              },
                              behavior: HitTestBehavior.opaque,
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
                                  (() {
                                    final whalePath = controller.getWhaleImage(
                                      day,
                                    );
                                    if (whalePath == null) {
                                      return const SizedBox(height: 32);
                                    }
                                    return Image.asset(
                                      whalePath,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) =>
                                          const SizedBox(height: 32),
                                    );
                                  })(),
                                ],
                              ),
                            );
                          });
                        },
                      );
                    }),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                if (controller.selectedDate.value == 0) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDA7B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(
                          0xFF757575,
                        ), // สีเทาเข้มของเส้นขอบตามรูป
                        width: 1.5, // ความหนาของเส้นขอบ
                      ),
                    ),
                    child: const Text(
                      "กรุณาเลือกวันที่ต้องการ",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF5D4037),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                if (controller.isSelectedDateInFuture) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDA7B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF757575),
                        width: 1.5,
                      ),
                    ),
                    child: const Text(
                      "ไม่สามารถบันทึกล่วงหน้าได้ (บันทึกได้เฉพาะวันนี้และย้อนหลัง)",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF5D4037),
                        fontSize: 16,
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
                          final saved = controller.saveDailyData();
                          if (!saved) return;
                          if (!controller.getPeriodStatusForSelectedDay()) {
                            return;
                          }
                          final selectedSymptoms = controller
                              .getSymptomsForSelectedDay();
                          if (selectedSymptoms.isEmpty) {
                            controller.showAdviceModal();
                          } else {
                            controller.showSymptomAdviceModal(selectedSymptoms);
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

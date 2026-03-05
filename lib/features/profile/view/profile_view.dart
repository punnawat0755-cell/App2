import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// 1. Controller
// ==========================================
class ProfileController extends GetxController {
  final supabase = Supabase.instance.client;

  var coins = 138.obs;
  var today = DateTime.now().day.obs;
  var selectedMonth = DateTime.now().month.obs;
  var selectedYear = DateTime.now().year.obs;
  var selectedDate = DateTime.now().day.obs;

  var isLoading = false.obs;
  var predictionText = "".obs;
  var predictionConfidence = "".obs; // [ใหม่] 'high' หรือ 'low'
  var avgCycleLength = 0.obs;        // [ใหม่] รอบเฉลี่ยจริง
  var latestCycleText = "".obs;

  // [ใหม่] สถิติรวม
  var statTotalCycles = 0.obs;
  var statAvgCycleLength = 0.obs;
  var statAvgPeriodDuration = 0.obs;
  var statCommonSymptoms = <String>[].obs;

  // ข้อมูลจาก Database (รายวัน)
  var dailyPeriodStatus = <String, bool>{}.obs;
  var dailySymptoms = <String, List<String>>{}.obs;
  var dailyWhaleMoods = <String, String>{}.obs;
  var dailyFlowLevel = <String, String?>{}.obs;   // [ใหม่]
  var dailyPainLevel = <String, int?>{}.obs;       // [ใหม่]
  var dailyNotes = <String, String?>{}.obs;        // [ใหม่]

  // State สำหรับ Input ที่กำลังแก้อยู่
  var currentFlowLevel = Rxn<String>();  // [ใหม่]
  var currentPainLevel = Rxn<int>();     // [ใหม่]
  var currentNotes = "".obs;            // [ใหม่]

  final TextEditingController notesController = TextEditingController(); // [ใหม่]

  @override
  void onInit() {
    super.onInit();
    loadMonthData();
    fetchPeriodPrediction();
    fetchLatestCycle();
    fetchMenstrualStats(); // [ใหม่]
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }

  String getDateKey(int year, int month, int day) =>
      "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

  String get dateKey => getDateKey(selectedYear.value, selectedMonth.value, selectedDate.value);

  final List<String> monthNames = [
    "มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน",
    "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม",
  ];

  int get daysInMonth => DateTime(selectedYear.value, selectedMonth.value + 1, 0).day;
  int get firstDayOffset => DateTime(selectedYear.value, selectedMonth.value, 1).weekday % 7;

  void changeMonth(String? monthName) {
    if (monthName != null) {
      selectedMonth.value = monthNames.indexOf(monthName) + 1;
      selectedDate.value = 1;
      _syncInputStateForDate();
      loadMonthData();
    }
  }

  // Sync input fields เมื่อ selectedDate เปลี่ยน
  void selectDay(int day) {
    selectedDate.value = day;
    _syncInputStateForDate();
  }

  void _syncInputStateForDate() {
    final key = dateKey;
    currentFlowLevel.value = dailyFlowLevel[key];
    currentPainLevel.value = dailyPainLevel[key];
    currentNotes.value = dailyNotes[key] ?? "";
    notesController.text = currentNotes.value;
  }

  Future<void> loadMonthData() async {
    try {
      isLoading.value = true;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase.rpc(
        'get_monthly_calendar_data',
        params: {'p_year': selectedYear.value, 'p_month': selectedMonth.value},
      );

      dailyPeriodStatus.clear();
      dailySymptoms.clear();
      dailyWhaleMoods.clear();
      dailyFlowLevel.clear();  // [ใหม่]
      dailyPainLevel.clear();  // [ใหม่]
      dailyNotes.clear();      // [ใหม่]

      if (response != null) {
        for (var row in response) {
          String key = row['calendar_date'].toString();

          dailyPeriodStatus[key] = row['is_menstruating'] ?? false;

          if (row['symptoms'] != null) {
            dailySymptoms[key] = List<String>.from(row['symptoms']);
          }

          // [ใหม่] รับค่า flow_level, pain_level, notes
          dailyFlowLevel[key] = row['flow_level'];
          dailyPainLevel[key] = row['pain_level'];
          dailyNotes[key] = row['notes'];

          if (row['mood_level'] != null) {
            int moodLevel = row['mood_level'];
            if (moodLevel >= 4) {
              dailyWhaleMoods[key] = 'whale_love';
            } else if (moodLevel <= 2) {
              dailyWhaleMoods[key] = 'whale_cry';
            } else {
              dailyWhaleMoods[key] = 'whale_happy';
            }
          }
        }
      }

      _syncInputStateForDate();
    } catch (e) {
      print("Error loading data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchLatestCycle() async {
    try {
      final response = await supabase.rpc('get_my_menstrual_cycles');
      if (response != null && response is List && response.isNotEmpty) {
        var latest = response.first;
        DateTime start = DateTime.parse(latest['start_date'].toString());
        DateTime end = DateTime.parse(latest['end_date'].toString());
        int days = latest['duration_days'];
        String startStr = "${start.day} ${monthNames[start.month - 1]}";
        String endStr = "${end.day} ${monthNames[end.month - 1]}";
        if (startStr == endStr) {
          latestCycleText.value = "รอบเดือนล่าสุด: $startStr (รวม 1 วัน)";
        } else {
          latestCycleText.value = "รอบเดือนล่าสุด: $startStr ถึง $endStr (รวม $days วัน)";
        }
      } else {
        latestCycleText.value = "ยังไม่มีประวัติรอบเดือน";
      }
    } catch (e) {
      latestCycleText.value = "ยังไม่มีประวัติรอบเดือน";
    }
  }

  Future<void> fetchPeriodPrediction() async {
    try {
      final response = await supabase.rpc('predict_next_period');
      if (response != null && response is List && response.isNotEmpty) {
        var data = response[0];
        // [ใหม่] รับ avg_cycle_length และ confidence
        avgCycleLength.value = data['avg_cycle_length'] ?? 28;
        predictionConfidence.value = data['confidence'] ?? 'low';

        if (data['predicted_start_date'] != null) {
          DateTime predictedDate = DateTime.parse(data['predicted_start_date'].toString());
          int daysLeft = predictedDate.difference(DateTime.now()).inDays;
          String thaiDate = "${predictedDate.day} ${monthNames[predictedDate.month - 1]}";

          if (daysLeft == 0) {
            predictionText.value = "คาดว่าประจำเดือนจะมา 🩸 วันนี้";
          } else if (daysLeft > 0) {
            predictionText.value = "คาดว่าประจำเดือนจะมา 🩸 $thaiDate (อีก $daysLeft วัน)";
          } else {
            predictionText.value = "ประจำเดือนมาช้ากว่ากำหนด ${daysLeft.abs()} วัน";
          }
        }
      } else {
        predictionText.value = "บันทึกข้อมูลเพื่อคำนวณรอบเดือนถัดไป 🌸";
        predictionConfidence.value = "";
      }
    } catch (e) {
      predictionText.value = "บันทึกข้อมูลเพื่อคำนวณรอบเดือนถัดไป 🌸";
      predictionConfidence.value = "";
    }
  }

  // [ใหม่] ดึงสถิติรวม
  Future<void> fetchMenstrualStats() async {
    try {
      final response = await supabase.rpc('get_menstrual_stats');
      if (response != null && response is List && response.isNotEmpty) {
        var data = response[0];
        statTotalCycles.value = data['total_cycles_recorded'] ?? 0;
        statAvgCycleLength.value = data['avg_cycle_length'] ?? 0;
        statAvgPeriodDuration.value = data['avg_period_duration'] ?? 0;
        if (data['most_common_symptoms'] != null) {
          statCommonSymptoms.value = List<String>.from(data['most_common_symptoms']);
        }
      }
    } catch (e) {
      print("Error fetching stats: $e");
    }
  }

  bool getPeriodStatusForSelectedDay() => dailyPeriodStatus[dateKey] ?? false;
  List<String> getSymptomsForSelectedDay() => dailySymptoms[dateKey] ?? [];

  void setPeriodStatus(bool status) {
    if (selectedDate.value != 0) {
      dailyPeriodStatus[dateKey] = status;
      dailyPeriodStatus.refresh();
      // ถ้าเปลี่ยนเป็น "ไม่เป็น" ให้ reset flow และ pain
      if (!status) {
        currentFlowLevel.value = null;
        currentPainLevel.value = null;
      }
    }
  }

  void toggleSymptom(String symptomName) {
    if (selectedDate.value == 0) return;
    List<String> currentList = List.from(getSymptomsForSelectedDay());
    if (currentList.contains(symptomName)) {
      currentList.remove(symptomName);
    } else {
      currentList.add(symptomName);
    }
    dailySymptoms[dateKey] = currentList;
    dailySymptoms.refresh();
  }

  Future<void> saveDailyData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      Get.snackbar("ข้อผิดพลาด", "กรุณาเข้าสู่ระบบก่อน",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    try {
      bool isPeriod = getPeriodStatusForSelectedDay();
      await supabase.rpc(
        'save_calendar_health_log',
        params: {
          'p_log_date': dateKey,
          'p_is_menstruating': isPeriod,
          'p_symptoms': getSymptomsForSelectedDay(),
          // [ใหม่] ส่งค่าใหม่ทั้งหมด (null ถ้าไม่เป็นประจำเดือน)
          'p_flow_level': isPeriod ? currentFlowLevel.value : null,
          'p_pain_level': isPeriod ? currentPainLevel.value : null,
          'p_notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        },
      );

      // อัปเดต local state
      dailyFlowLevel[dateKey] = isPeriod ? currentFlowLevel.value : null;
      dailyPainLevel[dateKey] = isPeriod ? currentPainLevel.value : null;
      dailyNotes[dateKey] = notesController.text.trim().isEmpty ? null : notesController.text.trim();

      Get.snackbar(
        "สำเร็จ ✨",
        "บันทึกข้อมูลวันที่ ${selectedDate.value} เรียบร้อยแล้ว",
        backgroundColor: const Color(0xFF2C5282),
        colorText: Colors.white,
      );

      fetchPeriodPrediction();
      fetchLatestCycle();
      fetchMenstrualStats(); // [ใหม่] รีเฟรชสถิติ

      if (isPeriod) showAdviceModal();
    } catch (e) {
      Get.snackbar("เกิดข้อผิดพลาด", "ไม่สามารถบันทึกข้อมูลได้: $e",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
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
              _buildAdviceItem("- พักผ่อนและขยับกายเบาๆ: นอนหลับให้เพียงพอ และอาจโยคะหรือเดินเล่นเบาๆ เพื่อช่วยให้ร่างกายหลั่งสารเอ็นดอร์ฟิน ลดความเครียด"),
              _buildAdviceItem("- รักษาความสะอาด: เปลี่ยนผ้าอนามัยทุก 3-4 ชั่วโมง เพื่อป้องกันความอับชื้นและการสะสมของเชื้อแบคทีเรีย"),
              _buildAdviceItem("- ดื่มน้ำอุ่นและเลี่ยงคาเฟอีน: น้ำอุ่นช่วยให้เลือดไหลเวียนดีขึ้น ส่วนการงดกาแฟหรือชาจะช่วยลดอาการคัดตึงหน้าอก"),
              _buildAdviceItem("- เลือกอาหารย่อยง่าย: เน้นทานผัก ผลไม้ และอาหารที่มีธาตุเหล็ก เพื่อทดแทนเลือดที่เสียไป"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CD9FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                ),
                child: const Text("ปิด",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
      child: Text(text,
          textAlign: TextAlign.left,
          style: const TextStyle(color: Color(0xFF4489D7), fontSize: 13, height: 1.4)),
    );
  }

  String getWhaleImage(int day) {
    String dk = getDateKey(selectedYear.value, selectedMonth.value, day);
    String? type = dailyWhaleMoods[dk];
    if (dailyPeriodStatus[dk] == true) return 'assets/images/whale_cry.png';
    if (type == 'whale_love') return 'assets/images/whale_love.png';
    if (type == 'whale_cry') return 'assets/images/whale_cry.png';
    return 'assets/images/whale_happy.png';
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

// ==========================================
// 2. ProfilePage
// ==========================================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  late ProfileController controller;

  @override
  void initState() {
    super.initState();
    // ใช้ permanent: false เพื่อให้ GetX ไม่ cache controller ข้ามหน้า
    controller = Get.put(ProfileController(), permanent: false);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ดักตอนแอพกลับมาจาก background (ปิดแล้วเปิดใหม่)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadAll();
    }
  }

  // ดักตอน navigate กลับมาหน้านี้จากหน้าอื่น
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reloadAll();
  }

  void _reloadAll() {
    controller.loadMonthData();
    controller.fetchPeriodPrediction();
    controller.fetchLatestCycle();
    controller.fetchMenstrualStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDA7B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Image.asset('assets/images/k1.png', width: 35, height: 30),
                        const SizedBox(width: 5),
                        Obx(() => Text(
                          "${controller.coins}",
                          style: const TextStyle(
                              color: Color(0xFF5D4037), fontWeight: FontWeight.bold, fontSize: 16),
                        )),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(
                        'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg'),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // ─── Title + Month Picker ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "รอบเดือนและอาการ",
                    style: GoogleFonts.mitr(
                      textStyle: const TextStyle(
                          color: Color(0xFF4489D7), fontSize: 22, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Obx(() => DropdownButton<String>(
                    value: controller.monthNames[controller.selectedMonth.value - 1],
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF757575)),
                    underline: const SizedBox(),
                    style: GoogleFonts.mitr(
                      textStyle: const TextStyle(
                          color: Color(0xFF757575), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onChanged: (val) => controller.changeMonth(val),
                    items: controller.monthNames
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                  )),
                ],
              ),
              const SizedBox(height: 10),

              // ─── Banner: รอบเดือนล่าสุด ────────────────────────────
              Obx(() {
                final text = controller.latestCycleText.value;
                if (text.isEmpty || text == "ยังไม่มีประวัติรอบเดือน") return const SizedBox();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFFFD348), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFFF05A42), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                              color: Color(0xFF5D4037), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // ─── Banner: การทำนาย + Confidence ────────────────────
              Obx(() {
                final prediction = controller.predictionText.value;
                if (prediction.isEmpty || prediction.contains('🌸')) return const SizedBox();
                final confidence = controller.predictionConfidence.value;
                final avgCycle = controller.avgCycleLength.value;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFFF05A42)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              prediction,
                              style: const TextStyle(
                                  color: Color(0xFF5D4037),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      // [ใหม่] แสดง confidence และรอบเฉลี่ย
                      if (confidence.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SizedBox(width: 34),
                            _ConfidenceBadge(confidence: confidence),
                            const SizedBox(width: 8),
                            if (avgCycle > 0)
                              Text(
                                "รอบเฉลี่ย $avgCycle วัน",
                                style: const TextStyle(
                                    color: Color(0xFF9E9E9E), fontSize: 12),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),

              // ─── Calendar ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCEEFFE).withAlpha(128),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"]
                          .map((day) => SizedBox(
                        width: 35,
                        child: Text(day,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFF4489D7),
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Obx(() {
                      if (controller.isLoading.value) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                              child: CircularProgressIndicator(color: Color(0xFF4489D7))),
                        );
                      }
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
                            String dayKey = controller.getDateKey(
                                controller.selectedYear.value,
                                controller.selectedMonth.value,
                                day);
                            bool isSelected = controller.selectedDate.value == day;
                            bool isToday = controller.today.value == day &&
                                controller.selectedMonth.value == DateTime.now().month;
                            bool isPeriodDay =
                                controller.dailyPeriodStatus[dayKey] ?? false;

                            Color bgColor = Colors.transparent;
                            Color textColor = const Color(0xFF4489D7);

                            if (isSelected) {
                              bgColor = const Color(0xFFFFD348);
                            } else if (isPeriodDay) {
                              bgColor = const Color(0xFFF05A42);
                              textColor = Colors.white;
                            } else if (isToday) {
                              bgColor = const Color(0xFFCCCCCC);
                            }

                            return GestureDetector(
                              onTap: () => controller.selectDay(day),
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: bgColor, shape: BoxShape.circle),
                                    child: Text("$day",
                                        style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
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
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // ─── [ใหม่] สถิติรวม ──────────────────────────────────
              _MenstrualStatsCard(controller: controller),
              const SizedBox(height: 25),

              // ─── บันทึกอาการ ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "บันทึกอาการ",
                    style: GoogleFonts.mitr(
                      textStyle: const TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: 22,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  Obx(() => Text(
                    "วันที่ ${controller.selectedDate.value} ${controller.monthNames[controller.selectedMonth.value - 1]}",
                    style: const TextStyle(
                        color: Color(0xFF757575), fontWeight: FontWeight.bold),
                  )),
                ],
              ),
              const SizedBox(height: 20),

              Obx(() {
                if (controller.selectedDate.value == 0) return const SizedBox();

                bool isPeriod = controller.getPeriodStatusForSelectedDay();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ปุ่มสถานะ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatusButton("เป็นประจำเดือน",
                            const Color(0xFFF05A42), Colors.white, true),
                        const SizedBox(width: 15),
                        _buildStatusButton("ไม่เป็นประจำเดือน",
                            const Color(0xFFA6E3F9), const Color(0xFF424242), false),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // [ใหม่] Flow Level (แสดงเฉพาะตอนเป็นประจำเดือน)
                    if (isPeriod) ...[
                      _SectionLabel(label: "ปริมาณเลือด"),
                      const SizedBox(height: 10),
                      _FlowLevelSelector(controller: controller),
                      const SizedBox(height: 20),

                      // [ใหม่] Pain Level
                      _SectionLabel(label: "ระดับความเจ็บปวด"),
                      const SizedBox(height: 10),
                      _PainLevelSelector(controller: controller),
                      const SizedBox(height: 20),
                    ],

                    // อาการ
                    _SectionLabel(label: "อาการ"),
                    const SizedBox(height: 12),
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
                                      : const Color(0xFFFFDA7B).withAlpha(204),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF4489D7)
                                          : Colors.black12,
                                      width: 1.5),
                                ),
                                child: Image.asset(item['img']!, fit: BoxFit.contain),
                              ),
                              const SizedBox(height: 8),
                              Text(item['name']!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF5D4037),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // [ใหม่] Notes
                    _SectionLabel(label: "บันทึกเพิ่มเติม"),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
                      ),
                      child: TextField(
                        controller: controller.notesController,
                        maxLines: 3,
                        style: const TextStyle(color: Color(0xFF5D4037), fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: "จดโน้ตอะไรก็ได้สำหรับวันนี้...",
                          hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // ปุ่มบันทึก
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => controller.saveDailyData(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C5282),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                        ),
                        child: const Text("บันทึกข้อมูล",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
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

  Widget _buildStatusButton(String title,
      Color activeColor, Color activeTextColor, bool isPeriodTab) {
    return Obx(() {
      bool isSelected = controller.getPeriodStatusForSelectedDay() == isPeriodTab;
      return GestureDetector(
        onTap: () => controller.setPeriodStatus(isPeriodTab),
        child: Container(
          width: Get.width * 0.42,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: isSelected ? activeColor : const Color(0xFF757575),
                width: 1.5),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? activeTextColor : const Color(0xFF424242),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }
}

// ==========================================
// Widgets แยกย่อย
// ==========================================

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.mitr(
        textStyle: const TextStyle(
            color: Color(0xFF4489D7), fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ─── [ใหม่] Flow Level Selector ──────────────────────────────────────────────
class _FlowLevelSelector extends StatelessWidget {
  final ProfileController controller;
  const _FlowLevelSelector({required this.controller});

  static const _levels = [
    {'value': 'spotting', 'label': 'Spotting', 'emoji': '🩷', 'desc': 'กระปิดกระปอย'},
    {'value': 'light', 'label': 'Light', 'emoji': '🩸', 'desc': 'น้อย'},
    {'value': 'medium', 'label': 'Medium', 'emoji': '🩸🩸', 'desc': 'ปานกลาง'},
    {'value': 'heavy', 'label': 'Heavy', 'emoji': '🩸🩸🩸', 'desc': 'มาก'},
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.currentFlowLevel.value;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _levels.map((level) {
          final isSelected = selected == level['value'];
          return GestureDetector(
            onTap: () => controller.currentFlowLevel.value = level['value'],
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 75,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF05A42) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFFF05A42) : const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFFF05A42).withOpacity(0.3), blurRadius: 8)]
                    : [],
              ),
              child: Column(
                children: [
                  Text(level['emoji']!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    level['desc']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

// ─── [ใหม่] Pain Level Selector ──────────────────────────────────────────────
class _PainLevelSelector extends StatelessWidget {
  final ProfileController controller;
  const _PainLevelSelector({required this.controller});

  static const _painLabels = ['แทบไม่เจ็บ', 'เล็กน้อย', 'พอทน', 'เจ็บมาก', 'ทนไม่ได้'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.currentPainLevel.value;
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (i) {
              final level = i + 1;
              final isSelected = selected == level;
              return GestureDetector(
                onTap: () => controller.currentPainLevel.value = level,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected ? _painColor(level) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? _painColor(level) : const Color(0xFFE0E0E0),
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: _painColor(level).withOpacity(0.35), blurRadius: 8)]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$level',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (selected != null) ...[
            const SizedBox(height: 8),
            Text(
              _painLabels[selected - 1],
              style: TextStyle(
                color: _painColor(selected),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ],
      );
    });
  }

  Color _painColor(int level) {
    const colors = [
      Color(0xFF66BB6A), // 1 - เขียว
      Color(0xFFFFEB3B), // 2 - เหลือง
      Color(0xFFFF9800), // 3 - ส้ม
      Color(0xFFF44336), // 4 - แดง
      Color(0xFF880E4F), // 5 - แดงเข้มมาก
    ];
    return colors[level - 1];
  }
}

// ─── [ใหม่] Confidence Badge ──────────────────────────────────────────────────
class _ConfidenceBadge extends StatelessWidget {
  final String confidence;
  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final isHigh = confidence == 'high';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isHigh
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHigh ? const Color(0xFF66BB6A) : const Color(0xFFFF9800),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHigh ? Icons.verified : Icons.info_outline,
            size: 12,
            color: isHigh ? const Color(0xFF66BB6A) : const Color(0xFFFF9800),
          ),
          const SizedBox(width: 4),
          Text(
            isHigh ? "แม่นยำสูง" : "ข้อมูลน้อย",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isHigh ? const Color(0xFF388E3C) : const Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── [ใหม่] Menstrual Stats Card ─────────────────────────────────────────────
class _MenstrualStatsCard extends StatelessWidget {
  final ProfileController controller;
  const _MenstrualStatsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.statTotalCycles.value == 0) return const SizedBox();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "สถิติรอบเดือนของคุณ",
              style: GoogleFonts.mitr(
                textStyle: const TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatItem(
                  icon: Icons.loop,
                  value: "${controller.statTotalCycles.value}",
                  label: "รอบที่บันทึก",
                  color: const Color(0xFF4489D7),
                ),
                _StatDivider(),
                _StatItem(
                  icon: Icons.date_range,
                  value: controller.statAvgCycleLength.value > 0
                      ? "${controller.statAvgCycleLength.value} วัน"
                      : "-",
                  label: "รอบเฉลี่ย",
                  color: const Color(0xFFF05A42),
                ),
                _StatDivider(),
                _StatItem(
                  icon: Icons.water_drop,
                  value: controller.statAvgPeriodDuration.value > 0
                      ? "${controller.statAvgPeriodDuration.value} วัน"
                      : "-",
                  label: "ประจำเดือนเฉลี่ย",
                  color: const Color(0xFFFF9800),
                ),
              ],
            ),
            // อาการที่พบบ่อย
            if (controller.statCommonSymptoms.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFF0F0F0)),
              const SizedBox(height: 8),
              Text(
                "อาการที่พบบ่อย",
                style: GoogleFonts.mitr(
                  textStyle: const TextStyle(
                      color: Color(0xFF9E9E9E), fontSize: 12),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: controller.statCommonSymptoms.map((s) {
                  return Chip(
                    label: Text(s,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
                    backgroundColor: const Color(0xFFFFF8E1),
                    side: const BorderSide(color: Color(0xFFFFD348)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 50, color: const Color(0xFFF0F0F0));
  }
}
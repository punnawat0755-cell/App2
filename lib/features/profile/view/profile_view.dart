import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// ==========================================
// 1. Controller: จัดการข้อมูลแยกตาม ปี-เดือน-วัน
// ==========================================
class ProfileController extends GetxController {
  final supabase = Supabase.instance.client;

  var coins = 138.obs;
  var today = DateTime.now().day.obs;
  var selectedMonth = DateTime.now().month.obs;
  var selectedYear = DateTime.now().year.obs;
  var selectedDate = DateTime.now().day.obs; // ตั้งค่าเริ่มต้นให้เป็นวันนี้

  // State สำหรับโหลดข้อมูล
  var isLoading = false.obs;
  var predictionText = "".obs; // เก็บข้อความคาดการณ์รอบเดือน

  // ข้อมูลจาก Database
  var dailyPeriodStatus = <String, bool>{}.obs;
  var dailySymptoms = <String, List<String>>{}.obs;
  var dailyWhaleMoods = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // โหลดข้อมูลเมื่อเปิดหน้า
    loadMonthData();
    fetchPeriodPrediction();
  }

  // สร้าง Key ให้ตรงกับรูปแบบ Database (YYYY-MM-DD)
  String getDateKey(int year, int month, int day) {
    return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
  }

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
      selectedDate.value = 1; // รีเซ็ตไปวันที่ 1 ของเดือนนั้น
      loadMonthData(); // โหลดข้อมูลของเดือนใหม่
    }
  }

  // ==========================================
  // ดึงข้อมูลจาก Supabase
  // ==========================================
  Future<void> loadMonthData() async {
    try {
      isLoading.value = true;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      String startDate = getDateKey(selectedYear.value, selectedMonth.value, 1);
      String endDate = getDateKey(selectedYear.value, selectedMonth.value, daysInMonth);

      final response = await supabase
          .from('daily_mood_entries')
          .select()
          .eq('user_id', userId)
          .gte('window_start', '$startDate 00:00:00')
          .lte('window_start', '$endDate 23:59:59');

      // เคลียร์ข้อมูลเก่า
      dailyPeriodStatus.clear();
      dailySymptoms.clear();
      dailyWhaleMoods.clear();

      for (var row in response) {
        // แปลงวันที่จาก DB ให้เป็น DateKey
        DateTime date = DateTime.parse(row['window_start'].toString());
        String key = getDateKey(date.year, date.month, date.day);

        dailyPeriodStatus[key] = row['is_menstruating'] ?? false;
        
        // จัดการ Array ของ Symptoms
        if (row['symptoms'] != null) {
          dailySymptoms[key] = List<String>.from(row['symptoms']);
        }

        // เช็คอารมณ์วาฬจาก DB (สมมติถ้ามี mood_score)
        // int moodScore = row['mood_score'] ?? 50;
        // dailyWhaleMoods[key] = moodScore > 70 ? 'whale_love' : 'whale_happy';
      }
    } catch (e) {
      print("Error loading data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ==========================================
  // คาดการณ์รอบเดือนถัดไป (เรียกใช้ SQL Function)
  // ==========================================
  Future<void> fetchPeriodPrediction() async {
    try {
      final response = await supabase.rpc('predict_next_period');
      
      if (response != null && response is List && response.isNotEmpty) {
        var data = response[0];
        if (data['predicted_next_period'] != null) {
          DateTime predictedDate = DateTime.parse(data['predicted_next_period'].toString());
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
      }
    } catch (e) {
      print("Error predicting period: $e");
      predictionText.value = "บันทึกข้อมูลเพื่อคำนวณรอบเดือนถัดไป 🌸";
    }
  }

  // ==========================================
  // จัดการ State บนหน้าจอ
  // ==========================================
  bool getPeriodStatusForSelectedDay() => dailyPeriodStatus[dateKey] ?? false;
  List<String> getSymptomsForSelectedDay() => dailySymptoms[dateKey] ?? [];

  void setPeriodStatus(bool status) {
    if (selectedDate.value != 0) {
      dailyPeriodStatus[dateKey] = status;
      dailyPeriodStatus.refresh();
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

  // ==========================================
  // บันทึกข้อมูลลง Supabase
  // ==========================================
  Future<void> saveDailyData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      Get.snackbar("ข้อผิดพลาด", "กรุณาเข้าสู่ระบบก่อน", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    try {
      // สร้าง Timestamp ของวันที่เลือก (เช่น 2026-03-04 12:00:00)
      DateTime recordDate = DateTime(selectedYear.value, selectedMonth.value, selectedDate.value, 12, 0, 0);
      
      await supabase.from('daily_mood_entries').upsert({
        'user_id': userId,
        'window_start': recordDate.toIso8601String(),
        'is_menstruating': getPeriodStatusForSelectedDay(),
        'symptoms': getSymptomsForSelectedDay(),
      }, onConflict: 'user_id, window_start');

      Get.snackbar(
        "สำเร็จ",
        "บันทึกข้อมูลวันที่ ${selectedDate.value} เรียบร้อยแล้ว",
        backgroundColor: const Color(0xFF2C5282),
        colorText: Colors.white,
      );

      // รีเฟรชการคาดการณ์ใหม่ เผื่อผู้ใช้เพิ่งบันทึกวันแรกของรอบเดือน
      fetchPeriodPrediction();

      if (getPeriodStatusForSelectedDay()) {
        showAdviceModal();
      }
    } catch (e) {
      Get.snackbar("เกิดข้อผิดพลาด", "ไม่สามารถบันทึกข้อมูลได้: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // --- Modal คำแนะนำ ---
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
              _buildAdviceItem("- พักผ่อนและขยับกายเบาๆ: นอนหลับให้เพียงพอ และอาจโยคะหรือเดินเล่นเบาๆเพื่อช่วยให้ร่างกายหลั่งสารเอ็นดอร์ฟิน ลดความเครียด"),
              _buildAdviceItem("- รักษาความสะอาด: เปลี่ยนผ้าอนามัยทุก 3-4 ชั่วโมง เพื่อป้องกันความอับชื้นและการสะสมของเชื้อแบคทีเรีย"),
              _buildAdviceItem("- ดื่มน้ำอุ่นและเลี่ยงคาเฟอีน: น้ำอุ่นช่วยให้เลือดไหลเวียนดีขึ้น ส่วนการงดกาแฟหรือชาจะช่วยลดอาการคัดตึงหน้าอกและอาการหงุดหงิด"),
              _buildAdviceItem("- เลือกอาหารย่อยง่าย: เน้นทานผัก ผลไม้ และอาหารที่มีธาตุเหล็ก (เช่น ตับ ไข่แดง) เพื่อทดแทนเลือดที่เสียไป และเลี่ยงอาหารรสจัดที่ทำให้ท้องอืด"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CD9FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                ),
                child: const Text("ปิด", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
        textAlign: TextAlign.left,
        style: const TextStyle(color: Color(0xFF4489D7), fontSize: 13, height: 1.4),
      ),
    );
  }

  String getWhaleImage(int day) {
    String dateKey = getDateKey(selectedYear.value, selectedMonth.value, day);
    String? type = dailyWhaleMoods[dateKey];
    
    // สำหรับ Demo ถ้าระบุว่าเป็นประจำเดือน ให้หน้าน้องวาฬดูเหนื่อยๆ (cry)
    if (dailyPeriodStatus[dateKey] == true) return 'assets/images/whale_cry.png';
    if (type == 'whale_love') return 'assets/images/whale_love.png';
    
    return 'assets/images/whale_happy.png'; // ค่าเริ่มต้น
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
                          style: const TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.bold, fontSize: 16),
                        )),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage('https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg'),
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
                      textStyle: const TextStyle(color: Color(0xFF4489D7), fontSize: 22, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Obx(() => DropdownButton<String>(
                    value: controller.monthNames[controller.selectedMonth.value - 1],
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF757575)),
                    underline: const SizedBox(),
                    style: GoogleFonts.mitr(
                      textStyle: const TextStyle(color: Color(0xFF757575), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onChanged: (val) => controller.changeMonth(val),
                    items: controller.monthNames.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  )),
                ],
              ),
              const SizedBox(height: 10),

              // Banner แจ้งเตือน AI คำนวณรอบเดือน
              Obx(() {
                final prediction = controller.predictionText.value;
                if (prediction.isEmpty || prediction.contains('🌸')) {
                  return const SizedBox();
                }
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFF05A42)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          prediction,
                          style: const TextStyle(color: Color(0xFF5D4037), fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // 3. ปฏิทิน
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
                      children: ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"].map((day) => SizedBox(
                        width: 35,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF4489D7), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 10),
                    Obx(() {
                      if (controller.isLoading.value) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF4489D7))),
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.daysInMonth + controller.firstDayOffset,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7, childAspectRatio: 0.65, mainAxisSpacing: 5, crossAxisSpacing: 0,
                        ),
                        itemBuilder: (context, index) {
                          int day = index - controller.firstDayOffset + 1;
                          if (day < 1 || day > controller.daysInMonth) return const SizedBox();

                          return Obx(() {
                            String dayKey = controller.getDateKey(controller.selectedYear.value, controller.selectedMonth.value, day);
                            bool isSelected = controller.selectedDate.value == day;
                            bool isToday = controller.today.value == day && controller.selectedMonth.value == DateTime.now().month;
                            bool isPeriodDay = controller.dailyPeriodStatus[dayKey] ?? false;

                            Color bgColor = Colors.transparent;
                            Color textColor = const Color(0xFF4489D7);

                            if (isSelected) {
                              bgColor = const Color(0xFFFFD348); // สีเหลืองเมื่อจิ้ม
                            } else if (isPeriodDay) {
                              bgColor = const Color(0xFFF05A42); // สีแดงเมื่อบันทึกว่ามีรอบเดือน
                              textColor = Colors.white;
                            } else if (isToday) {
                              bgColor = const Color(0xFFCCCCCC);
                            }

                            return GestureDetector(
                              onTap: () => controller.selectedDate.value = day,
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                children: [
                                  Container(
                                    width: 36, height: 36, alignment: Alignment.center,
                                    decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                                    child: Text(
                                      "$day",
                                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Image.asset(
                                    controller.getWhaleImage(day),
                                    width: 32, height: 32, fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) => const SizedBox(height: 32),
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

              // 4. บันทึกอาการ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "บันทึกอาการ",
                    style: GoogleFonts.mitr(
                      textStyle: const TextStyle(color: Color(0xFF4489D7), fontSize: 22, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Obx(() => Text(
                    "วันที่ ${controller.selectedDate.value} ${controller.monthNames[controller.selectedMonth.value - 1]}",
                    style: const TextStyle(color: Color(0xFF757575), fontWeight: FontWeight.bold),
                  ))
                ],
              ),
              const SizedBox(height: 20),
              Obx(() {
                if (controller.selectedDate.value == 0) return const SizedBox(); // ซ่อนไว้ถ้าไม่ได้เลือกวัน
                
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatusButton(controller, "เป็นประจำเดือน", const Color(0xFFF05A42), Colors.white, true),
                        const SizedBox(width: 15),
                        _buildStatusButton(controller, "ไม่เป็นประจำเดือน", const Color(0xFFA6E3F9), const Color(0xFF424242), false),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Wrap(
                      spacing: 15, runSpacing: 20, alignment: WrapAlignment.center,
                      children: controller.symptomsList.map((item) {
                        bool isSelected = controller.getSymptomsForSelectedDay().contains(item['name']);
                        return GestureDetector(
                          onTap: () => controller.toggleSymptom(item['name']!),
                          child: Column(
                            children: [
                              Container(
                                width: 70, height: 70, padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFA6E3F9) : const Color(0xFFFFDA7B).withAlpha(204),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: isSelected ? const Color(0xFF4489D7) : Colors.black12, width: 1.5),
                                ),
                                child: Image.asset(item['img']!, fit: BoxFit.contain),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['name']!,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF5D4037), fontWeight: FontWeight.w600),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)
                        ),
                        child: const Text("บันทึกข้อมูล", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildStatusButton(ProfileController controller, String title, Color activeColor, Color activeTextColor, bool isPeriodTab) {
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
            border: Border.all(color: isSelected ? activeColor : const Color(0xFF757575), width: 1.5),
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

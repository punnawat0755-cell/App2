import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/feed/view/post.dart';
import 'package:flutter_application_1/module/home/view/playvideo.dart';
import 'package:flutter_application_1/module/home/view/test_view.dart';
import 'package:flutter_application_1/module/home/view/widget/home_widgets.dart';
import 'package:flutter_application_1/module/home/view/widget/article/article_card.dart';
import 'package:flutter_application_1/module/home/view/widget/article/article_detail.dart';
import 'package:flutter_application_1/module/setting/view/setting_view.dart';
import 'package:flutter_application_1/module/user_Profile/widget/app_profile_avatar.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 💡 นำเข้า SharedPreferences

// ==========================================
// 💡 1. HomeController
// ==========================================
class HomeController extends GetxController {
  final RxInt currentBannerIndex = 0.obs;
  late final PageController pageController;
  Timer? timer;

  final ImagePicker _picker = ImagePicker();
  final RxString selectedVideoPath = ''.obs;

  final RxList<Map<String, dynamic>> clipList = <Map<String, dynamic>>[
    {
      "title": "Jellyfish",
      "subtitle": "2 week",
      "imagePath":
          "https://i.pinimg.com/1200x/10/fd/6c/10fd6c2086373b9007700b8f997545f1.jpg",
      "page": () => Null,
    },
    {
      "title": "starfish",
      "subtitle": "1 week",
      "imagePath":
          "https://i.pinimg.com/736x/e0/e4/4d/e0e44d1c32bf9b484430e4cb74bf2719.jpg",
      "page": () => PlayVideoFromNetwork(),
    },
    {
      "title": "whale",
      "subtitle": "1 day",
      "imagePath":
          "https://i.pinimg.com/1200x/2a/92/db/2a92db9b4048574f9b24f57108d3a2ef.jpg",
      "page": null,
    },
    {
      "title": "whale",
      "subtitle": "1 day",
      "imagePath":
          "https://i.pinimg.com/1200x/2a/92/db/2a92db9b4048574f9b24f57108d3a2ef.jpg",
      "page": null,
    },
  ].obs;

  bool hasShownPeriodPanel = false;
  final TextEditingController periodRangeController = TextEditingController();

  // 💡 ฟังก์ชันเช็คว่าควรโชว์ Popup ไหม (เช็คว่าครบ 4 ชม. หรือยัง)
  Future<bool> shouldShowPeriodPanel() async {
    final prefs = await SharedPreferences.getInstance();
    final String? nextShowTimeStr = prefs.getString('next_period_prompt_time');

    if (nextShowTimeStr != null) {
      final DateTime nextShowTime = DateTime.parse(nextShowTimeStr);
      if (DateTime.now().isBefore(nextShowTime)) {
        return false; // ยังไม่ถึงเวลา 4 ชม. ไม่ต้องโชว์
      }
    }
    return true; // ถึงเวลาแล้ว ให้โชว์ได้
  }

  // 💡 ฟังก์ชันแอบตั้งเวลาไปอีก 4 ชม. (ทำงานเงียบๆ เบื้องหลัง)
  Future<void> setNextPromptIn4Hours() async {
    final prefs = await SharedPreferences.getInstance();
    final DateTime nextTime = DateTime.now().add(
      const Duration(hours: 4),
    ); // 💡 เปลี่ยน hours: 4 ตรงนี้ถ้าอยากเทสเวลาอื่น
    await prefs.setString(
      'next_period_prompt_time',
      nextTime.toIso8601String(),
    );
  }

  void addNewClip(String videoPath, String caption) {
    clipList.insert(0, {
      "title": "seal",
      "subtitle": "Just now",
      "imagePath": videoPath,
      "videoPath": videoPath,
      "caption": caption,
    });
  }

  Future<void> pickMedia() async {
    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file != null) {
        selectedVideoPath.value = file.path;
        showPostSheet(
          mediaFile: file,
          isVideo: true,
          mode: PostComposerMode.homeVideoOnly,
        );
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการดึงไฟล์: $e");
    }
  }

  final List<Map<String, dynamic>> articleList = [
    {
      "title": 'วาฬ 52Hz\nไม่ได้อยู่คนเดียว',
      "subtitle": '1 Month Ago',
      "imagePath": 'assets/images/52Hz.png',
      "detailImage": 'assets/images/article1.png',
      "content": "เคยถูกใช้เป็นภาพสะท้อนความเหงา...",
    },
    {
      "title": 'อยู่คนเดียวก็มีความ\nสุขดีนะ',
      "subtitle": '3 Month Ago',
      "imagePath": 'assets/images/alon.png',
      "detailImage": 'assets/images/alon.png',
      "content": "การอยู่คนเดียวไม่ได้หมายความว่าต้องเหงาเสมอไป...",
    },
    {
      "title": 'วิธีฮีลใจ\nในวันที่อ่อนล้า',
      "subtitle": '3 Month Ago',
      "imagePath": 'assets/images/alon.png',
      "detailImage": 'assets/images/alon.png',
      "content": "ลองหาเวลาพักผ่อนและทำสิ่งที่ชอบดูสิ...",
    },
  ];

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
    timer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
      if (currentBannerIndex.value < 2) {
        currentBannerIndex.value++;
      } else {
        currentBannerIndex.value = 0;
      }
      if (pageController.hasClients) {
        pageController.animateToPage(
          currentBannerIndex.value,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void onClose() {
    timer?.cancel();
    pageController.dispose();
    periodRangeController.dispose();
    super.onClose();
  }
}

// ==========================================
// 💡 2. HomePage
// ==========================================
class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController controller = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController());

  void _showPeriodPanel() {
    DateTime? selectedStart;
    DateTime? selectedEnd;
    bool isSaved = false; // ตัวแปรเช็คว่าผู้ใช้กดปุ่มบันทึกหรือยัง

    Get.bottomSheet(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateSheet) {
          return Container(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: 30,
              top: 10,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- ขีดสีเทาด้านบน ---
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // --- ข้อความหัวข้อ ---
                const Text(
                  'คุณยังไม่ได้ใส่ประจำเดือนนะ คุณต้องการที่จะใส่ไหม',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8E8E8E),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),

                // --- ส่วนเลือกวันที่ ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 💡 ปุ่มเลือกวันเริ่ม
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedStart ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateSheet(() => selectedStart = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5), // สีเทาอ่อน
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selectedStart != null
                                ? DateFormat('dd/MM/yy').format(selectedStart!)
                                : 'วันที่เริ่ม',
                            style: TextStyle(
                              color: selectedStart != null
                                  ? const Color(0xFF6A6A6A)
                                  : const Color(0xFFB0B0B0),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // เครื่องหมายลบตรงกลาง
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        "-",
                        style: TextStyle(
                          color: Color(0xFF5CC0FF), // สีฟ้า
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // 💡 ปุ่มเลือกวันจบ
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                selectedEnd ?? selectedStart ?? DateTime.now(),
                            firstDate:
                                selectedStart ??
                                DateTime(2000), // วันจบต้องไม่ก่อนวันเริ่ม
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateSheet(() => selectedEnd = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selectedEnd != null
                                ? DateFormat('dd/MM/yy').format(selectedEnd!)
                                : 'วันที่สิ้นสุด',
                            style: TextStyle(
                              color: selectedEnd != null
                                  ? const Color(0xFF6A6A6A)
                                  : const Color(0xFFB0B0B0),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // --- ปุ่มบันทึก ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedStart != null && selectedEnd != null) {
                        // เซฟเข้า Controller
                        final String start = DateFormat(
                          'dd/MM/yy',
                        ).format(selectedStart!);
                        final String end = DateFormat(
                          'dd/MM/yy',
                        ).format(selectedEnd!);
                        controller.periodRangeController.text = '$start - $end';

                        isSaved =
                            true; // 💡 กำหนดสถานะว่าบันทึกแล้ว จะได้ไม่ไปรันตอน whenComplete
                        Get.back(); // ปิด Panel
                      } else {
                        Get.snackbar(
                          "แจ้งเตือน",
                          "กรุณาเลือกทั้งวันเริ่มต้นและวันสิ้นสุด",
                          backgroundColor: const Color(0xFF5CC0FF),
                          colorText: Colors.white,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF5CC0FF,
                      ), // สีฟ้าตามดีไซน์
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'บันทึก',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // ให้ Container โชว์ขอบมนได้
    ).whenComplete(() {
      // 💡 โค้ดส่วนนี้จะทำงานเมื่อ Popup หายไป
      if (!isSaved) {
        // ถ้าผู้ใช้ปัดทิ้ง โดยยังไม่ได้กดบันทึก ให้ตั้งเวลา 4 ชม. อัตโนมัติ
        controller.setNextPromptIn4Hours();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const name = 'Seal';

    // 💡 เช็คเวลาก่อนโชว์ Popup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!controller.hasShownPeriodPanel) {
        bool shouldShow = await controller.shouldShowPeriodPanel();
        if (shouldShow) {
          controller.hasShownPeriodPanel = true;
          _showPeriodPanel();
        } else {
          // ถ้ายังไม่ถึงเวลา ก็ตั้ง flag เป็น true ไว้เลยจะได้ไม่เช็คซ้ำในการเรนเดอร์ครั้งนี้
          controller.hasShownPeriodPanel = true;
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Get.to(() => const SettingPage()),
                        child: const AppProfileAvatar(
                          radius: 25,
                          showNotificationDot: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'สวัสดี, $name',
                style: TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),

              // --- Banner Section ---
              SizedBox(
                height: 160,
                child: PageView(
                  controller: controller.pageController,
                  onPageChanged: (index) =>
                      controller.currentBannerIndex.value = index,
                  children: const [
                    DailyMissionBanner(),
                    ClownFishBanner(),
                    LoveJobBanner(),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: controller.currentBannerIndex.value == index
                          ? 24
                          : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: controller.currentBannerIndex.value == index
                            ? const Color(0xFF4489D7)
                            : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const HomeSectionHeader(title: 'คลิปสั้น'),
              const SizedBox(height: 15),

              // --- ส่วนแสดงคลิปสั้น ---
              SizedBox(
                height: 160,
                child: Obx(
                  () => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.zero,
                    itemCount: controller.clipList.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 15),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return GestureDetector(
                          onTap: () {
                            controller.pickMedia();
                          },
                          child: Container(
                            width: 110,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E2E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Container(
                                width: 45,
                                height: 45,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Color(0xFF8A8A8A),
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final item = controller.clipList[index - 1];
                      return InkWell(
                        onTap: () {
                          final String? videoPath = item['videoPath'];
                          if (videoPath != null && videoPath.isNotEmpty) {
                            Get.to(
                              () => PlayVideo(
                                videoPath: videoPath,
                                uploaderName: item['title'] ?? 'Unknown',
                                caption: item['caption'] ?? '',
                              ),
                            );
                            return;
                          }

                          final page = item['page'];
                          if (page != null) Get.to(page);
                        },
                        child: ClipCard(
                          title: item['title'],
                          subtitle: item['subtitle'],
                          imagePath: item['imagePath'],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 25),
              const HomeSectionHeader(title: 'บทความจิตวิทยา'),
              const SizedBox(height: 15),

              // --- ส่วนแสดงบทความ ---
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.zero,
                  itemCount: controller.articleList.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 15),
                  itemBuilder: (context, index) {
                    final article = controller.articleList[index];
                    return SizedBox(
                      width: 160,
                      child: ArticleCard(
                        title: article['title'],
                        subtitle: article['subtitle'],
                        imagePath: article['imagePath'],
                        onTap: () => Get.to(
                          () => ArticleDetailPage(
                            title: article['title'].replaceAll('\n', ' '),
                            imagePath: article['detailImage'],
                            content: article['content'],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

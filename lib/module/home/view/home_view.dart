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

// ==========================================
// 💡 1. HomeController
// ==========================================
class HomeController extends GetxController {
  final RxInt currentBannerIndex = 0.obs;
  late final PageController pageController;
  Timer? timer;

  final ImagePicker _picker = ImagePicker();
  final RxString selectedVideoPath = ''.obs;

  // 💡 2. เปลี่ยน clipList เป็น RxList (.obs) เพื่อให้ UI อัปเดตอัตโนมัติเวลาลงคลิปใหม่
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

  // 💡 Panel กรอกประจำเดือน (แสดงครั้งเดียวเมื่อเข้า Home)
  bool hasShownPeriodPanel = false;
  final TextEditingController periodRangeController = TextEditingController();

  // 💡 3. เพิ่มฟังก์ชัน addNewClip เพื่อให้หน้า Post เรียกใช้งาน (เส้นแดงในหน้า post.dart จะหายไป)
  void addNewClip(String videoPath, String caption) {
    clipList.insert(0, {
      "title": "seal",
      "subtitle": "Just now",
      // ใช้ path วิดีโอจริงเป็น thumbnail (ดึงเฟรมแรกจากไฟล์)
      "imagePath": videoPath,
      "videoPath": videoPath,
      "caption": caption,
    });
  }

  // 💡 4. แก้ไข pickMedia ให้เด้งไปหน้า Post
  Future<void> pickMedia() async {
    try {
      // โพสต์จากหน้า Home รองรับเฉพาะวิดีโอ
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);

      if (file != null) {
        selectedVideoPath.value = file.path;

        print("เลือกไฟล์สำเร็จ! ไปหน้าโพสต์...");

        // เปิดหน้า Post แบบ BottomSheet ให้ UI เหมือนกันทุกจุด
        showPostSheet(
          mediaFile: file,
          isVideo: true,
          mode: PostComposerMode.homeVideoOnly,
        );
      } else {
        print("ผู้ใช้ยกเลิกการเลือก");
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
      "content": "เคยถูกใช้เป็นภาพสะท้อนความเหงา... (เนื้อหายาว)",
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
    Get.bottomSheet(
      ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 16),
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Text(
                    'คุณยังไม่ได้ใส่ประจำเดือน- คุณต้องการที่จะใส่ไหม',
                    style: TextStyle(
                      color: Color(0xFF8E8E8E),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      controller: controller.periodRangeController,
                      readOnly: true,
                      style: const TextStyle(
                        color: Color(0xFF6A6A6A),
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'dd/mm/yy-dd/mm/yy',
                        hintStyle: TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 18,
                        ),
                        suffixIcon: Image.asset(
                          "assets/images/calendar.png",
                          width: 10,
                          height: 10,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF20C2FF),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    const name = 'Seal';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasShownPeriodPanel) {
        controller.hasShownPeriodPanel = true;
        _showPeriodPanel();
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
              Text(
                'สวัสดี,$name',
                style: const TextStyle(
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
                  children: [
                    const DailyMissionBanner(),
                    const ClownFishBanner(),
                    const LoveJobBanner(),
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

              // --- 💡 ส่วนแสดงคลิปสั้น ---
              SizedBox(
                height: 160,
                // 💡 5. ใช้ Obx ครอบ ListView เพื่อให้เวลาเพิ่มคลิปใหม่ UI จะรีเฟรชเอง
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
                            controller
                                .pickMedia(); // เรียกฟังก์ชันเปิดแกลเลอรี่
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

              // --- 💡 ส่วนแสดงบทความ ---
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

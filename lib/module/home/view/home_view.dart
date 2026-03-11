import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/home/view/test_view.dart';
import 'package:flutter_application_1/module/home/view/widget/home_widgets.dart';
import 'package:flutter_application_1/module/home/view/widget/article/article_card.dart';
import 'package:flutter_application_1/module/home/view/widget/article/article_detail.dart';
import 'package:flutter_application_1/module/setting/view/setting_view.dart';
import 'package:get/get.dart';

// ==========================================
// 💡 1. HomeController (เพิ่มระบบแจ้งเตือน)
// ==========================================
class HomeController extends GetxController {
  final RxInt currentBannerIndex = 0.obs;
  late final PageController pageController;
  Timer? timer;

  // 🔔 เพิ่มตัวแปรเช็คสถานะแจ้งเตือน (ใช้ .obs เพื่อให้ UI อัปเดตอัตโนมัติ)
  var hasNewNotification = true.obs;

  final List<Map<String, dynamic>> clipList = [
    {
      "title": "Jellyfish",
      "subtitle": "2 week",
      "imagePath":
          "https://i.pinimg.com/1200x/10/fd/6c/10fd6c2086373b9007700b8f997545f1.jpg",
      "page": () => VideoApp(),
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
    {
      "title": "whale",
      "subtitle": "1 day",
      "imagePath":
          "https://i.pinimg.com/1200x/2a/92/db/2a92db9b4048574f9b24f57108d3a2ef.jpg",
      "page": null,
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
    super.onClose();
  }
}

// ==========================================
// 💡 2. HomePage (เพิ่ม Stack และ Obx ที่รูปโปรไฟล์)
// ==========================================
class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController controller = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    const name = 'Seal';
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
                      Obx(
                        () => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => Get.to(
                                () => const SettingPage(),
                              ), // ไปหน้าเมนู (ภาพที่ 2)
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  image: const DecorationImage(
                                    image: NetworkImage(
                                      'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // 🔴 จุดสีแดงแสดงเมื่อมีข้อความใหม่
                            if (controller.hasNewNotification.value)
                              Positioned(
                                top: -4,
                                right: -5,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEE6855,
                                    ), // สีแดงส้มตามรูป
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: controller.clipList.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 5),
                  itemBuilder: (context, index) {
                    final item = controller.clipList[index];
                    return InkWell(
                      onTap: () =>
                          item['page'] != null ? Get.to(item['page']) : null,
                      child: ClipCard(
                        title: item['title'],
                        subtitle: item['subtitle'],
                        imagePath: item['imagePath'],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),
              const HomeSectionHeader(title: 'บทความจิตวิทยา'),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ArticleCard(
                      title: 'วาฬ 52Hz\nไม่ได้อยู่คนเดียว',
                      subtitle: '1 Month Ago',
                      imagePath: 'assets/images/52Hz.png',
                      onTap: () => Get.to(
                        () => const ArticleDetailPage(
                          title: 'วาฬ 52Hz ไม่ได้อยู่คนเดียว',
                          imagePath: 'assets/images/article1.png',
                          content:
                              "เคยถูกใช้เป็นภาพสะท้อนความเหงา... (เนื้อหายาว)",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ArticleCard(
                      title: 'อยู่คนเดียวก็มีความ\nสุขดีนะ',
                      subtitle: '3 Month Ago',
                      imagePath: 'assets/images/alon.png',
                      onTap: () => Get.to(
                        () => const ArticleDetailPage(
                          title: 'อยู่คนเดียวก็มีความสุขดีนะ',
                          imagePath: 'assets/images/alon.png',
                          content:
                              "การอยู่คนเดียวไม่ได้หมายความว่าต้องเหงาเสมอไป...",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

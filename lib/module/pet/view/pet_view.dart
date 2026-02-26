import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/shop/view/shop_view.dart';
import 'package:get/get.dart';

// ==========================================
// 1. Class Pet (Logic Controller) - แก้ไขแล้ว
// ==========================================
class Pet extends GetxController {
  var ownedItems = <int>[].obs;

  // --- ตัวแปรทั่วไป ---
  var coins = 833.obs;
  var level = 1.obs;
  var energyPercent = 50.obs; // ค่าพลังงานเริ่มต้น
  var username = "Seal".obs;

  // --- ตัวแปรระบบอาหาร (ปลาซ้าย) ---
  var foodCount = 3.obs;
  var remainingTime = "00:00:00".obs;
  var isTimerRunning = false.obs;
  Timer? _timer;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // -----------------------------------------------------------------------
  // ฟังก์ชัน 1: ปลาซ้าย (ใช้จำนวนตัว / ฟรี / รอเวลา)
  // -----------------------------------------------------------------------
  void feedPet() {
    // 1. เช็คว่ามีของไหม
    if (foodCount.value <= 0) {
      Get.snackbar(
        "อาหารหมด!",
        "ต้องรอเวลาให้ปลาว่ายมาเติมก่อนนะ (เหลือเวลา ${remainingTime.value})",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
      return;
    }

    // 2. หักจำนวนปลา
    foodCount.value--;

    // ---------------------------------------------------
    // [เพิ่มใหม่] เพิ่มพลังงาน 5%
    // ---------------------------------------------------
    energyPercent.value += 5;
    if (energyPercent.value > 100) {
      energyPercent.value = 100; // ตันที่ 100
    }
    // ---------------------------------------------------

    Get.snackbar(
      "งั่มๆ!",
      "น้องกินปลาเล็กแล้ว (+5 Energy)",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(10),
    );

    // 3. เริ่มจับเวลาถ้าของหมด
    if (foodCount.value == 0) {
      _startTimer(6 * 60 * 60);
    }
  }

  // -----------------------------------------------------------------------
  // ฟังก์ชัน 2: ปลาตัวกลาง (ใช้เหรียญ)
  // -----------------------------------------------------------------------
  void feedWithCoin(int cost) {
    if (coins.value >= cost) {
      // หักเหรียญ
      coins.value -= cost;

      // ---------------------------------------------------
      // [แก้ตรงนี้] เปลี่ยนจาก 5 เป็น 10
      // ---------------------------------------------------
      energyPercent.value += 10; // <--- เพิ่มทีละ 10%

      if (energyPercent.value > 100) {
        energyPercent.value = 100; // ตันที่ 100 เหมือนเดิม
      }
      // ---------------------------------------------------

      Get.snackbar(
        "อร่อยจัง!",
        "เปย์น้องด้วยปลาใหญ่! (+10 Energy)", // อย่าลืมแก้ข้อความตรงนี้ด้วยนะครับ
        backgroundColor: Colors.amber,
        colorText: Colors.black,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(milliseconds: 800),
        margin: const EdgeInsets.all(10),
      );
    } else {
      Get.snackbar(
        "เหรียญไม่พอ",
        "ต้องใช้ $cost coins เพื่อให้อาหารนี้นะ",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
    }
  }

  // --- Logic การนับเวลา ---
  void _startTimer(int seconds) {
    _timer?.cancel();
    isTimerRunning.value = true;

    var duration = Duration(seconds: seconds);
    remainingTime.value = _printDuration(duration);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (duration.inSeconds > 0) {
        duration = duration - const Duration(seconds: 1);
        remainingTime.value = _printDuration(duration);
      } else {
        timer.cancel();
        isTimerRunning.value = false;

        foodCount.value++;
        remainingTime.value = "00:00:00";

        Get.snackbar(
          "ปลามาแล้ว!",
          "ได้รับปลาฟรี 1 ตัวจากการรอ",
          backgroundColor: Colors.blueAccent,
          colorText: Colors.white,
        );
      }
    });
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

// ==========================================
// 2. ส่วนหน้าจอ (UI View)
// ==========================================
class PetPage extends StatelessWidget {
  const PetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Pet controller = Get.put(Pet());

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backpet.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(controller),
                const Spacer(),
                const Spacer(),
                _buildBottomDock(controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // Widget: Top Bar
  // -----------------------------------------------------------
  Widget _buildTopBar(Pet controller) {
    const double boxHeight = 39.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 0),
      child: Column(
        children: [
          // Row 1: Back + Name
          // Row(
          //   children: [
          //     // InkWell(
          //     //   onTap: () => Get.back(),
          //     //   child: Image.asset(
          //     //     'assets/images/back2.png',
          //     //     width: 36,
          //     //     height: 28,
          //     //     fit: BoxFit.contain,
          //     //   ),
          //     // ),
          //     const SizedBox(width: 10),
          //     Obx(
          //       () => Text(
          //         "สวัสดี,${controller.username}",
          //         style: const TextStyle(
          //           color: Colors.white,
          //           fontSize: 24,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 20),

          // Row 2: Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Coin
              Container(
                height: boxHeight,
                padding: const EdgeInsets.fromLTRB(5, 0, 15, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/coin.png',
                      width: 35,
                      height: 35,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 9),
                    Obx(
                      () => Text(
                        "${controller.coins}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              // Level & Energy
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "เลเวล 1",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 160,
                    height: boxHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(
                            15.0,
                            8.0,
                            9.0,
                            8.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE5B9),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Obx(() {
                            double maxW = 160.0, left = 15.0, right = 9.0;
                            double currentW = (maxW - left - right) *
                                (controller.energyPercent.value / 100);
                            return Container(
                              width: currentW,
                              height: double.infinity,
                              margin: EdgeInsets.fromLTRB(left, 8.0, 0.0, 8.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD146),
                                borderRadius: BorderRadius.circular(30),
                              ),
                            );
                          }),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 1),
                            child: Image.asset(
                              'assets/images/t1.png',
                              width: 34,
                              height: 34,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Obx(
                            () => Text(
                              " ${controller.energyPercent.value} %",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF634917),
                                fontSize: 16,
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
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // Widget: Bottom Dock
  // -----------------------------------------------------------
  Widget _buildBottomDock(Pet controller) {
    return Container(
      padding: const EdgeInsets.only(bottom: 30, left: 10, right: 10),
      height: 170,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. ปุ่มซ้าย (Fish 1 - ใช้จำนวนตัว)
          Obx(() {
            bool isOutOfFood = controller.foodCount.value == 0;

            return _buildItemCard(
              imagePath: 'assets/images/fish1.png',
              customImageSize: 90,
              customImageBottom: 10,
              labelWidget: Text(
                isOutOfFood ? controller.remainingTime.value : "00:00:00",
                style: TextStyle(
                  color: isOutOfFood ? Colors.grey : const Color(0xFF1565C0),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              badgeCount: controller.foodCount.value,
              onTap: () => controller.feedPet(),
            );
          }),

          // 2. ปุ่มกลาง (Fish 2 - ใช้เหรียญ)
          _buildItemCard(
            imagePath: 'assets/images/fish2.png',
            customImageSize: 100,
            isBig: true,
            customImageBottom: -9,
            topBadgeWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: const Color(0xFFFFC107),
                    child: Image.asset(
                      'assets/images/coin2.png',
                      width: 16,
                      height: 16,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "2 coin",
                    style: TextStyle(
                      color: Color(0xFFFFC107),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // [แก้ไข] เรียกใช้ feedWithCoin(2) แทน buyFood
            onTap: () => controller.feedWithCoin(2),
          ),

          // 3. ปุ่มขวา (Shop)
          _buildItemCard(
            imagePath: 'assets/images/shop.png',
            customImageSize: 80,
            customImageBottom: 5,
            topBadgeWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "SHOP",
                style: TextStyle(
                  color: Color(0xFFFFC107),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            onTap: () => Get.to(() => const ShopPage()),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // Widget: Item Card Structure
  // -----------------------------------------------------------
  Widget _buildItemCard({
    required String imagePath,
    required VoidCallback onTap,
    Widget? labelWidget,
    Widget? topBadgeWidget,
    int badgeCount = 0,
    double? customImageSize,
    double? customImageBottom,
    bool isBig = false,
  }) {
    final double cardWidth = 100;
    final double cardHeight = 100;
    final double imageSize = customImageSize ?? 80;
    final double imageBottom = customImageBottom ?? 10;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight + 40,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (labelWidget != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: labelWidget,
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: imageBottom,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  imagePath,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.error, size: imageSize),
                ),
              ),
            ),
            if (topBadgeWidget != null)
              Positioned(
                top: 25,
                left: 0,
                right: 0,
                child: Center(child: topBadgeWidget),
              ),
            if (badgeCount > 0)
              Positioned(
                top: 23,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$badgeCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

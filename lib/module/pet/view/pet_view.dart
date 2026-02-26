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
  var showFrame = false.obs;

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

  void toggleFrame() {
    showFrame.value = !showFrame.value;
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
      energyPercent.value = 100;
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
      energyPercent.value += 10; // <--- เพิ่มทีละ 10%

      if (energyPercent.value > 100) {
        energyPercent.value = 100; // ตันที่ 100 เหมือนเดิม
      }
      // ---------------------------------------------------

      Get.snackbar(
        "อร่อยจัง!",
        "เปย์น้องด้วยปลาใหญ่! (+10 Energy)",
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
          Obx(
            () => controller.showFrame.value
                ? _buildPhotoOverlay(controller)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // Widget: Photo Overlay (กรอบรูปโพลารอยด์)
  // -----------------------------------------------------------
  Widget _buildPhotoOverlay(Pet controller) {
    return Container(
      color: Colors.black.withOpacity(0.5), // ทำพื้นหลังมืดจางๆ
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. ตัวกรอบโพลารอยด์สีขาว (เฉพาะรูปภาพ)
            Container(
              height: 380,
              width: 380,
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [],
              ),
              child: AspectRatio(
                aspectRatio: 1.4, // ปรับรูปให้เป็นแนวนอนเป๊ะๆ
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ), // ขอบขาวซ้อนในรูป
                  ),
                  child: Image.asset(
                    'assets/images/backpet.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30), // ระยะห่างระหว่างกรอบรูปกับปุ่มด้านล่าง
            // 2. แถวของปุ่มกดด้านล่าง (ปุ่มโปรไฟล์ + ปุ่มปิด)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- ปุ่มใช้เป็นรูปโปรไฟล์ ---
                GestureDetector(
                  onTap: () {
                    print("Go to Profile Setup");
                    // controller.toggleFrame(); // ปิดกรอบหลังจากกด
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFD9D9D9), // สีขาวนวลตามรูป
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      "ใช้เป็นรูปโปรไฟล์",
                      style: TextStyle(color: Color(0xFF6C6C6C), fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                // --- ปุ่มกากบาท (X) ---
                GestureDetector(
                  onTap: () => controller.toggleFrame(),
                  child: Container(
                    width: 55,
                    height: 55,
                    decoration: const BoxDecoration(
                      color: Colors.white, // พื้นหลังสีขาว
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        "X",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // Widget: Top Bar
  // -----------------------------------------------------------
  Widget _buildTopBar(Pet controller) {
    const double boxHeight = 39.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        10,
        10,
        10,
        0,
      ), // ปรับ padding ขวาเล็กน้อย
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Row: Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 1. ส่วนแสดง Coin
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

              // 2. ส่วนแสดง Level, Energy Bar และปุ่มกล้อง
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
                  Row(
                    // ใช้ Row เพื่อวางหลอดพลังงานและปุ่มกล้องข้างกัน
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // หลอดพลังงาน (Energy Bar)
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
                                double currentW =
                                    (maxW - left - right) *
                                    (controller.energyPercent.value / 100);
                                return Container(
                                  width: currentW,
                                  height: double.infinity,
                                  margin: EdgeInsets.fromLTRB(
                                    left,
                                    8.0,
                                    0.0,
                                    8.0,
                                  ),
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
                      const SizedBox(
                        width: 10,
                      ), // เว้นระยะห่างระหว่างหลอดกับปุ่มกล้อง
                      // ปุ่มกล้อง (Camera Button)
                      GestureDetector(
                        onTap: () {
                          // ใส่ Action สำหรับการถ่ายรูปตรงนี้
                          controller.toggleFrame();
                        },
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              0.8,
                            ), // ขาวขุ่นตามรูป
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/camera.png',
                            width: 28,
                            height: 28,
                          ),
                        ),
                      ),
                    ],
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
                    color: Colors.black.withOpacity(0.15),
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

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_application_1/core/services/coin_service.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/features/shop/view/shop_view.dart';

// ==========================================
// 1. Class Pet (Logic Controller) - แก้ไขแล้ว
// ==========================================
class Pet extends GetxController {
  late final CoinService _coinService;
  var ownedItems = <int>[].obs;

  // --- ตัวแปรทั่วไป ---
  RxInt get coins => _coinService.coins;
  var level = 1.obs;
  var energyPercent = 50.obs; // ค่าพลังงานเริ่มต้น
  var username = "Seal".obs;

  // --- ตัวแปรระบบอาหาร (ปลาซ้าย) ---
  var foodCount = 3.obs;
  var remainingTime = "00:00:00".obs;
  var isTimerRunning = false.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _coinService = Get.isRegistered<CoinService>()
        ? Get.find<CoinService>()
        : Get.put(CoinService(), permanent: true);
  }

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
  Future<void> feedWithCoin(int cost) async {
    final didSpend = await _coinService.spendCoins(cost);
    if (didSpend) {
      // หักเหรียญ

      energyPercent.value += 10;

      if (energyPercent.value > 100) {
        energyPercent.value = 100; // ตันที่ 100 เหมือนเดิม
      }

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

  Future<bool> spendCoins(int cost) => _coinService.spendCoins(cost);

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
class PetPage extends StatefulWidget {
  const PetPage({super.key});

  @override
  State<PetPage> createState() => _PetPageState();
}

class _PetPageState extends State<PetPage> {
  late final Pet controller;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<Pet>() ? Get.find<Pet>() : Get.put(Pet());
    _audioPlayer = AudioPlayer();
    unawaited(_startLoopSound());
  }

  Future<void> _startLoopSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('Sound/howareyou.mp3'));
    } catch (e) {
      debugPrint('Failed to play looping pet sound: $e');
    }
  }

  @override
  void dispose() {
    unawaited(_audioPlayer.stop());
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final scale = ResponsiveScale.fromWidth(screenWidth);
                return Column(
                  children: [
                    _buildTopBar(controller, screenWidth, scale),
                    const Spacer(),
                    const Spacer(),
                    _buildBottomDock(controller, screenWidth, scale),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // Widget: Top Bar
  // -----------------------------------------------------------
  Widget _buildTopBar(
    Pet controller,
    double screenWidth,
    ResponsiveScale scale,
  ) {
    final isCompact = screenWidth < 360;
    final energyBarWidth =
        isCompact ? (screenWidth * 0.43).clamp(136.0, 160.0) : 160.0;
    final boxHeight = scale.rs(39, min: 33, max: 39);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        scale.rs(10, min: 8, max: 10),
        scale.rs(20, min: 14, max: 20),
        scale.rs(20, min: 14, max: 20),
        0,
      ),
      child: Column(
        children: [
          SizedBox(height: scale.rs(20, min: 14, max: 20)),

          // Row 2: Stats
          Wrap(
            alignment: WrapAlignment.center,
            spacing: isCompact
                ? scale.rs(10, min: 8, max: 10)
                : scale.rs(15, min: 10, max: 15),
            runSpacing: scale.rs(8, min: 6, max: 8),
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              // Coin
              Container(
                height: boxHeight,
                padding: EdgeInsets.fromLTRB(
                  scale.rs(5, min: 4, max: 5),
                  0,
                  scale.rs(15, min: 10, max: 15),
                  0,
                ),
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
                      width: scale.rs(35, min: 28, max: 35),
                      height: scale.rs(35, min: 28, max: 35),
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: scale.rs(9, min: 6, max: 9)),
                    Obx(
                      () => Text(
                        "${controller.coins}",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: scale.rf(18, min: 15, max: 18),
                          color: const Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Level & Energy
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "เลเวล 1",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: scale.rf(18, min: 15, max: 18),
                    ),
                  ),
                  SizedBox(height: scale.rs(5, min: 3, max: 5)),
                  Container(
                    width: energyBarWidth,
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
                            final maxW = energyBarWidth;
                            const left = 15.0;
                            const right = 9.0;
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
                              width: scale.rs(34, min: 27, max: 34),
                              height: scale.rs(34, min: 27, max: 34),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Obx(
                            () => Text(
                              " ${controller.energyPercent.value} %",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF634917),
                                fontSize: scale.rf(16, min: 13.5, max: 16),
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
  Widget _buildBottomDock(
    Pet controller,
    double screenWidth,
    ResponsiveScale scale,
  ) {
    final usableWidth = (screenWidth - 20).clamp(280.0, 460.0);
    final cardWidth = ((usableWidth - 24) / 3).clamp(86.0, 110.0);
    final cardHeight = cardWidth;

    return Container(
      padding: EdgeInsets.only(
        bottom: scale.rs(30, min: 20, max: 30),
        left: scale.rs(10, min: 8, max: 10),
        right: scale.rs(10, min: 8, max: 10),
      ),
      height: cardHeight + scale.rs(70, min: 56, max: 70),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. ปุ่มซ้าย (Fish 1 - ใช้จำนวนตัว)
          Obx(() {
            bool isOutOfFood = controller.foodCount.value == 0;

            return _buildItemCard(
              imagePath: 'assets/images/fish1.png',
              customImageSize: scale.rs(90, min: 72, max: 90),
              customImageBottom: scale.rs(10, min: 6, max: 10),
              labelWidget: Text(
                isOutOfFood ? controller.remainingTime.value : "00:00:00",
                style: TextStyle(
                  color: isOutOfFood ? Colors.grey : const Color(0xFF1565C0),
                  fontWeight: FontWeight.w900,
                  fontSize: screenWidth < 360
                      ? scale.rf(14, min: 12, max: 14)
                      : scale.rf(16, min: 13.5, max: 16),
                ),
              ),
              badgeCount: controller.foodCount.value,
              cardWidth: cardWidth,
              scale: scale,
              onTap: () => controller.feedPet(),
            );
          }),

          // 2. ปุ่มกลาง (Fish 2 - ใช้เหรียญ)
          _buildItemCard(
            imagePath: 'assets/images/fish2.png',
            customImageSize: scale.rs(100, min: 80, max: 100),
            isBig: true,
            customImageBottom: -scale.rs(9, min: 6, max: 9),
            topBadgeWidget: Container(
              padding: EdgeInsets.symmetric(
                horizontal: scale.rs(9, min: 7, max: 9),
                vertical: scale.rs(6, min: 4, max: 6),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: scale.rs(8, min: 6, max: 8),
                    backgroundColor: const Color(0xFFFFC107),
                    child: Image.asset(
                      'assets/images/coin2.png',
                      width: scale.rs(16, min: 12, max: 16),
                      height: scale.rs(16, min: 12, max: 16),
                    ),
                  ),
                  SizedBox(width: scale.rs(5, min: 3, max: 5)),
                  Text(
                    "2 coin",
                    style: TextStyle(
                      color: const Color(0xFFFFC107),
                      fontWeight: FontWeight.bold,
                      fontSize: scale.rf(14, min: 12, max: 14),
                    ),
                  ),
                ],
              ),
            ),
            // [แก้ไข] เรียกใช้ feedWithCoin(2) แทน buyFood
            cardWidth: cardWidth,
            scale: scale,
            onTap: () => controller.feedWithCoin(2),
          ),

          // 3. ปุ่มขวา (Shop)
          _buildItemCard(
            imagePath: 'assets/images/shop.png',
            customImageSize: scale.rs(80, min: 64, max: 80),
            customImageBottom: scale.rs(5, min: 3, max: 5),
            topBadgeWidget: Container(
              padding: EdgeInsets.symmetric(
                horizontal: scale.rs(16, min: 12, max: 16),
                vertical: scale.rs(6, min: 4, max: 6),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
              ),
              child: Text(
                "SHOP",
                style: TextStyle(
                  color: const Color(0xFFFFC107),
                  fontWeight: FontWeight.w900,
                  fontSize: scale.rf(14, min: 12, max: 14),
                ),
              ),
            ),
            cardWidth: cardWidth,
            scale: scale,
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
    double cardWidth = 100,
    required ResponsiveScale scale,
  }) {
    final cardHeight = cardWidth;
    final imageSize = customImageSize ?? (cardWidth * 0.8);
    final double imageBottom = customImageBottom ?? 10;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight + scale.rs(40, min: 30, max: 40),
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius:
                    BorderRadius.circular(scale.rs(30, min: 22, max: 30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: scale.rs(8, min: 6, max: 8),
                    offset: Offset(0, scale.rs(4, min: 2, max: 4)),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (labelWidget != null)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: scale.rs(2, min: 1, max: 2),
                      ),
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
                top: scale.rs(25, min: 18, max: 25),
                left: 0,
                right: 0,
                child: Center(child: topBadgeWidget),
              ),
            if (badgeCount > 0)
              Positioned(
                top: scale.rs(23, min: 16, max: 23),
                right: -3,
                child: Container(
                  padding: EdgeInsets.all(scale.rs(10, min: 7, max: 10)),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$badgeCount",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: scale.rf(15, min: 12.5, max: 15),
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

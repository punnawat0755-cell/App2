import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/shop/view/shop_view.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/supabase_client.dart';

// =====================================================
// Pet Controller (GetX) - รวมของเดิม + Supabase จริง
// - โหลด coins/level/energy จาก DB
// - อาหารฟรีทุก 6 ชม. (ใช้ user_free_claims + RPC claim_free_food)
// - ให้อาหาร (RPC feed_pet) หรือ fallback เป็น local (ถ้ายังไม่มี RPC)
// - ซื้ออาหารด้วยเหรียญ (RPC buy_item หรือ fallback local)
// =====================================================
class Pet extends GetxController {
  // UI state
  var coins = 0.obs;
  var level = 1.obs;
  var energyPercent = 50.obs; // 0-100
  var username = "Seal".obs;
  final ownedItems = <int>{}.obs;

  // ซ้าย: อาหารฟรี (นับ + cooldown)
  var foodCount = 0.obs;
  var remainingTime = "00:00:00".obs;
  var isTimerRunning = false.obs;

  // อาหารแบบ coin (กลาง) - cost ตาม UI
  static const int coinFoodCost = 2;

  // claim key สำหรับอาหารฟรีช่องแรก
  static const String freeClaimKey = 'free_food_basic';

  // ถ้าคุณใช้ไอเท็มอาหารใน DB ให้กรอก sku / item_id ของอาหารฟรีไว้
  // - ถ้าทำ RPC claim_free_food แล้วเพิ่ม inventory ให้ user แล้ว
  //   feedPet() สามารถเรียก feed_pet ด้วย item_id ได้เลย
  // - ถ้ายังไม่ได้ทำ feed_pet: จะ fallback เพิ่ม energy แบบ local
  String? freeFoodItemId; // set หลังโหลดได้ (optional)

  Timer? _timer;

  // loading flags
  var isLoading = true.obs;
  var error = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadFromDb();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // =====================================================
  // 1) LOAD: pet_profiles + coins + inventory (free food qty) + cooldown
  // =====================================================
  Future<void> loadFromDb() async {
    try {
      isLoading.value = true;
      error.value = null;

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // 1) username (รองรับหลายชื่อฟิลด์)
      final prof = await supabase
          .from('profiles')
          .select('username, displayname, display_name, displayName')
          .eq('id', user.id)
          .maybeSingle();
      final fields = [
        prof?['username'] as String?,
        prof?['displayname'] as String?,
        prof?['display_name'] as String?,
        prof?['displayName'] as String?,
      ];
      final u = fields
          .whereType<String>()
          .map((v) => v.trim())
          .firstWhere((v) => v.isNotEmpty, orElse: () => '');
      if (u.isNotEmpty) username.value = u;

      // 2) pet_profiles
      final pet = await supabase
          .from('pet_profiles')
          .select('level, exp, energy')
          .eq('user_id', user.id)
          .maybeSingle();

      if (pet == null) {
        await supabase.from('pet_profiles').insert({
          'user_id': user.id,
          'level': 1,
          'exp': 0,
          'energy': 50,
        });
        level.value = 1;
        energyPercent.value = 50;
      } else {
        level.value = (pet['level'] as int?) ?? 1;
        energyPercent.value = (pet['energy'] as int?) ?? 50;
      }

      // 3) coins: ถ้าคุณมี wallet จริง ให้ query จาก coin_wallets
      // ตัวอย่าง: coin_wallets(user_id, balance)
      final wallet = await supabase
          .from('coin_wallets')
          .select('balance')
          .eq('user_id', user.id)
          .maybeSingle();
      coins.value = (wallet?['balance'] as int?) ?? coins.value;

      // 4) หา item_id ของอาหารฟรีจาก items.sku (ปรับ sku ให้ตรงของคุณ)
      // ถ้าไม่ใช้ DB items ก็ปล่อย null ได้ (จะ fallback local)
      const String freeFoodSku = 'fish1'; // ปรับให้ตรงกับ DB ของคุณ
      final freeItem = await supabase
          .from('items')
          .select('id, sku, item_type')
          .eq('sku', freeFoodSku)
          .eq('item_type', 'food')
          .maybeSingle();
      freeFoodItemId = freeItem?['id'] as String?;

      // 5) qty ของอาหารฟรี: user_item_balances(user_id,item_id,qty)
      if (freeFoodItemId != null) {
        final bal = await supabase
            .from('user_item_balances')
            .select('qty')
            .eq('user_id', user.id)
            .eq('item_id', freeFoodItemId!)
            .maybeSingle();
        foodCount.value = (bal?['qty'] as int?) ?? 0;
      }

      // 6) cooldown: user_free_claims(user_id, claim_key, last_claim_at)
      final claim = await supabase
          .from('user_free_claims')
          .select('last_claim_at')
          .eq('user_id', user.id)
          .eq('claim_key', freeClaimKey)
          .maybeSingle();

      if (claim == null || claim['last_claim_at'] == null) {
        // กดรับได้ทันที
        _stopTimerUi();
        remainingTime.value = "00:00:00";
      } else {
        final last = DateTime.parse(claim['last_claim_at'] as String);
        final next = last.add(const Duration(hours: 6));
        final diff = next.difference(DateTime.now());
        if (diff.isNegative) {
          _stopTimerUi();
          remainingTime.value = "00:00:00";
        } else {
          _startTimer(diff.inSeconds);
        }
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // =====================================================
  // 2) ซ้าย: กดให้อาหารฟรี
  // - ถ้ามี foodCount > 0: feed
  // - ถ้า foodCount == 0:
  //    - ถ้า timer ยังนับ: แจ้งให้รอ
  //    - ถ้า timer เป็น 00:00:00: call claim_free_food แล้ว reload
  // =====================================================
  Future<void> feedPet() async {
    // ถ้ามีของ -> ให้อาหาร
    if (foodCount.value > 0) {
      await _feedUsingFreeFood();
      return;
    }

    // ไม่มีของ -> ถ้าเหลือเวลา -> แจ้งรอ
    final outOfFood = foodCount.value <= 0;
    final canClaimNow =
        !isTimerRunning.value && remainingTime.value == "00:00:00";

    if (outOfFood && !canClaimNow) {
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

    // claim ได้แล้ว -> เรียก RPC claim_free_food แล้วโหลดใหม่
    await _claimFreeFood();
  }

  Future<void> _claimFreeFood() async {
    try {
      await supabase.rpc('claim_free_food', params: {
        'p_claim_key': freeClaimKey,
      });

      // รีโหลด qty + cooldown
      await loadFromDb();

      Get.snackbar(
        "ปลามาแล้ว!",
        "ได้รับปลาฟรี 1 ตัว",
        backgroundColor: Colors.blueAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
    } catch (e) {
      Get.snackbar(
        "Claim failed",
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
    }
  }

  Future<void> _feedUsingFreeFood() async {
    try {
      // พยายามเรียก RPC feed_pet ถ้ามี item_id
      if (freeFoodItemId != null) {
        await supabase.rpc('feed_pet', params: {
          'p_item_id': freeFoodItemId,
        });

        await loadFromDb();

        Get.snackbar(
          "งั่มๆ!",
          "น้องกินปลาเล็กแล้ว",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 1),
          margin: const EdgeInsets.all(10),
        );
        return;
      }

      // fallback local (กรณีคุณยังไม่ทำ RPC)
      foodCount.value--;
      energyPercent.value = (energyPercent.value + 5).clamp(0, 100);

      Get.snackbar(
        "งั่มๆ!",
        "น้องกินปลาเล็กแล้ว (+5 Energy)",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(10),
      );

      if (foodCount.value == 0) {
        _startTimer(6 * 60 * 60);
      }
    } catch (e) {
      Get.snackbar(
        "Feed failed",
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
    }
  }

  // =====================================================
  // 3) กลาง: ให้อาหารด้วยเหรียญ (2 coin)
  // - ถ้าคุณทำ buy_item + feed_pet: ควรซื้ออาหาร item_id ของ fish2 แล้ว feed
  // - แต่ใน UI นี้เหมือนจ่ายเหรียญแล้วได้พลังงานทันที -> ทำ RPC spend_coins ก็ได้
  // =====================================================
  Future<void> feedWithCoin(int cost) async {
    if (coins.value < cost) {
      Get.snackbar(
        "เหรียญไม่พอ",
        "ต้องใช้ $cost coins เพื่อให้อาหารนี้นะ",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
      return;
    }

    try {
      // แนะนำให้ทำ RPC สำหรับ “จ่ายเหรียญแล้วเพิ่ม energy”
      // ถ้าคุณยังไม่มี ให้ fallback local (หัก coin + เพิ่ม energy)
      // await supabase.rpc('feed_with_coin', params: {'p_cost': cost});

      // fallback local:
      coins.value -= cost;
      energyPercent.value = (energyPercent.value + 10).clamp(0, 100);

      Get.snackbar(
        "อร่อยจัง!",
        "เปย์น้องด้วยปลาใหญ่! (+10 Energy)",
        backgroundColor: Colors.amber,
        colorText: Colors.black,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(milliseconds: 800),
        margin: const EdgeInsets.all(10),
      );
    } catch (e) {
      Get.snackbar(
        "Feed failed",
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
    }
  }

  // =====================================================
  // TIMER UI (ใช้โชว์ countdown ให้ตรงกับ DB cooldown)
  // =====================================================
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
        _stopTimerUi();
        remainingTime.value = "00:00:00";
      }
    });
  }

  void _stopTimerUi() {
    _timer?.cancel();
    isTimerRunning.value = false;
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

// =====================================================
// UI View (เหมือนเดิม แค่เพิ่ม loading/error เล็กน้อย)
// =====================================================
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
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.error.value != null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(controller.error.value!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: controller.loadFromDb,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  _buildTopBar(controller),
                  const Spacer(),
                  const Spacer(),
                  _buildBottomDock(controller),
                ],
              );
            }),
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
          const SizedBox(height: 20),
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
                        "${controller.coins.value}",
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
                  Obx(
                    () => Text(
                      "เลเวล ${controller.level.value}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
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
          // 1) ซ้าย: ฟรี + cooldown
          Obx(() {
            final isOutOfFood = controller.foodCount.value == 0;

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

          // 2) กลาง: ใช้เหรียญ
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
            onTap: () => controller.feedWithCoin(Pet.coinFoodCost),
          ),

          // 3) ขวา: Shop
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
  // Widget: Item Card Structure (เหมือนเดิม)
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

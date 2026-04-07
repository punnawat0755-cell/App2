import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/features/pet/view/pet_view.dart';
import 'package:flutter_application_1/features/shop/data/mock/shop_items_mock.dart';
import 'package:flutter_application_1/features/shop/model/shop_item.dart';
import 'package:get/get.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------
    // เรียก Controller
    // -------------------------------------------------------------
    Pet controller;
    try {
      controller = Get.find<Pet>();
    } catch (e) {
      controller = Get.put(Pet());
    }

    final List<ShopItem> shopItems = shopItemsMock;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
            final horizontalPadding = constraints.maxWidth < 360
                ? scale.rs(14, min: 10, max: 14)
                : scale.rs(20, min: 14, max: 20);
            final isCompact = constraints.maxWidth < 360;
            final crossAxisCount = isCompact ? 2 : 3;
            final crossAxisSpacing = isCompact
                ? scale.rs(10, min: 8, max: 10)
                : scale.rs(15, min: 10, max: 15);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // -------------------------------------------------------
                      // 1. Banner
                      // -------------------------------------------------------
                      Image.asset(
                        'assets/images/shop1.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: scale.rs(120, min: 96, max: 120),
                          color: const Color(0xFF8D6E63),
                          child: const Center(
                            child: Text(
                              "BANNER IMAGE",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: scale.rs(20, min: 14, max: 20)),
                      // -------------------------------------------------------
                      // 2. Header
                      // -------------------------------------------------------
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 8,
                        ),
                        height: scale.rs(50, min: 42, max: 50),
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCEEFFE),
                                  borderRadius: BorderRadius.circular(
                                    scale.rs(20, min: 16, max: 20),
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFF4489D7),
                                    width: scale.rs(2, min: 1.5, max: 2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "Fish Shop",
                                  style: TextStyle(
                                    color: Color(0xFF4489D7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () => Get.back(),
                                  child: Image.asset(
                                    'assets/images/back.png',
                                    width: scale.rs(25, min: 20, max: 25),
                                    height: scale.rs(25, min: 20, max: 25),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(
                                      0, -scale.rs(15, min: 10, max: 15)),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFA600),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/images/coin2.png',
                                          width: scale.rs(20, min: 16, max: 20),
                                          height:
                                              scale.rs(20, min: 16, max: 20),
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(width: 5),
                                        Obx(
                                          () => Text(
                                            "${controller.coins}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // -------------------------------------------------------
                      // 3. Grid สินค้า
                      // -------------------------------------------------------
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          scale.rs(18, min: 12, max: 18),
                          horizontalPadding,
                          scale.rs(25, min: 18, max: 25),
                        ),
                        child: GridView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 0.90,
                            crossAxisSpacing: crossAxisSpacing,
                            mainAxisSpacing: scale.rs(10, min: 8, max: 10),
                          ),
                          itemCount: shopItems.length,
                          itemBuilder: (context, index) {
                            return _buildShopItemCard(
                              index,
                              shopItems[index],
                              controller,
                              scale,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: scale.rs(2, min: 1, max: 2)),
                      // -------------------------------------------------------
                      // 4. Footer Image
                      // -------------------------------------------------------
                      Image.asset(
                        'assets/images/shop2.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => Container(
                          height: scale.rs(80, min: 64, max: 80),
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget ย่อย: การ์ดสินค้าแต่ละชิ้น (เพิ่ม Logic การซื้อ)
  Widget _buildShopItemCard(
    int index,
    ShopItem item,
    Pet controller,
    ResponsiveScale scale,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCBEAF8),
        borderRadius: BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // รูปสินค้า
          Container(
            height: scale.rs(75, min: 60, max: 75),
            width: double.infinity,
            alignment: Alignment.center,
            padding: EdgeInsets.all(scale.rs(10, min: 8, max: 10)),
            child: Image.asset(
              item.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),

          // ปุ่มกด (Logic เช็คสถานะ Owned/Buy)
          Obx(() {
            // เช็คว่าเคยซื้อไปยัง (ต้องเพิ่ม ownedItems ใน controller ก่อนนะ)
            bool isOwned = false;
            try {
              isOwned = controller.ownedItems.contains(index);
            } catch (e) {
              // กัน error กรณีลืมเพิ่มตัวแปร
            }

            if (isOwned) {
              // --- [กรณี 1: ซื้อแล้ว] แสดงปุ่ม "ใช้เลย" ---
              return GestureDetector(
                onTap: () async {
                  Get.snackbar(
                    "สวมใส่สำเร็จ",
                    "เปลี่ยนไอเท็มเรียบร้อย!",
                    backgroundColor: Colors.blueAccent,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 1),
                  );
                  // ใส่ Logic การเปลี่ยนชุดตรงนี้ได้เลย
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: scale.rs(5, min: 3, max: 5)),
                  padding: EdgeInsets.symmetric(
                    horizontal: scale.rs(12, min: 8, max: 12),
                    vertical: scale.rs(4, min: 2, max: 4),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F), // สีเหลืองอ่อน (ใช้เลย)
                    borderRadius:
                        BorderRadius.circular(scale.rs(25, min: 18, max: 25)),
                  ),
                  child: Text(
                    "ใช้เลย",
                    style: TextStyle(
                      color: const Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                      fontSize: scale.rf(12, min: 10.5, max: 12),
                    ),
                  ),
                ),
              );
            } else {
              // --- [กรณี 2: ยังไม่ซื้อ] แสดงราคาและกดซื้อได้ ---
              return GestureDetector(
                onTap: () async {
                  final price = item.price;
                  final didSpend = await controller.spendCoins(price);
                  if (didSpend) {
                    // เงินพอ: หักเงิน + เพิ่มเข้าของที่มี
                    try {
                      controller.ownedItems.add(index);
                    } catch (e) {
                      debugPrint(
                        "Error: Please add 'ownedItems' to Pet Controller",
                      );
                    }
                    Get.snackbar(
                      "สำเร็จ",
                      "ซื้อของเรียบร้อย!",
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 1),
                    );
                  } else {
                    // เงินไม่พอ
                    Get.snackbar(
                      "เหรียญไม่พอ",
                      "ไปเก็บเหรียญเพิ่มก่อนนะ",
                      backgroundColor: Colors.redAccent,
                      colorText: Colors.white,
                    );
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: scale.rs(5, min: 3, max: 5)),
                  padding: EdgeInsets.symmetric(
                    horizontal: scale.rs(8, min: 6, max: 8),
                    vertical: scale.rs(2, min: 1, max: 2),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA600), // สีส้ม (ราคา)
                    borderRadius:
                        BorderRadius.circular(scale.rs(25, min: 18, max: 25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/coin2.png',
                        width: scale.rs(22, min: 18, max: 22),
                        height: scale.rs(22, min: 18, max: 22),
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: scale.rs(5, min: 3, max: 5)),
                      Text(
                        '${item.price}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: scale.rf(14, min: 12, max: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }),
        ],
      ),
    );
  }
}

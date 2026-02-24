import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/pet/view/pet_view.dart';
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

    // ข้อมูลสินค้า
    final List<Map<String, dynamic>> shopItems = [
      {'img': 'assets/images/s1.png', 'price': 25},
      {'img': 'assets/images/s2.png', 'price': 35},
      {'img': 'assets/images/s3.png', 'price': 45},
      {'img': 'assets/images/s4.png', 'price': 50},
      {'img': 'assets/images/s5.png', 'price': 65},
      {'img': 'assets/images/s6.png', 'price': 85},
      {'img': 'assets/images/s7.png', 'price': 95},
      {'img': 'assets/images/s8.png', 'price': 95},
      {'img': 'assets/images/s9.png', 'price': 95},
      {'img': 'assets/images/s10.png', 'price': 65},
      {'img': 'assets/images/s11.png', 'price': 85},
      {'img': 'assets/images/s12.png', 'price': 95},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FF),
      body: SafeArea(
        top: false,
        bottom: false,
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
                  height: 120,
                  color: const Color(0xFF8D6E63),
                  child: const Center(
                    child: Text(
                      "BANNER IMAGE",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------------
              // 2. Header
              // -------------------------------------------------------
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                height: 50,
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
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF4489D7),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
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
                            width: 25,
                            height: 25,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -15),
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
                                  width: 20,
                                  height: 20,
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
              // 3. Grid สินค้า (Updated)
              // -------------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(35, 18, 35, 25),
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.90,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: shopItems.length,
                  itemBuilder: (context, index) {
                    // ส่งข้อมูลทั้งหมดไปให้ Widget สร้างการ์ด
                    return _buildShopItemCard(
                      index,
                      shopItems[index],
                      controller,
                    );
                  },
                ),
              ),

              const SizedBox(height: 2),

              // -------------------------------------------------------
              // 4. Footer Image
              // -------------------------------------------------------
              Image.asset(
                'assets/images/shop2.png',
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) =>
                    Container(height: 80, color: Colors.grey[300]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget ย่อย: การ์ดสินค้าแต่ละชิ้น (เพิ่ม Logic การซื้อ)
  Widget _buildShopItemCard(
    int index,
    Map<String, dynamic> item,
    Pet controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCBEAF8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // รูปสินค้า
          Container(
            height: 75,
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              item['img'],
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
                onTap: () {
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
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F), // สีเหลืองอ่อน (ใช้เลย)
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    "ใช้เลย",
                    style: TextStyle(
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            } else {
              // --- [กรณี 2: ยังไม่ซื้อ] แสดงราคาและกดซื้อได้ ---
              return GestureDetector(
                onTap: () {
                  int price = item['price'];
                  if (controller.coins.value >= price) {
                    // เงินพอ: หักเงิน + เพิ่มเข้าของที่มี
                    controller.coins.value -= price;
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
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA600), // สีส้ม (ราคา)
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/coin2.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "${item['price']}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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

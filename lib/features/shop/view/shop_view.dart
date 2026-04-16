import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/features/pet/controller/pet_controller.dart';
import 'package:flutter_application_1/features/shop/data/mock/shop_items_mock.dart';
import 'package:flutter_application_1/features/shop/model/shop_item.dart';
import 'package:get/get.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.isRegistered<Pet>() ? Get.find<Pet>() : Get.put(Pet());
    final List<ShopItem> shopItems = shopItemsMock;

    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FF),
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
            final childAspectRatio = isCompact ? 0.68 : 0.84;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                              'BANNER IMAGE',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: scale.rs(20, min: 14, max: 20)),
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
                                  'Fish Shop',
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
                                  onTap: () async {
                                    await controller.refreshState(silent: true);
                                    if (context.mounted) {
                                      Get.back();
                                    }
                                  },
                                  child: Image.asset(
                                    'assets/images/back.png',
                                    width: scale.rs(25, min: 20, max: 25),
                                    height: scale.rs(25, min: 20, max: 25),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(
                                    0,
                                    -scale.rs(15, min: 10, max: 15),
                                  ),
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
                                          height: scale.rs(
                                            20,
                                            min: 16,
                                            max: 20,
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(width: 5),
                                        Obx(
                                          () => Text(
                                            '${controller.coins}',
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
                            childAspectRatio: childAspectRatio,
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: scale.rs(8, min: 6, max: 8)),
          Expanded(
            child: Container(
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
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: scale.rs(8, min: 6, max: 8),
            ),
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF2C5E92),
                fontWeight: FontWeight.w700,
                fontSize: scale.rf(12, min: 10.5, max: 12),
              ),
            ),
          ),
          SizedBox(height: scale.rs(6, min: 4, max: 6)),
          Obx(() {
            final isOwned = controller.isOwnedItem(index);
            final isEquipped = controller.isEquippedItem(index);
            final isBusy = controller.isPurchasingItem(index) ||
                (controller.isEquipping.value && isEquipped);
            final canTap = !isBusy &&
                !controller.isLoading.value &&
                !controller.isRefreshing.value &&
                !controller.isEquipping.value &&
                !controller.isFeedingCoin.value &&
                !controller.isFeedingFree.value;

            if (isOwned) {
              return IgnorePointer(
                ignoring: !canTap,
                child: Opacity(
                  opacity: canTap ? 1 : 0.7,
                  child: GestureDetector(
                    onTap: () async {
                      if (isEquipped) {
                        final unequipped = await controller.unequipItem();
                        if (unequipped) {
                          Get.snackbar(
                            'ถอดชุดแล้ว',
                            'ถอด ${item.name} เรียบร้อย',
                            backgroundColor: Colors.blueGrey,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 1),
                          );
                        }
                        return;
                      }

                      final equipped = await controller.equipItem(index);
                      if (equipped) {
                        Get.snackbar(
                          'สวมใส่สำเร็จ',
                          'ตอนนี้กำลังใช้ ${item.name}',
                          backgroundColor: Colors.blueAccent,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 1),
                        );
                      }
                    },
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: scale.rs(28, min: 26, max: 30),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: scale.rs(12, min: 8, max: 12),
                        vertical: scale.rs(4, min: 2, max: 4),
                      ),
                      decoration: BoxDecoration(
                        color: isEquipped
                            ? const Color(0xFF4489D7)
                            : const Color(0xFFFFD54F),
                        borderRadius: BorderRadius.circular(
                          scale.rs(25, min: 18, max: 25),
                        ),
                      ),
                      child: isBusy
                          ? SizedBox(
                              width: scale.rs(18, min: 16, max: 18),
                              height: scale.rs(18, min: 16, max: 18),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEquipped ? 'ถอดออก' : 'ใช้เลย',
                              style: TextStyle(
                                color: isEquipped
                                    ? Colors.white
                                    : const Color(0xFF5D4037),
                                fontWeight: FontWeight.bold,
                                fontSize: scale.rf(12, min: 10.5, max: 12),
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }

            return IgnorePointer(
              ignoring: !canTap,
              child: Opacity(
                opacity: canTap ? 1 : 0.7,
                child: GestureDetector(
                  onTap: () async {
                    final didSpend = await controller.purchaseItem(
                      index,
                      item.price,
                    );
                    if (didSpend) {
                      Get.snackbar(
                        'สำเร็จ',
                        'ซื้อ ${item.name} เรียบร้อย!',
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 1),
                      );
                    } else if (!controller.isPurchasingItem(index)) {
                      Get.snackbar(
                        'เหรียญไม่พอ',
                        'ไปเก็บเหรียญเพิ่มก่อนนะ',
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: scale.rs(28, min: 26, max: 30),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: scale.rs(8, min: 6, max: 8),
                      vertical: scale.rs(2, min: 1, max: 2),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA600),
                      borderRadius: BorderRadius.circular(
                        scale.rs(25, min: 18, max: 25),
                      ),
                    ),
                    child: isBusy
                        ? SizedBox(
                            width: scale.rs(22, min: 18, max: 22),
                            height: scale.rs(22, min: 18, max: 22),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
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
                ),
              ),
            );
          }),
          SizedBox(height: scale.rs(8, min: 6, max: 8)),
        ],
      ),
    );
  }
}

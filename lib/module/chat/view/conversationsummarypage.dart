import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chatconfirmdialog.dart';
import 'chatselectionpage.dart';

class ConversationSummaryController extends GetxController {
  final RxBool isFollowed = false.obs;
  final RxBool isBlocked = false.obs;
  final RxInt currentRating = 1.obs;

  void resetState() {
    isFollowed.value = false;
    isBlocked.value = false;
    currentRating.value = 1;
  }

  void showBlockDialog(BuildContext context) {
    showChatConfirmDialog(
      title: "คุณต้องการที่จะบล็อกใช่หรือไม่",
      onConfirm: () {
        Get.back();
        isBlocked.value = true;
      },
    );
  }
}

class ConversationSummaryPage extends StatelessWidget {
  ConversationSummaryPage({super.key}) {
    controller.resetState();
  }

  final ConversationSummaryController controller =
      Get.isRegistered<ConversationSummaryController>()
      ? Get.find<ConversationSummaryController>()
      : Get.put(ConversationSummaryController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Text(
                "Jellyfish",
                style: TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: Colors.white,
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1548681528-6a5c45b66b42?auto=format&fit=crop&w=600&q=80',
                    ),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              if (!controller.isBlocked.value) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        controller.isFollowed.value =
                            !controller.isFollowed.value;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: controller.isFollowed.value
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFFD3ECF8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: controller.isFollowed.value
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4489D7,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: Text(
                          controller.isFollowed.value ? "ติดตามแล้ว" : "ติดตาม",
                          style: TextStyle(
                            color: controller.isFollowed.value
                                ? Colors.grey[600]
                                : const Color(0xFF4489D7),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: () => controller.showBlockDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          "บล็อก",
                          style: TextStyle(
                            color: Color(0xFF4489D7),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ] else ...[
                const SizedBox(height: 50),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      controller.currentRating.value = index + 1;
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.star_rounded,
                        size: 55,
                        color: index < controller.currentRating.value
                            ? const Color(0xFFFFE082)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Get.offAll(() => const ChatSelectionPage());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE082),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    "บันทึก",
                    style: TextStyle(
                      color: Color(0xFF6C6C6C),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 300),
            ],
          ),
        ),
      ),
    );
  }
}

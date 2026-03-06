import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chatconfirmdialog.dart';
import 'chat_view.dart';

class WaitingChatController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final AnimationController animationController;
  Timer? timer;

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 5), () {
      Get.off(() => ChatPage());
    });
  }

  void showExitDialog(BuildContext context) {
    timer?.cancel();
    showChatConfirmDialog(
      title: "คุณต้องการที่จะออกจากการจับคู่\nใช่หรือไม่",
      barrierDismissible: false,
      onConfirm: () {
        Get.back();
        Get.back();
      },
      onCancel: () {
        Get.back();
        startTimer();
      },
    );
  }

  @override
  void onClose() {
    animationController.dispose();
    timer?.cancel();
    super.onClose();
  }
}

class WaitingChatPage extends StatelessWidget {
  WaitingChatPage({super.key});

  final WaitingChatController controller =
      Get.isRegistered<WaitingChatController>()
      ? Get.find<WaitingChatController>()
      : Get.put(WaitingChatController());

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        controller.showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => controller.showExitDialog(context),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Image.asset(
                'assets/images/back.png',
                width: 25,
                height: 25,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'รอคู่สนทนาสักครู่',
                style: TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 450,
                height: 450,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildOneWayRipple(0.0),
                    _buildOneWayRipple(0.33),
                    _buildOneWayRipple(0.66),
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFAEDEF4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Image.asset(
                            'assets/images/sad.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOneWayRipple(double startDelay) {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        final double t =
            (controller.animationController.value + startDelay) % 1.0;
        final double currentSize = 240 + (180 * t);
        final double opacity = 0.4 * (1.0 - t);
        return Container(
          width: currentSize,
          height: currentSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFAEDEF4).withValues(alpha: opacity),
            border: Border.all(
              color: Colors.white.withValues(alpha: opacity),
              width: 1,
            ),
          ),
        );
      },
    );
  }
}

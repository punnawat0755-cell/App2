import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/features/pet/controller/pet_controller.dart';
import 'package:flutter_application_1/features/pet/model/pet_state.dart';
import 'package:flutter_application_1/features/shop/view/shop_view.dart';
import 'package:get/get.dart';

class PetPage extends StatefulWidget {
  const PetPage({
    super.key,
    required this.isActive,
  });

  final bool isActive;

  @override
  State<PetPage> createState() => _PetPageState();
}

class _PetPageState extends State<PetPage> with WidgetsBindingObserver {
  late final Pet controller;
  late final AudioPlayer _audioPlayer;
  bool _isSoundPlaying = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.isRegistered<Pet>() ? Get.find<Pet>() : Get.put(Pet());
    _audioPlayer = AudioPlayer();
    unawaited(_syncSoundPlayback());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isActive) {
        unawaited(controller.refreshState(silent: true));
      }
    });
  }

  @override
  void didUpdateWidget(covariant PetPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      unawaited(_syncSoundPlayback());
      if (widget.isActive) {
        unawaited(controller.refreshState(silent: true));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopLoopSound());
    _audioPlayer.dispose();
    _isDisposed = true;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (widget.isActive) {
        unawaited(controller.refreshState(silent: true));
      }
      unawaited(_syncSoundPlayback());
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_stopLoopSound());
    }
  }

  Future<void> _syncSoundPlayback() async {
    if (_isDisposed) {
      return;
    }

    if (widget.isActive) {
      await _startLoopSound();
      return;
    }

    await _stopLoopSound();
  }

  Future<void> _startLoopSound() async {
    if (_isDisposed || _isSoundPlaying) {
      return;
    }

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('Sound/howareyou.mp3'));
      _isSoundPlaying = true;
    } catch (e) {
      _isSoundPlaying = false;
      debugPrint('Failed to play looping pet sound: $e');
    }
  }

  Future<void> _stopLoopSound() async {
    if (!_isSoundPlaying) {
      return;
    }

    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Failed to stop looping pet sound: $e');
    } finally {
      _isSoundPlaying = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backpet.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final scale = ResponsiveScale.fromWidth(screenWidth);
                return Column(
                  children: [
                    _buildTopBar(controller, screenWidth, scale),
                    Expanded(child: _buildPetHero(controller, scale)),
                    _buildBottomDock(controller, screenWidth, scale),
                  ],
                );
              },
            ),
          ),
          Obx(() {
            if (!controller.isLoading.value) {
              return const SizedBox.shrink();
            }

            return Container(
              color: Colors.white.withValues(alpha: 0.18),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: Color(0xFF4489D7),
              ),
            );
          }),
        ],
      ),
    );
  }

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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: isCompact
                ? scale.rs(10, min: 8, max: 10)
                : scale.rs(15, min: 10, max: 15),
            runSpacing: scale.rs(8, min: 6, max: 8),
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
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
                        '${controller.coins}',
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () => Text(
                      'เลเวล ${controller.level.value}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: scale.rf(18, min: 15, max: 18),
                      ),
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
                            final currentW = (maxW - left - right) *
                                (controller.energyPercent.value / 100);
                            return Container(
                              width: currentW,
                              height: double.infinity,
                              margin: const EdgeInsets.fromLTRB(
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
                              ' ${controller.energyPercent.value} %',
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

  Widget _buildPetHero(Pet controller, ResponsiveScale scale) {
    return Center(
      child: Obx(() {
        final equippedItem = controller.equippedItem;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /*
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: scale.rs(18, min: 14, max: 18),
                vertical: scale.rs(8, min: 6, max: 8),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                controller.username.value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: scale.rf(18, min: 15, max: 18),
                  color: const Color(0xFF2C5E92),
                ),
              ),
            ),
            SizedBox(height: scale.rs(16, min: 12, max: 16)),
            */
            SizedBox(
              width: scale.rs(260, min: 210, max: 260),
              height: scale.rs(230, min: 180, max: 230),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.28),
                            Colors.white.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Image.asset(
                    controller.petMoodAssetPath,
                    width: scale.rs(210, min: 170, max: 210),
                    height: scale.rs(210, min: 170, max: 210),
                    fit: BoxFit.contain,
                  ),
                  if (equippedItem != null)
                    Positioned(
                      top: scale.rs(22, min: 18, max: 22),
                      child: Image.asset(
                        equippedItem.imagePath,
                        width: scale.rs(78, min: 62, max: 78),
                        height: scale.rs(78, min: 62, max: 78),
                        fit: BoxFit.contain,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: scale.rs(8, min: 6, max: 8)),
            if (equippedItem != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: scale.rs(14, min: 10, max: 14),
                  vertical: scale.rs(8, min: 6, max: 8),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3C4),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFFFD146),
                    width: 1.4,
                  ),
                ),
                child: Text(
                  'กำลังใส่ ${equippedItem.name}',
                  style: TextStyle(
                    color: const Color(0xFF8A6100),
                    fontWeight: FontWeight.w800,
                    fontSize: scale.rf(13, min: 11, max: 13),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

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
          Obx(() {
            final isFoodRefillPending =
                controller.foodCount.value < PetState.maxFoodCount;
            return _buildItemCard(
              imagePath: 'assets/images/fish1.png',
              customImageSize: scale.rs(90, min: 72, max: 90),
              customImageBottom: scale.rs(10, min: 6, max: 10),
              labelWidget: Text(
                isFoodRefillPending
                    ? controller.remainingTime.value
                    : '00:00:00',
                style: TextStyle(
                  color: isFoodRefillPending
                      ? const Color(0xFF1565C0)
                      : Colors.grey,
                  fontWeight: FontWeight.w900,
                  fontSize: screenWidth < 360
                      ? scale.rf(14, min: 12, max: 14)
                      : scale.rf(16, min: 13.5, max: 16),
                ),
              ),
              badgeCount: controller.foodCount.value,
              cardWidth: cardWidth,
              scale: scale,
              isDisabled: controller.isAnyActionRunning,
              isBusy: controller.isFeedingFree.value,
              onTap: controller.feedPet,
            );
          }),
          Obx(
            () => _buildItemCard(
              imagePath: 'assets/images/fish2.png',
              customImageSize: scale.rs(100, min: 80, max: 100),
              customImageBottom: -scale.rs(9, min: 6, max: 9),
              topBadgeWidget: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: scale.rs(9, min: 7, max: 9),
                  vertical: scale.rs(6, min: 4, max: 6),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    scale.rs(20, min: 16, max: 20),
                  ),
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
                      '2 coin',
                      style: TextStyle(
                        color: const Color(0xFFFFC107),
                        fontWeight: FontWeight.bold,
                        fontSize: scale.rf(14, min: 12, max: 14),
                      ),
                    ),
                  ],
                ),
              ),
              cardWidth: cardWidth,
              scale: scale,
              isDisabled: controller.isAnyActionRunning,
              isBusy: controller.isFeedingCoin.value,
              onTap: () => controller.feedWithCoin(2),
            ),
          ),
          Obx(
            () => _buildItemCard(
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
                  borderRadius: BorderRadius.circular(
                    scale.rs(20, min: 16, max: 20),
                  ),
                ),
                child: Text(
                  'SHOP',
                  style: TextStyle(
                    color: const Color(0xFFFFC107),
                    fontWeight: FontWeight.w900,
                    fontSize: scale.rf(14, min: 12, max: 14),
                  ),
                ),
              ),
              cardWidth: cardWidth,
              scale: scale,
              isDisabled: controller.isAnyActionRunning,
              isBusy: controller.isRefreshing.value,
              onTap: () async {
                await Get.to(() => const ShopPage());
                await controller.refreshState(silent: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard({
    required String imagePath,
    required Future<void> Function() onTap,
    Widget? labelWidget,
    Widget? topBadgeWidget,
    int badgeCount = 0,
    double? customImageSize,
    double? customImageBottom,
    bool isDisabled = false,
    bool isBusy = false,
    double cardWidth = 100,
    required ResponsiveScale scale,
  }) {
    final cardHeight = cardWidth;
    final imageSize = customImageSize ?? (cardWidth * 0.8);
    final imageBottom = customImageBottom ?? 10.0;

    return IgnorePointer(
      ignoring: isDisabled,
      child: Opacity(
        opacity: isDisabled ? 0.68 : 1,
        child: GestureDetector(
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
                    borderRadius: BorderRadius.circular(
                      scale.rs(30, min: 22, max: 30),
                    ),
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
                        '$badgeCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: scale.rf(15, min: 12.5, max: 15),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (isBusy)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: scale.rs(36, min: 32, max: 36),
                        height: scale.rs(36, min: 32, max: 36),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Color(0xFF4489D7),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/services/coin_service.dart';
import 'package:flutter_application_1/features/pet/model/pet_state.dart';
import 'package:flutter_application_1/features/pet/repository/pet_repository.dart';
import 'package:flutter_application_1/features/pet/service/pet_service.dart';
import 'package:flutter_application_1/features/shop/data/mock/shop_items_mock.dart';
import 'package:flutter_application_1/features/shop/model/shop_item.dart';
import 'package:get/get.dart';

class Pet extends GetxController {
  static const Duration _freeFoodCooldown = Duration(minutes: 30);
  static const Duration _fedMoodDuration = Duration(seconds: 10);
  static const Duration _stateRequestTimeout = Duration(seconds: 6);

  late final CoinService _coinService;
  late final PetRepository _petRepository;

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isFeedingFree = false.obs;
  final isFeedingCoin = false.obs;
  final isEquipping = false.obs;
  final purchasingItemId = RxnInt();
  final equippedItemId = RxnInt();
  final ownedItems = <int>[].obs;

  RxInt get coins => _coinService.coins;
  final level = 1.obs;
  final exp = 0.obs;
  final energyPercent = 50.obs;
  final username = 'Seal'.obs;

  final foodCount = PetState.maxFoodCount.obs;
  final remainingTime = '00:00:00'.obs;
  final isTimerRunning = false.obs;
  Timer? _timer;
  Timer? _fedMoodTimer;
  bool _isCompletingFoodTimer = false;
  int _mutationVersion = 0;
  final _temporaryMoodAssetPath = RxnString();

  bool get isAnyActionRunning =>
      isLoading.value ||
      isFeedingFree.value ||
      isFeedingCoin.value ||
      isEquipping.value ||
      purchasingItemId.value != null;

  ShopItem? get equippedItem {
    final itemId = equippedItemId.value;
    if (itemId == null || itemId < 0 || itemId >= shopItemsMock.length) {
      return null;
    }
    return shopItemsMock[itemId];
  }

  int get expRequiredForNextLevel {
    final safeLevel = level.value < 1 ? 1 : level.value;
    return 20 + ((safeLevel - 1) * 8);
  }

  double get expProgress {
    final requiredExp = expRequiredForNextLevel;
    if (requiredExp <= 0) {
      return 0;
    }
    return (exp.value / requiredExp).clamp(0, 1).toDouble();
  }

  String get petMoodAssetPath {
    final temporaryPath = _temporaryMoodAssetPath.value;
    if (temporaryPath != null) {
      return temporaryPath;
    }
    return 'assets/images/whale_impassible.png';
  }

  @override
  void onInit() {
    super.onInit();
    _coinService = Get.isRegistered<CoinService>()
        ? Get.find<CoinService>()
        : Get.put(CoinService(), permanent: true);

    final petService = Get.isRegistered<PetService>()
        ? Get.find<PetService>()
        : Get.put(PetService(), permanent: true);
    _petRepository = Get.isRegistered<PetRepository>()
        ? Get.find<PetRepository>()
        : Get.put(PetRepository(service: petService), permanent: true);

    unawaited(refreshState(silent: true));
  }

  @override
  void onClose() {
    _timer?.cancel();
    _fedMoodTimer?.cancel();
    super.onClose();
  }

  Future<void> refreshState({bool silent = false}) async {
    if (isLoading.value || isRefreshing.value) {
      return;
    }
    final mutationVersionAtStart = _mutationVersion;

    if (silent) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }

    try {
      var state =
          await _petRepository.loadState().timeout(_stateRequestTimeout);
      state = await _petRepository
          .alignFoodCooldown(
            refillDuration: _freeFoodCooldown,
            baseState: state,
          )
          .timeout(_stateRequestTimeout);
      if (mutationVersionAtStart != _mutationVersion) {
        return;
      }
      _applyState(state);
      _resumeTimerIfNeeded(state);
    } on TimeoutException catch (error) {
      Get.log('Pet.refreshState timeout: $error');
      if (!silent) {
        Get.snackbar(
          'โหลดข้อมูลสัตว์เลี้ยงช้าเกินไป',
          'ลองใหม่อีกครั้งได้ทันที',
          backgroundColor: Colors.orangeAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(10),
        );
      }
    } catch (error) {
      Get.log('Pet.refreshState error: $error');
      if (!silent) {
        Get.snackbar(
          'โหลดข้อมูลสัตว์เลี้ยงไม่สำเร็จ',
          '$error',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(10),
        );
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  void _applyState(PetState state) {
    level.value = state.level;
    exp.value = state.exp;
    energyPercent.value = state.energyPercent;
    username.value = state.username;
    foodCount.value = state.foodCount;
    ownedItems.assignAll(state.ownedItems);
    equippedItemId.value = state.equippedItemId;
    if (state.nextFoodReadyAt == null) {
      remainingTime.value = '00:00:00';
      isTimerRunning.value = false;
    }
  }

  void _applyMutationState(PetState state) {
    _mutationVersion += 1;
    _applyState(state);
  }

  void _resumeTimerIfNeeded(PetState state) {
    if (state.foodCount >= PetState.maxFoodCount) {
      _timer?.cancel();
      remainingTime.value = '00:00:00';
      isTimerRunning.value = false;
      return;
    }

    final nextFoodReadyAt = state.nextFoodReadyAt;
    if (nextFoodReadyAt == null) {
      _timer?.cancel();
      return;
    }

    final remainingSeconds =
        nextFoodReadyAt.difference(DateTime.now()).inSeconds;
    if (remainingSeconds <= 0) {
      unawaited(_completeFoodTimer(showSnackBar: false));
      return;
    }

    _startTimer(remainingSeconds);
  }

  bool isOwnedItem(int itemId) => ownedItems.contains(itemId);

  bool isEquippedItem(int itemId) => equippedItemId.value == itemId;

  bool isPurchasingItem(int itemId) => purchasingItemId.value == itemId;

  Future<bool> purchaseItem(int itemId, int price) async {
    if (isPurchasingItem(itemId) || isLoading.value) {
      return false;
    }
    if (isOwnedItem(itemId)) {
      return true;
    }

    purchasingItemId.value = itemId;
    var didSpendCoins = false;
    try {
      didSpendCoins = await spendCoins(price);
      if (!didSpendCoins) {
        return false;
      }

      final nextState = await _petRepository.addOwnedItem(itemId);
      _applyMutationState(nextState);
      return true;
    } catch (error) {
      if (didSpendCoins) {
        await _refundCoinsSafely(price);
      }
      Get.log('Pet.purchaseItem error: $error');
      Get.snackbar(
        'ซื้อของไม่สำเร็จ',
        '$error',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
      return false;
    } finally {
      purchasingItemId.value = null;
    }
  }

  Future<bool> equipItem(int itemId) async {
    if (isEquipping.value || isLoading.value) {
      return false;
    }
    if (!isOwnedItem(itemId)) {
      Get.snackbar(
        'ยังไม่ได้ซื้อไอเท็มนี้',
        'ซื้อก่อนแล้วค่อยนำมาใช้ได้เลย',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
      return false;
    }
    if (isEquippedItem(itemId)) {
      return true;
    }

    isEquipping.value = true;
    try {
      final nextState = await _petRepository.equipItem(itemId);
      _applyMutationState(nextState);
      return true;
    } catch (error) {
      Get.log('Pet.equipItem error: $error');
      Get.snackbar(
        'สวมใส่ไม่สำเร็จ',
        '$error',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
      return false;
    } finally {
      isEquipping.value = false;
    }
  }

  Future<bool> unequipItem() async {
    if (isEquipping.value || isLoading.value) {
      return false;
    }
    if (equippedItemId.value == null) {
      return true;
    }

    isEquipping.value = true;
    try {
      final nextState = await _petRepository.unequipItem();
      _applyMutationState(nextState);
      return true;
    } catch (error) {
      Get.log('Pet.unequipItem error: $error');
      Get.snackbar(
        'ถอดไอเท็มไม่สำเร็จ',
        '$error',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
      return false;
    } finally {
      isEquipping.value = false;
    }
  }

  Future<void> feedPet() async {
    if (isFeedingFree.value || isAnyActionRunning) {
      return;
    }
    if (foodCount.value <= 0) {
      Get.snackbar(
        'อาหารหมด!',
        'ต้องรอเวลาให้ปลาว่ายมาเติมก่อนนะ (เหลือเวลา ${remainingTime.value})',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
      return;
    }

    isFeedingFree.value = true;
    try {
      final nextState = await _petRepository.feedPet(
        refillDuration: _freeFoodCooldown,
      );
      final leveledUp = nextState.level > level.value;
      _applyMutationState(nextState);
      _resumeTimerIfNeeded(nextState);
      _showFedMoodTemporarily();

      Get.snackbar(
        leveledUp ? 'เลเวลอัป!' : 'งั่มๆ!',
        leveledUp
            ? 'น้องโตขึ้นเป็นเลเวล ${nextState.level} แล้ว'
            : 'น้องกินปลาเล็กแล้ว (+5 Energy, +10 EXP)',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(10),
      );
    } on StateError {
      Get.snackbar(
        'อาหารหมด!',
        'ต้องรอเวลาให้ปลาว่ายมาเติมก่อนนะ (เหลือเวลา ${remainingTime.value})',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
    } catch (error) {
      Get.snackbar(
        'ให้อาหารไม่สำเร็จ',
        '$error',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
    } finally {
      isFeedingFree.value = false;
    }
  }

  Future<void> feedWithCoin(int cost) async {
    if (isFeedingCoin.value || isAnyActionRunning) {
      return;
    }

    isFeedingCoin.value = true;
    var didSpendCoins = false;
    try {
      didSpendCoins = await _coinService.spendCoins(cost);
      if (!didSpendCoins) {
        Get.snackbar(
          'เหรียญไม่พอ',
          'ต้องใช้ $cost coins เพื่อให้อาหารนี้นะ',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(10),
        );
        return;
      }

      final nextState = await _petRepository.feedWithCoin();
      final leveledUp = nextState.level > level.value;
      _applyMutationState(nextState);
      _showFedMoodTemporarily();

      Get.snackbar(
        leveledUp ? 'เลเวลอัป!' : 'อร่อยจัง!',
        leveledUp
            ? 'น้องโตขึ้นเป็นเลเวล ${nextState.level} แล้ว'
            : 'เปย์น้องด้วยปลาใหญ่! (+10 Energy, +18 EXP)',
        backgroundColor: Colors.amber,
        colorText: Colors.black,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(milliseconds: 800),
        margin: const EdgeInsets.all(10),
      );
    } catch (error) {
      if (didSpendCoins) {
        await _refundCoinsSafely(cost);
      }
      Get.snackbar(
        'ให้อาหารไม่สำเร็จ',
        '$error',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
    } finally {
      isFeedingCoin.value = false;
    }
  }

  Future<bool> spendCoins(int cost) => _coinService.spendCoins(cost);

  Future<void> _refundCoinsSafely(int amount) async {
    if (amount <= 0) {
      return;
    }

    try {
      await _coinService.addCoins(amount);
    } catch (error) {
      Get.log('Pet._refundCoinsSafely error: $error');
    }
  }

  void _showFedMoodTemporarily() {
    _fedMoodTimer?.cancel();
    _temporaryMoodAssetPath.value = 'assets/images/whale_love.png';
    _fedMoodTimer = Timer(_fedMoodDuration, () {
      _temporaryMoodAssetPath.value = null;
    });
  }

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
        unawaited(_completeFoodTimer());
      }
    });
  }

  Future<void> _completeFoodTimer({bool showSnackBar = true}) async {
    if (_isCompletingFoodTimer) {
      return;
    }
    _isCompletingFoodTimer = true;

    try {
      isTimerRunning.value = false;
      remainingTime.value = '00:00:00';

      final nextState = await _petRepository.markFoodRefillReady(
        refillDuration: _freeFoodCooldown,
      );
      _applyMutationState(nextState);
      _resumeTimerIfNeeded(nextState);

      if (showSnackBar) {
        Get.snackbar(
          'ปลามาแล้ว!',
          'ได้รับปลาฟรีแล้ว ตอนนี้มี ${nextState.foodCount}/${PetState.maxFoodCount}',
          backgroundColor: Colors.blueAccent,
          colorText: Colors.white,
        );
      }
    } catch (error) {
      Get.log('Pet._completeFoodTimer error: $error');
    } finally {
      _isCompletingFoodTimer = false;
    }
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}

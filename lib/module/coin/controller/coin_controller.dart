import 'package:get/get.dart';

class CoinController extends GetxController {
  final RxInt coins = 30.obs;

  void addCoins(int amount) {
    coins.value += amount;
  }

  bool spendCoins(int amount) {
    if (coins.value < amount) return false;
    coins.value -= amount;
    return true;
  }
}

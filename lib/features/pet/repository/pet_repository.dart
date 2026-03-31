import 'package:flutter_application_1/features/pet/model/pet_state.dart';
import 'package:flutter_application_1/features/pet/service/pet_service.dart';

class PetRepository {
  PetRepository({PetService? service}) : _service = service ?? PetService();

  final PetService _service;
  static const int _freeFeedExpReward = 10;
  static const int _coinFeedExpReward = 18;

  Future<PetState> loadState() => _service.loadState();

  Future<PetState> feedPet({
    required Duration refillDuration,
  }) async {
    final current = await _service.loadState();
    if (current.foodCount <= 0) {
      throw StateError('out_of_food');
    }

    final nextFoodCount = current.foodCount - 1;
    final nextState = _applyExpGain(
      current.copyWith(
        foodCount: nextFoodCount,
        energyPercent: (current.energyPercent + 5).clamp(0, 100),
        nextFoodReadyAt:
            nextFoodCount == 0 ? DateTime.now().add(refillDuration) : null,
        clearNextFoodReadyAt: nextFoodCount > 0,
      ),
      _freeFeedExpReward,
    );
    return _service.saveState(nextState);
  }

  Future<PetState> feedWithCoin() async {
    final current = await _service.loadState();
    return _service.saveState(
      _applyExpGain(
        current.copyWith(
          energyPercent: (current.energyPercent + 10).clamp(0, 100),
        ),
        _coinFeedExpReward,
      ),
    );
  }

  Future<PetState> addOwnedItem(int itemId) async {
    final current = await _service.loadState();
    if (current.ownedItems.contains(itemId)) {
      return current;
    }

    final nextOwnedItems = [...current.ownedItems, itemId]..sort();
    return _service.saveState(
      current.copyWith(ownedItems: nextOwnedItems),
    );
  }

  Future<PetState> equipItem(int itemId) async {
    final current = await _service.loadState();
    if (!current.ownedItems.contains(itemId)) {
      throw StateError('item_not_owned');
    }

    return _service.saveState(
      current.copyWith(equippedItemId: itemId),
    );
  }

  Future<PetState> markFoodRefillReady() async {
    final current = await _service.loadState();
    if (current.foodCount > 0) {
      return current;
    }

    return _service.saveState(
      current.copyWith(
        foodCount: 1,
        clearNextFoodReadyAt: true,
      ),
    );
  }

  PetState _applyExpGain(PetState state, int gainedExp) {
    if (gainedExp <= 0) {
      return state;
    }

    var nextLevel = state.level < 1 ? 1 : state.level;
    var nextExp = state.exp + gainedExp;
    var expToNextLevel = _expRequiredForLevel(nextLevel);

    while (nextExp >= expToNextLevel) {
      nextExp -= expToNextLevel;
      nextLevel += 1;
      expToNextLevel = _expRequiredForLevel(nextLevel);
    }

    return state.copyWith(
      level: nextLevel,
      exp: nextExp,
    );
  }

  int _expRequiredForLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
    return 20 + ((safeLevel - 1) * 8);
  }
}

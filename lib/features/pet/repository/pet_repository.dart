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
    final fedState = current.copyWith(
      foodCount: nextFoodCount,
      energyPercent: (current.energyPercent + 5).clamp(0, 100),
      nextFoodReadyAt:
          nextFoodCount == 0 ? DateTime.now().add(refillDuration) : null,
      clearNextFoodReadyAt: nextFoodCount > 0,
    );
    final nextState = _applyLevelProgress(
      previousState: current,
      currentState: fedState,
      gainedExp: _freeFeedExpReward,
    );
    return _service.saveState(nextState);
  }

  Future<PetState> feedWithCoin() async {
    final current = await _service.loadState();
    final fedState = current.copyWith(
      energyPercent: (current.energyPercent + 10).clamp(0, 100),
    );
    return _service.saveState(
      _applyLevelProgress(
        previousState: current,
        currentState: fedState,
        gainedExp: _coinFeedExpReward,
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

  PetState _applyLevelProgress({
    required PetState previousState,
    required PetState currentState,
    required int gainedExp,
  }) {
    final safeCurrentLevel = currentState.level < 1 ? 1 : currentState.level;
    final nextExp = currentState.exp + (gainedExp > 0 ? gainedExp : 0);
    final didReachFullEnergy = previousState.energyPercent < 100 &&
        currentState.energyPercent >= 100;

    return currentState.copyWith(
      level: didReachFullEnergy ? safeCurrentLevel + 1 : safeCurrentLevel,
      exp: nextExp,
    );
  }
}

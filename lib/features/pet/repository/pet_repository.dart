import 'package:flutter_application_1/features/pet/model/pet_state.dart';
import 'package:flutter_application_1/features/pet/service/pet_service.dart';

class PetRepository {
  PetRepository({PetService? service}) : _service = service ?? PetService();

  final PetService _service;
  static const int _freeFeedExpReward = 10;
  static const int _coinFeedExpReward = 18;
  static const int _maxFreeFoodCount = PetState.maxFoodCount;

  Future<PetState> loadState() => _service.loadState();

  Future<PetState> feedPet({
    required Duration refillDuration,
  }) async {
    final current = await _service.loadState();
    if (current.foodCount <= 0) {
      throw StateError('out_of_food');
    }

    final nextFoodCount = current.foodCount - 1;
    final shouldScheduleRefill = nextFoodCount < _maxFreeFoodCount;
    final nextFoodReadyAt = shouldScheduleRefill
        ? (current.nextFoodReadyAt ?? DateTime.now().add(refillDuration))
        : null;

    final fedState = current.copyWith(
      foodCount: nextFoodCount,
      energyPercent: current.energyPercent + 5,
      nextFoodReadyAt: nextFoodReadyAt,
      clearNextFoodReadyAt: nextFoodReadyAt == null,
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
      energyPercent: current.energyPercent + 10,
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

  Future<PetState> unequipItem() async {
    final current = await _service.loadState();
    if (current.equippedItemId == null) {
      return current;
    }

    return _service.saveState(
      current.copyWith(clearEquippedItemId: true),
    );
  }

  Future<PetState> markFoodRefillReady({
    required Duration refillDuration,
  }) async {
    final current = await _service.loadState();
    if (current.foodCount >= _maxFreeFoodCount) {
      if (current.nextFoodReadyAt == null) {
        return current;
      }
      return _service.saveState(
        current.copyWith(
          foodCount: _maxFreeFoodCount,
          clearNextFoodReadyAt: true,
        ),
      );
    }

    final scheduledReadyAt = current.nextFoodReadyAt;
    if (scheduledReadyAt == null) {
      return _service.saveState(
        current.copyWith(
          nextFoodReadyAt: DateTime.now().add(refillDuration),
        ),
      );
    }

    final now = DateTime.now();
    if (now.isBefore(scheduledReadyAt)) {
      return current;
    }

    final refillSeconds =
        refillDuration.inSeconds <= 0 ? 1 : refillDuration.inSeconds;
    final elapsedSeconds = now.difference(scheduledReadyAt).inSeconds;
    final gainedFood = 1 + (elapsedSeconds ~/ refillSeconds);
    final nextFoodCount =
        (current.foodCount + gainedFood).clamp(0, _maxFreeFoodCount).toInt();

    if (nextFoodCount >= _maxFreeFoodCount) {
      return _service.saveState(
        current.copyWith(
          foodCount: _maxFreeFoodCount,
          clearNextFoodReadyAt: true,
        ),
      );
    }

    final nextReadyAt = scheduledReadyAt.add(
      Duration(seconds: gainedFood * refillSeconds),
    );

    return _service.saveState(
      current.copyWith(
        foodCount: nextFoodCount,
        nextFoodReadyAt: nextReadyAt,
      ),
    );
  }

  Future<PetState> alignFoodCooldown({
    required Duration refillDuration,
    PetState? baseState,
  }) async {
    final current = baseState ?? await _service.loadState();

    if (current.foodCount >= _maxFreeFoodCount) {
      if (current.nextFoodReadyAt == null) {
        return current;
      }
      return _service.saveState(
        current.copyWith(
          foodCount: _maxFreeFoodCount,
          clearNextFoodReadyAt: true,
        ),
      );
    }

    final now = DateTime.now();
    final nextFoodReadyAt = current.nextFoodReadyAt;
    if (nextFoodReadyAt == null) {
      return _service.saveState(
        current.copyWith(
          nextFoodReadyAt: now.add(refillDuration),
        ),
      );
    }

    final remaining = nextFoodReadyAt.difference(now);
    if (remaining > refillDuration) {
      return _service.saveState(
        current.copyWith(
          nextFoodReadyAt: now.add(refillDuration),
        ),
      );
    }

    return current;
  }

  PetState _applyLevelProgress({
    required PetState previousState,
    required PetState currentState,
    required int gainedExp,
  }) {
    final safeCurrentLevel = currentState.level < 1 ? 1 : currentState.level;
    final nextExp = currentState.exp + (gainedExp > 0 ? gainedExp : 0);
    final normalizedPreviousEnergy =
        previousState.energyPercent < 0 ? 0 : previousState.energyPercent;
    final normalizedCurrentEnergy =
        currentState.energyPercent < 0 ? 0 : currentState.energyPercent;
    final addedEnergy = normalizedCurrentEnergy - normalizedPreviousEnergy;
    final totalEnergy =
        normalizedPreviousEnergy + (addedEnergy < 0 ? 0 : addedEnergy);
    final levelGain = totalEnergy ~/ 100;
    final remainingEnergy = totalEnergy % 100;

    return currentState.copyWith(
      level: safeCurrentLevel + levelGain,
      energyPercent: remainingEnergy,
      exp: nextExp,
    );
  }
}

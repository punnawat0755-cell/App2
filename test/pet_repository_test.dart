import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/pet/model/pet_state.dart';
import 'package:flutter_application_1/features/pet/repository/pet_repository.dart';
import 'package:flutter_application_1/features/pet/service/pet_service.dart';

class _FakePetService extends PetService {
  _FakePetService(this._state);

  PetState _state;

  @override
  Future<PetState> loadState() async => _state;

  @override
  Future<PetState> saveState(PetState state) async {
    _state = state;
    return _state;
  }
}

void main() {
  group('PetRepository', () {
    test('feedPet adds energy and exp without leveling when exp is below cap',
        () async {
      final service = _FakePetService(PetState.initial());
      final repository = PetRepository(service: service);

      final result = await repository.feedPet(
        refillDuration: const Duration(hours: 6),
      );

      expect(result.energyPercent, 55);
      expect(result.foodCount, 2);
      expect(result.exp, 10);
      expect(result.level, 1);
      expect(result.nextFoodReadyAt, isNull);
    });

    test(
        'feedPet levels up when energy reaches 100 and starts refill timer',
        () async {
      final service = _FakePetService(
        PetState.initial().copyWith(
          level: 1,
          exp: 15,
          energyPercent: 96,
          foodCount: 1,
        ),
      );
      final repository = PetRepository(service: service);

      final beforeCall = DateTime.now();
      final result = await repository.feedPet(
        refillDuration: const Duration(hours: 6),
      );
      final afterCall = DateTime.now();

      expect(result.level, 2);
      expect(result.exp, 25);
      expect(result.energyPercent, 1);
      expect(result.foodCount, 0);
      expect(result.nextFoodReadyAt, isNotNull);
      expect(
        result.nextFoodReadyAt!.isBefore(
          beforeCall.add(const Duration(hours: 6)),
        ),
        isFalse,
      );
      expect(
        result.nextFoodReadyAt!.isAfter(
          afterCall.add(const Duration(hours: 6)),
        ),
        isFalse,
      );
    });

    test('feedWithCoin levels up only when energy reaches 100', () async {
      final service = _FakePetService(
        PetState.initial().copyWith(
          level: 2,
          exp: 20,
          energyPercent: 91,
        ),
      );
      final repository = PetRepository(service: service);

      final result = await repository.feedWithCoin();

      expect(result.level, 3);
      expect(result.exp, 38);
      expect(result.energyPercent, 1);
    });

    test('feedWithCoin does not level up if energy is below 100', () async {
      final service = _FakePetService(
        PetState.initial().copyWith(
          level: 3,
          exp: 99,
          energyPercent: 80,
        ),
      );
      final repository = PetRepository(service: service);

      final result = await repository.feedWithCoin();

      expect(result.level, 3);
      expect(result.exp, 117);
      expect(result.energyPercent, 90);
    });

    test('addOwnedItem keeps owned items unique and sorted', () async {
      final service = _FakePetService(
        PetState.initial().copyWith(ownedItems: [5, 2]),
      );
      final repository = PetRepository(service: service);

      final result = await repository.addOwnedItem(3);
      final unchanged = await repository.addOwnedItem(3);

      expect(result.ownedItems, [2, 3, 5]);
      expect(unchanged.ownedItems, [2, 3, 5]);
    });

    test('equipItem stores equipped item when item is owned', () async {
      final service = _FakePetService(
        PetState.initial().copyWith(ownedItems: [1, 4, 7]),
      );
      final repository = PetRepository(service: service);

      final result = await repository.equipItem(4);

      expect(result.equippedItemId, 4);
    });

    test('equipItem throws when item is not owned', () async {
      final service = _FakePetService(PetState.initial());
      final repository = PetRepository(service: service);

      expect(
        () => repository.equipItem(9),
        throwsA(isA<StateError>()),
      );
    });

    test('unequipItem clears equipped item when one is equipped', () async {
      final service = _FakePetService(
        PetState.initial().copyWith(
          ownedItems: [2, 5],
          equippedItemId: 5,
        ),
      );
      final repository = PetRepository(service: service);

      final result = await repository.unequipItem();

      expect(result.equippedItemId, isNull);
    });

    test('markFoodRefillReady restores one free food and clears timer',
        () async {
      final service = _FakePetService(
        PetState.initial().copyWith(
          foodCount: 0,
          nextFoodReadyAt: DateTime.now().add(const Duration(minutes: 5)),
        ),
      );
      final repository = PetRepository(service: service);

      final result = await repository.markFoodRefillReady();

      expect(result.foodCount, 1);
      expect(result.nextFoodReadyAt, isNull);
    });
  });
}

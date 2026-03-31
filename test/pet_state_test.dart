import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/pet/model/pet_state.dart';

void main() {
  group('PetState', () {
    test('fromMap reads persisted fields correctly', () {
      final state = PetState.fromMap({
        'level': 3,
        'exp': 14,
        'energy_percent': 88,
        'username': 'Nong Whale',
        'food_count': 2,
        'owned_items': [4, 1, 4],
        'equipped_item_id': 4,
        'next_food_ready_at': '2026-03-31T10:00:00.000Z',
      });

      expect(state.level, 3);
      expect(state.exp, 14);
      expect(state.energyPercent, 88);
      expect(state.username, 'Nong Whale');
      expect(state.foodCount, 2);
      expect(state.ownedItems, [1, 4]);
      expect(state.equippedItemId, 4);
      expect(state.nextFoodReadyAt, isNotNull);
    });

    test('toMap includes exp and equipped item fields', () {
      final state = PetState.initial().copyWith(
        level: 2,
        exp: 9,
        energyPercent: 77,
        foodCount: 1,
        ownedItems: [2, 5],
        equippedItemId: 5,
        nextFoodReadyAt: DateTime(2026, 3, 31, 18, 30),
      );

      final map = state.toMap();

      expect(map['level'], 2);
      expect(map['exp'], 9);
      expect(map['energy_percent'], 77);
      expect(map['food_count'], 1);
      expect(map['owned_items'], [2, 5]);
      expect(map['equipped_item_id'], 5);
      expect(map['next_food_ready_at'], isA<String>());
    });
  });
}

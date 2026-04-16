class PetState {
  const PetState({
    required this.level,
    required this.exp,
    required this.energyPercent,
    required this.username,
    required this.foodCount,
    required this.ownedItems,
    this.equippedItemId,
    this.nextFoodReadyAt,
  });

  factory PetState.initial() {
    return const PetState(
      level: 1,
      exp: 0,
      energyPercent: 50,
      username: 'Seal',
      foodCount: 3,
      ownedItems: <int>[],
      equippedItemId: null,
    );
  }

  final int level;
  final int exp;
  final int energyPercent;
  final String username;
  final int foodCount;
  final List<int> ownedItems;
  final int? equippedItemId;
  final DateTime? nextFoodReadyAt;

  factory PetState.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return PetState.initial();
    }

    return PetState(
      level: _readInt(map['level']) ?? 1,
      exp: _readInt(map['exp']) ?? 0,
      energyPercent: _readInt(map['energy_percent']) ?? 50,
      username: map['username']?.toString().trim().isNotEmpty == true
          ? map['username'].toString().trim()
          : 'Seal',
      foodCount: _readInt(map['food_count']) ?? 3,
      ownedItems: _readIntList(map['owned_items']),
      equippedItemId: _readInt(map['equipped_item_id']),
      nextFoodReadyAt: _readDateTime(map['next_food_ready_at']),
    );
  }

  PetState copyWith({
    int? level,
    int? exp,
    int? energyPercent,
    String? username,
    int? foodCount,
    List<int>? ownedItems,
    int? equippedItemId,
    DateTime? nextFoodReadyAt,
    bool clearNextFoodReadyAt = false,
    bool clearEquippedItemId = false,
  }) {
    return PetState(
      level: level ?? this.level,
      exp: exp ?? this.exp,
      energyPercent: energyPercent ?? this.energyPercent,
      username: username ?? this.username,
      foodCount: foodCount ?? this.foodCount,
      ownedItems: ownedItems ?? this.ownedItems,
      equippedItemId:
          clearEquippedItemId ? null : equippedItemId ?? this.equippedItemId,
      nextFoodReadyAt:
          clearNextFoodReadyAt ? null : nextFoodReadyAt ?? this.nextFoodReadyAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'exp': exp,
      'energy_percent': energyPercent,
      'username': username,
      'food_count': foodCount,
      'owned_items': ownedItems,
      'equipped_item_id': equippedItemId,
      'next_food_ready_at': nextFoodReadyAt?.toIso8601String(),
    };
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static List<int> _readIntList(dynamic value) {
    if (value is! List) {
      return const <int>[];
    }

    return value.map(_readInt).whereType<int>().toSet().toList()..sort();
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is DateTime) {
      return value.toLocal();
    }

    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed?.toLocal();
  }
}

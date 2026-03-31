import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/pet/model/pet_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetService {
  PetService({SupabaseClient? supabaseClient}) : _supabase = supabaseClient;

  static const _petProfilesTable = 'pet_profiles';
  static PetState? _cachedState;
  final SupabaseClient? _supabase;

  SupabaseClient get supabaseClient => _supabase ?? Supabase.instance.client;

  Future<PetState> loadState() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      final localState = _cachedState ?? PetState.initial();
      final normalized = _normalize(localState);
      _cachedState = normalized;
      return normalized;
    }

    try {
      final metadata = user.userMetadata ?? const <String, dynamic>{};
      var state = await _loadStateFromTable(user.id);
      state ??= PetState.fromMap(_readMap(metadata['pet_state']));

      final username = await _loadUsername(user.id, metadata);
      if (username.isNotEmpty) {
        state = state.copyWith(username: username);
      }

      final normalized = _normalize(state);
      _cachedState = normalized;
      return normalized;
    } catch (error) {
      debugPrint('PetService.loadState error: $error');
      final fallback = _normalize(_cachedState ?? PetState.initial());
      _cachedState = fallback;
      return fallback;
    }
  }

  Future<PetState> saveState(PetState state) async {
    final normalized = _normalize(state);
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      _cachedState = normalized;
      return normalized;
    }

    try {
      final savedToTable = await _saveStateToTable(user.id, normalized);
      if (!savedToTable) {
        final currentMetadata = Map<String, dynamic>.from(
          user.userMetadata ?? const <String, dynamic>{},
        );
        currentMetadata['pet_state'] = normalized.toMap();

        await supabaseClient.auth.updateUser(
          UserAttributes(data: currentMetadata),
        );
      }
    } catch (error) {
      debugPrint('PetService.saveState error: $error');
    }

    _cachedState = normalized;
    return normalized;
  }

  PetState _normalize(PetState state) {
    var normalized = state.copyWith(
      energyPercent: state.energyPercent.clamp(0, 100),
      foodCount: state.foodCount < 0 ? 0 : state.foodCount,
      ownedItems: state.ownedItems.toSet().toList()..sort(),
    );

    final nextFoodReadyAt = normalized.nextFoodReadyAt;
    if (normalized.foodCount == 0 &&
        nextFoodReadyAt != null &&
        !nextFoodReadyAt.isAfter(DateTime.now())) {
      normalized = normalized.copyWith(
        foodCount: 1,
        clearNextFoodReadyAt: true,
      );
    }

    return normalized;
  }

  Future<String> _loadUsername(
    String userId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final row = await supabaseClient
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .maybeSingle();
      final username = row?['username']?.toString().trim();
      if (username != null && username.isNotEmpty) {
        return username;
      }
    } catch (error) {
      debugPrint('PetService._loadUsername profiles error: $error');
    }

    final metadataCandidates = [
      metadata['username'],
      metadata['name'],
      metadata['display_name'],
      metadata['displayName'],
    ];
    for (final candidate in metadataCandidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  Future<PetState?> _loadStateFromTable(String userId) async {
    try {
      final row = await supabaseClient
          .from(_petProfilesTable)
          .select(
            'level, exp, energy_percent, food_count, owned_items, '
            'equipped_item_id, next_food_ready_at',
          )
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) {
        return null;
      }

      return PetState.fromMap(row);
    } catch (error) {
      debugPrint('PetService._loadStateFromTable error: $error');
      return null;
    }
  }

  Future<bool> _saveStateToTable(String userId, PetState state) async {
    try {
      await supabaseClient.from(_petProfilesTable).upsert({
        'user_id': userId,
        'level': state.level,
        'exp': state.exp,
        'energy_percent': state.energyPercent,
        'food_count': state.foodCount,
        'owned_items': state.ownedItems,
        'equipped_item_id': state.equippedItemId,
        'next_food_ready_at': state.nextFoodReadyAt?.toIso8601String(),
      });
      return true;
    } catch (error) {
      debugPrint('PetService._saveStateToTable error: $error');
      return false;
    }
  }

  Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), mapValue),
      );
    }
    return null;
  }
}

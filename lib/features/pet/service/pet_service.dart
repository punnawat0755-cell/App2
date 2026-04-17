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

    var saved = await _saveStateToTable(user.id, normalized);

    if (!saved) {
      saved = await _saveStateToMetadataWithRecovery(user, normalized);
    }

    if (!saved) {
      debugPrint(
        'PetService.saveState warning: unable to persist remotely, kept local cache only.',
      );
    }

    _cachedState = normalized;
    return normalized;
  }

  PetState _normalize(PetState state) {
    var normalized = state.copyWith(
      energyPercent: state.energyPercent.clamp(0, 100),
      foodCount: state.foodCount.clamp(0, PetState.maxFoodCount),
      ownedItems: state.ownedItems.toSet().toList()..sort(),
    );

    if (normalized.foodCount >= PetState.maxFoodCount &&
        normalized.nextFoodReadyAt != null) {
      normalized = normalized.copyWith(
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

  Future<void> _saveStateToMetadata(User user, PetState state) async {
    final currentMetadata = Map<String, dynamic>.from(
      user.userMetadata ?? const <String, dynamic>{},
    );
    currentMetadata['pet_state'] = state.toMap();

    await supabaseClient.auth.updateUser(
      UserAttributes(data: currentMetadata),
    );
  }

  Future<bool> _saveStateToMetadataWithRecovery(
    User user,
    PetState state,
  ) async {
    try {
      await _saveStateToMetadata(user, state);
      return true;
    } on AuthApiException catch (error) {
      if (!_isSessionNotFound(error)) {
        debugPrint('PetService._saveStateToMetadata auth error: $error');
        return false;
      }

      final refreshed = await _refreshAuthSessionSafely();
      if (!refreshed) {
        debugPrint(
          'PetService._saveStateToMetadata: session missing and refresh failed.',
        );
        return false;
      }

      final refreshedUser = supabaseClient.auth.currentUser;
      if (refreshedUser == null) {
        debugPrint(
          'PetService._saveStateToMetadata: refresh succeeded but user is null.',
        );
        return false;
      }

      try {
        await _saveStateToMetadata(refreshedUser, state);
        return true;
      } catch (retryError) {
        debugPrint('PetService._saveStateToMetadata retry error: $retryError');
        return false;
      }
    } catch (error) {
      debugPrint('PetService._saveStateToMetadata error: $error');
      return false;
    }
  }

  bool _isSessionNotFound(AuthApiException error) {
    final code = (error.code ?? '').trim().toLowerCase();
    final message = error.message.toLowerCase();
    return code == 'session_not_found' || message.contains('session_id claim');
  }

  Future<bool> _refreshAuthSessionSafely() async {
    try {
      final currentSession = supabaseClient.auth.currentSession;
      if (currentSession == null) {
        return false;
      }
      final response = await supabaseClient.auth.refreshSession();
      return response.session != null;
    } catch (error) {
      debugPrint('PetService._refreshAuthSessionSafely error: $error');
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

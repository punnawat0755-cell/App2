import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoinService extends GetxService {
  CoinService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final RxInt coins = 0.obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _supabase.auth.onAuthStateChange.listen((_) {
      loadCoins();
    });
    loadCoins();
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadCoins() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      coins.value = 0;
      return;
    }

    try {
      isLoading.value = true;
      await _supabase.rpc('ensure_my_wallet');

      final row = await _supabase
          .from('coin_wallets')
          .select('balance')
          .eq('user_id', user.id)
          .maybeSingle();

      coins.value = _parseCoins(row?['balance']) ?? 0;
    } catch (error) {
      coins.value = 0;
      Get.log('CoinService.loadCoins error: $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setCoins(int nextValue) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      coins.value = nextValue;
      return;
    }

    final normalized = nextValue < 0 ? 0 : nextValue;
    final previous = coins.value;
    coins.value = normalized;

    try {
      final delta = normalized - previous;
      if (delta == 0) return;

      await _supabase.rpc('_award_coins', params: {
        'p_user_id': user.id,
        'p_amount': delta,
        'p_reason': delta > 0 ? 'manual_adjust_add' : 'manual_adjust_deduct',
        'p_dedupe_key':
            'manual_adjust:${user.id}:${DateTime.now().microsecondsSinceEpoch}',
        'p_ref_type': 'app_client',
      });

      await loadCoins();
    } catch (error) {
      coins.value = previous;
      rethrow;
    }
  }

  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    if (coins.value < amount) return false;

    try {
      await setCoins(coins.value - amount);
      return true;
    } catch (error) {
      Get.log('CoinService.spendCoins error: $error');
      return false;
    }
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;

    try {
      await setCoins(coins.value + amount);
    } catch (error) {
      Get.log('CoinService.addCoins error: $error');
      rethrow;
    }
  }

  int? _parseCoins(dynamic rawCoins) {
    if (rawCoins is int) return rawCoins;
    if (rawCoins is num) return rawCoins.toInt();
    if (rawCoins is String) return int.tryParse(rawCoins);
    return null;
  }
}

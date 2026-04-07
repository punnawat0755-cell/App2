import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/profile/model/profile_avatar_catalog.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileAvatarController extends GetxController {
  ProfileAvatarController({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final avatarUrl = ProfileAvatarCatalog.defaultAvatar.obs;
  final isSaving = false.obs;

  StreamSubscription<AuthState>? _authSubscription;

  List<String> get avatarOptions => ProfileAvatarCatalog.assetPaths;
  ImageProvider<Object> get avatarImageProvider =>
      ProfileAvatarCatalog.providerFor(avatarUrl.value);

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _supabase.auth.onAuthStateChange.listen((_) {
      _loadAvatarForCurrentUser();
    });
    _loadAvatarForCurrentUser();
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  Future<bool> saveAvatar(String nextAvatarUrl) async {
    final user = _supabase.auth.currentUser;
    if (user == null || isSaving.value) return false;

    final normalizedAvatar = ProfileAvatarCatalog.normalize(nextAvatarUrl);
    final previousAvatar = avatarUrl.value;
    avatarUrl.value = normalizedAvatar;
    isSaving.value = true;

    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'avatarurl': normalizedAvatar,
      });
      Get.snackbar(
        'เปลี่ยนรูปโปรไฟล์แล้ว',
        'ระบบบันทึกรูปใหม่เรียบร้อย',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return true;
    } catch (error) {
      avatarUrl.value = previousAvatar;
      Get.snackbar(
        'บันทึกรูปไม่สำเร็จ',
        '$error',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _loadAvatarForCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      avatarUrl.value = ProfileAvatarCatalog.defaultAvatar;
      return;
    }

    try {
      final row = await _supabase
          .from('profiles')
          .select('avatarurl')
          .eq('id', user.id)
          .maybeSingle();

      avatarUrl.value = ProfileAvatarCatalog.normalize(
        row?['avatarurl']?.toString(),
      );
    } catch (_) {
      avatarUrl.value = ProfileAvatarCatalog.defaultAvatar;
    }
  }
}

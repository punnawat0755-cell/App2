import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/setting/service/profile_service.dart';
import 'package:get/get.dart';

class EditProfileController extends GetxController {
  EditProfileController({ProfileService? profileService})
      : _profileService = profileService ?? ProfileService();

  final ProfileService _profileService;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final bioController = TextEditingController();

  final email = ''.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    nameController.dispose();
    bioController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      final profile = await _profileService.fetchProfile();
      nameController.text = profile['displayName']?.toString() ?? '';
      bioController.text = profile['bio']?.toString() ?? '';
      email.value = profile['email']?.toString() ?? '';
    } catch (error) {
      Get.snackbar(
        'Unable to load profile',
        '$error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) {
      return false;
    }

    final trimmedName = nameController.text.trim();
    final trimmedBio = bioController.text.trim();

    try {
      isSaving.value = true;
      await _profileService.updateProfile(
        displayName: trimmedName,
        bio: trimmedBio,
      );
      nameController.text = trimmedName;
      bioController.text = trimmedBio;
      Get.snackbar(
        'Profile updated',
        'Your profile information has been saved.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (error) {
      Get.snackbar(
        'Save failed',
        '$error',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}

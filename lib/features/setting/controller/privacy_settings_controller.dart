import 'package:flutter_application_1/features/setting/service/privacy_service.dart';
import 'package:get/get.dart';

class PrivacySettingsController extends GetxController {
  PrivacySettingsController({PrivacyService? service})
      : _service = service ?? PrivacyService();

  final PrivacyService _service;

  final isLoading = false.obs;
  final privateProfile = false.obs;
  final analyticsEnabled = true.obs;
  final biometricLockEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final data = await _service.load();
    privateProfile.value = data['privateProfile'] ?? false;
    analyticsEnabled.value = data['analyticsEnabled'] ?? true;
    biometricLockEnabled.value = data['biometricLockEnabled'] ?? false;
    isLoading.value = false;
  }

  Future<void> updatePrivateProfile(bool value) async {
    privateProfile.value = value;
    await _persist();
  }

  Future<void> updateAnalytics(bool value) async {
    analyticsEnabled.value = value;
    await _persist();
  }

  Future<void> updateBiometricLock(bool value) async {
    biometricLockEnabled.value = value;
    await _persist();
  }

  Future<void> _persist() {
    return _service.save(
      privateProfile: privateProfile.value,
      analyticsEnabled: analyticsEnabled.value,
      biometricLockEnabled: biometricLockEnabled.value,
    );
  }
}

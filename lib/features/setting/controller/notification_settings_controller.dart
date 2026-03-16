import 'package:flutter_application_1/features/setting/service/notification_settings_service.dart';
import 'package:get/get.dart';

class NotificationSettingsController extends GetxController {
  NotificationSettingsController({
    NotificationSettingsService? service,
  }) : _service = service ?? NotificationSettingsService();

  final NotificationSettingsService _service;

  final isLoading = false.obs;
  final pushEnabled = true.obs;
  final messageEnabled = true.obs;
  final dailyReminderEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final data = await _service.load();
    pushEnabled.value = data['pushEnabled'] ?? true;
    messageEnabled.value = data['messageEnabled'] ?? true;
    dailyReminderEnabled.value = data['dailyReminderEnabled'] ?? false;
    isLoading.value = false;
  }

  Future<void> updatePush(bool value) async {
    pushEnabled.value = value;
    await _persist();
  }

  Future<void> updateMessage(bool value) async {
    messageEnabled.value = value;
    await _persist();
  }

  Future<void> updateDailyReminder(bool value) async {
    dailyReminderEnabled.value = value;
    await _persist();
  }

  Future<void> _persist() {
    return _service.save(
      pushEnabled: pushEnabled.value,
      messageEnabled: messageEnabled.value,
      dailyReminderEnabled: dailyReminderEnabled.value,
    );
  }
}

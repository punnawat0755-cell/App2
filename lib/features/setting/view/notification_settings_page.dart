import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/setting/controller/notification_settings_controller.dart';
import 'package:get/get.dart';

class NotificationSettingsPage
    extends GetView<NotificationSettingsController> {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationController = Get.put(NotificationSettingsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Obx(() {
        if (notificationController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SwitchCard(
              title: 'Push notifications',
              subtitle: 'General alerts about activity in your account.',
              value: notificationController.pushEnabled.value,
              onChanged: notificationController.updatePush,
            ),
            const SizedBox(height: 14),
            _SwitchCard(
              title: 'Message notifications',
              subtitle: 'Alerts when there is a new chat or direct message.',
              value: notificationController.messageEnabled.value,
              onChanged: notificationController.updateMessage,
            ),
            const SizedBox(height: 14),
            _SwitchCard(
              title: 'Daily reminders',
              subtitle: 'A gentle reminder to check in with the app each day.',
              value: notificationController.dailyReminderEnabled.value,
              onChanged: notificationController.updateDailyReminder,
            ),
          ],
        );
      }),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E7F4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF17324D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6D7B8B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

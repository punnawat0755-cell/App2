import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/setting/controller/privacy_settings_controller.dart';
import 'package:get/get.dart';

class PrivacySettingsPage extends GetView<PrivacySettingsController> {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final privacyController = Get.put(PrivacySettingsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      appBar: AppBar(
        title: const Text('Privacy'),
      ),
      body: Obx(() {
        if (privacyController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SwitchCard(
              title: 'Private profile',
              subtitle: 'Hide parts of your profile from other users.',
              value: privacyController.privateProfile.value,
              onChanged: privacyController.updatePrivateProfile,
            ),
            const SizedBox(height: 14),
            _SwitchCard(
              title: 'Usage analytics',
              subtitle: 'Allow anonymous analytics to improve the app.',
              value: privacyController.analyticsEnabled.value,
              onChanged: privacyController.updateAnalytics,
            ),
            const SizedBox(height: 14),
            _SwitchCard(
              title: 'Biometric app lock',
              subtitle: 'Require device biometrics before opening the app.',
              value: privacyController.biometricLockEnabled.value,
              onChanged: privacyController.updateBiometricLock,
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

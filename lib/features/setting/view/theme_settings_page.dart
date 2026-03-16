import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/setting/controller/theme_settings_controller.dart';
import 'package:get/get.dart';

class ThemeSettingsPage extends GetView<ThemeSettingsController> {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeSettingsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      appBar: AppBar(
        title: const Text('Theme'),
      ),
      body: Obx(() {
        if (themeController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            _ThemeModeCard(
              title: 'Follow system',
              subtitle: 'Match the device appearance settings.',
              value: 'system',
              icon: Icons.phone_android_rounded,
            ),
            SizedBox(height: 14),
            _ThemeModeCard(
              title: 'Light mode',
              subtitle: 'Bright surfaces with the default app palette.',
              value: 'light',
              icon: Icons.light_mode_rounded,
            ),
            SizedBox(height: 14),
            _ThemeModeCard(
              title: 'Dark mode',
              subtitle: 'A darker appearance for low-light environments.',
              value: 'dark',
              icon: Icons.dark_mode_rounded,
            ),
          ],
        );
      }),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeSettingsController>();

    return Obx(() {
      final selected = themeController.selectedMode.value == value;

      return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => themeController.updateMode(value),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2A6EBB)
                  : const Color(0xFFD8E7F4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2A6EBB)),
              const SizedBox(width: 14),
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
              Radio<String>(
                value: value,
                groupValue: themeController.selectedMode.value,
                onChanged: (nextValue) {
                  if (nextValue != null) {
                    themeController.updateMode(nextValue);
                  }
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}

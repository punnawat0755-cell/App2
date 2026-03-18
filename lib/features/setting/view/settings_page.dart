import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/setting/controller/settings_controller.dart';
import 'package:flutter_application_1/features/setting/view/about_app_page.dart';
import 'package:flutter_application_1/features/setting/view/app_lock_page.dart';
import 'package:flutter_application_1/features/setting/view/edit_profile_page.dart';
import 'package:flutter_application_1/features/setting/view/favorites_page.dart';
import 'package:flutter_application_1/features/setting/view/help_center_page.dart';
import 'package:flutter_application_1/features/setting/view/notification_settings_page.dart';
import 'package:flutter_application_1/features/setting/view/privacy_settings_page.dart';
import 'package:flutter_application_1/features/setting/view/theme_settings_page.dart';
import 'package:flutter_application_1/features/setting/widget/logout_dialog.dart';
import 'package:flutter_application_1/features/setting/widget/settings_menu_tile.dart';
import 'package:flutter_application_1/features/setting/widget/settings_profile_header.dart';
import 'package:get/get.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.put(SettingsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8FC),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF17324D),
          ),
        ),
      ),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: settingsController.loadProfile,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              SettingsProfileHeader(
                avatarController: settingsController.avatarController,
                displayName: settingsController.displayName.value,
                email: settingsController.email.value,
                bio: settingsController.bio.value,
                onAvatarTap: () => settingsController.pickAvatar(context),
                onEditTap: () async {
                  await Get.to(() => const EditProfilePage());
                  await settingsController.loadProfile();
                },
              ),
              const SizedBox(height: 22),
              const Text(
                'Account',
                style: TextStyle(
                  color: Color(0xFF6D7B8B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SettingsMenuTile(
                title: 'Edit profile',
                subtitle: 'Update your name, bio, and account details.',
                icon: Icons.person_outline_rounded,
                onTap: () async {
                  await Get.to(() => const EditProfilePage());
                  await settingsController.loadProfile();
                },
              ),
              const SizedBox(height: 14),
              SettingsMenuTile(
                title: 'Privacy',
                subtitle: 'Control profile visibility and app privacy options.',
                icon: Icons.lock_outline_rounded,
                onTap: () => Get.to(() => const PrivacySettingsPage()),
              ),
              const SizedBox(height: 14),
              SettingsMenuTile(
                title: 'Notifications',
                subtitle: 'Choose which alerts and reminders you want.',
                icon: Icons.notifications_none_rounded,
                onTap: () => Get.to(() => const NotificationSettingsPage()),
              ),
              const SizedBox(height: 14),
              SettingsMenuTile(
                title: 'Theme',
                subtitle: 'Switch between light, dark, or system mode.',
                icon: Icons.palette_outlined,
                onTap: () => Get.to(() => const ThemeSettingsPage()),
              ),
              const SizedBox(height: 22),
              const Text(
                'More',
                style: TextStyle(
                  color: Color(0xFF6D7B8B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SettingsMenuTile(
                title: 'Favorites',
                subtitle: 'Quick links to the parts of the app users visit most.',
                icon: Icons.favorite_border_rounded,
                onTap: () => Get.to(() => const FavoritesPage()),
              ),
              const SizedBox(height: 14),
              SettingsMenuTile(
                title: 'App lock',
                subtitle: 'Control whether the app should ask to unlock again.',
                icon: Icons.shield_outlined,
                onTap: () => Get.to(() => const AppLockPage()),
              ),
              const SizedBox(height: 14),
              SettingsMenuTile(
                title: 'Help center',
                subtitle: 'Read common answers or contact support.',
                icon: Icons.help_outline_rounded,
                onTap: () => Get.to(() => const HelpCenterPage()),
              ),
              const SizedBox(height: 14),
              SettingsMenuTile(
                title: 'About app',
                subtitle: 'See app information and a short product overview.',
                icon: Icons.info_outline_rounded,
                onTap: () => Get.to(() => const AboutAppPage()),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () async {
                  await showDialog<bool>(
                    context: context,
                    builder: (_) => LogoutDialog(
                      onConfirm: settingsController.signOut,
                    ),
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB43F3F),
                  side: const BorderSide(color: Color(0xFFF0B5B5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPage();
  }
}

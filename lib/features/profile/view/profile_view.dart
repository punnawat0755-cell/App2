import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/setting/controller/settings_controller.dart';
import 'package:flutter_application_1/features/setting/view/about_app_page.dart';
import 'package:flutter_application_1/features/setting/view/app_lock_page.dart';
import 'package:flutter_application_1/features/setting/view/edit_profile_page.dart';
import 'package:flutter_application_1/features/setting/view/favorites_page.dart';
import 'package:flutter_application_1/features/setting/view/help_center_page.dart';
import 'package:flutter_application_1/features/setting/view/privacy_settings_page.dart';
import 'package:flutter_application_1/features/setting/widget/logout_dialog.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : Get.put(SettingsController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'โปรไฟล์',
          style: GoogleFonts.mitr(
            textStyle: const TextStyle(
              color: Color(0xFF4489D7),
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: settingsController.loadProfile,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              if (settingsController.isLoading.value)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => settingsController.pickAvatar(context),
                        child: Stack(
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFCEEFFE),
                                  width: 5,
                                ),
                                image: DecorationImage(
                                  image: settingsController
                                      .avatarController.avatarImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD348),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Color(0xFF5D4037),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        settingsController.displayName.value,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mitr(
                          textStyle: const TextStyle(
                            color: Color(0xFF4489D7),
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (settingsController.email.value.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          settingsController.email.value,
                          style: const TextStyle(
                            color: Color(0xFF6D7B8B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (settingsController.bio.value.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            settingsController.bio.value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF5E6F81),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () async {
                          await Get.to(() => const EditProfilePage());
                          await settingsController.loadProfile();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF5CD9FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.person_outline_rounded),
                        label: const Text('แก้ไขโปรไฟล์'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _ProfileMenuItem(
                  leading: Image.asset('assets/images/person.png'),
                  title: 'แก้ไขข้อมูล',
                  onTap: () async {
                    await Get.to(() => const EditProfilePage());
                    await settingsController.loadProfile();
                  },
                ),
                const SizedBox(height: 16),
                _ProfileMenuItem(
                  leading: Image.asset('assets/images/lock.png'),
                  title: 'ความเป็นส่วนตัว',
                  onTap: () => Get.to(() => const PrivacySettingsPage()),
                ),
                const SizedBox(height: 16),
                _ProfileMenuItem(
                  leading: Image.asset('assets/images/heart.png'),
                  title: 'รายการโปรด',
                  onTap: () => Get.to(() => const FavoritesPage()),
                ),
                const SizedBox(height: 16),
                _ProfileMenuItem(
                  leading: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF4489D7),
                    size: 28,
                  ),
                  title: 'ล็อกแอป',
                  onTap: () => Get.to(() => const AppLockPage()),
                ),
                const SizedBox(height: 16),
                _ProfileMenuItem(
                  leading: const Icon(
                    Icons.help_outline_rounded,
                    color: Color(0xFF4489D7),
                    size: 28,
                  ),
                  title: 'ช่วยเหลือ',
                  onTap: () => Get.to(() => const HelpCenterPage()),
                ),
                const SizedBox(height: 16),
                _ProfileMenuItem(
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF4489D7),
                    size: 28,
                  ),
                  title: 'เกี่ยวกับแอป',
                  onTap: () => Get.to(() => const AboutAppPage()),
                ),
                const SizedBox(height: 24),
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
                  label: const Text('ออกจากระบบ'),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.leading,
    required this.title,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCEEFFE).withAlpha(204),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 5,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: SizedBox(
          width: 36,
          height: 36,
          child: FittedBox(
            fit: BoxFit.contain,
            child: leading,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.mitr(
            textStyle: const TextStyle(
              color: Color(0xFF4489D7),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color(0xFF757575),
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: onTap,
      ),
    );
  }
}

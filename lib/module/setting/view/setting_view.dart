import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/profile/controller/profile_avatar_controller.dart';
import 'package:flutter_application_1/module/login/view/login_view.dart';
import 'package:flutter_application_1/module/policy/view/policy_view.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'favorites_view.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileAvatarController avatarController =
        Get.isRegistered<ProfileAvatarController>()
            ? Get.find<ProfileAvatarController>()
            : Get.put(ProfileAvatarController());
    final displayName = _resolveDisplayName();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 40,
        titleSpacing: 2,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/back.png',
                width: 25,
                height: 25,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        title: const Text(
          'การตั้งค่า',
          style: TextStyle(
            color: Color(0xFF4489D7),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Obx(
                  () => Column(
                    children: [
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: () => _showAvatarPicker(context, avatarController),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: avatarController.avatarImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4489D7),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        avatarController.isSaving.value
                            ? 'กำลังบันทึกรูปโปรไฟล์...'
                            : 'แตะรูปเพื่อเปลี่ยนรูปโปรไฟล์',
                        style: const TextStyle(
                          color: Color(0xFF8A8A8A),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildSettingItem(
                        Image.asset('assets/images/person.png'),
                        'แก้ไขโปรไฟล์',
                        () => _showAvatarPicker(context, avatarController),
                      ),
                      const SizedBox(height: 20),
                      _buildSettingItem(
                        Image.asset('assets/images/lock.png'),
                        'ความเป็นส่วนตัว',
                        () => Get.to(() => const PrivacyDetailPage()),
                      ),
                      const SizedBox(height: 20),
                      _buildSettingItem(
                        Image.asset('assets/images/heart.png'),
                        'รายการโปรด',
                        () => Get.to(() => const FavoritesPage()),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _signOut(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ออกจากระบบ',
                    style: TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset('assets/images/exit.png', width: 24, height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAvatarPicker(
    BuildContext context,
    ProfileAvatarController controller,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Obx(
              () {
                final selectedAvatar = controller.avatarUrl.value;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'เลือกรูปโปรไฟล์',
                      style: TextStyle(
                        color: Color(0xFF4489D7),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'เลือกได้เฉพาะรูปที่แอปมีให้',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.avatarOptions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        final avatarPath = controller.avatarOptions[index];
                        final isSelected = selectedAvatar == avatarPath;

                        return GestureDetector(
                          onTap: () async {
                            await controller.saveAvatar(avatarPath);
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4489D7)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircleAvatar(
                                  backgroundImage: AssetImage(avatarPath),
                                ),
                                if (isSelected)
                                  const Align(
                                    alignment: Alignment.bottomRight,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Color(0xFF4489D7),
                                      child: Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Get.offAll(() => const LoginPage());
    }
  }

  String _resolveDisplayName() {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final candidates = [
      metadata['username'],
      metadata['name'],
      metadata['display_name'],
      user?.email?.split('@').first,
    ];

    for (final value in candidates) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    return 'Seal';
  }

  Widget _buildSettingItem(
    Widget leading,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCEEFFE),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: SizedBox(width: 50, height: 50, child: leading),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4489D7),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Transform.flip(
          flipX: true,
          child: Image.asset(
            'assets/images/back.png',
            width: 20,
            height: 20,
            color: const Color(0xFF757575),
            fit: BoxFit.contain,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
}

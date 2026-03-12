import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/profile/controller/profile_avatar_controller.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        titleSpacing: -8,
        leading: IconButton(
          icon: Image.asset(
            'assets/images/back.png',
            width: 25,
            height: 25,
            fit: BoxFit.contain,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'การตั้งค่า',
          style: GoogleFonts.mitr(
            textStyle: const TextStyle(
              color: Color(0xFF4489D7),
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      body: Center(
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
                            border: Border.all(color: Colors.white, width: 2),
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
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: GoogleFonts.mitr(
                    textStyle: const TextStyle(
                      color: Color(0xFF4489D7),
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  avatarController.isSaving.value
                      ? 'กำลังบันทึกรูปโปรไฟล์...'
                      : 'แตะรูปเพื่อเปลี่ยนรูปโปรไฟล์',
                  style: GoogleFonts.mitr(
                    textStyle: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildSettingItem(
                  Image.asset('assets/images/person.png'),
                  'แก้ไขข้อมูล',
                ),
                const SizedBox(height: 20),
                _buildSettingItem(
                  Image.asset('assets/images/lock.png'),
                  'ความเป็นส่วนตัว',
                ),
                const SizedBox(height: 20),
                _buildSettingItem(
                  Image.asset('assets/images/heart.png'),
                  'รายการโปรด',
                ),
              ],
            ),
          ),
        ),
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
                    Text(
                      'เลือกรูปโปรไฟล์',
                      style: GoogleFonts.mitr(
                        textStyle: const TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'เลือกได้เฉพาะรูปที่แอปมีให้',
                      style: GoogleFonts.mitr(
                        textStyle: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 14,
                        ),
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

  Widget _buildSettingItem(Widget leading, String title) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCEEFFE).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: leading,
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
        onTap: () {},
      ),
    );
  }
}

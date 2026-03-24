import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/features/login/view/login_page.dart';
import 'package:flutter_application_1/features/profile/controller/profile_avatar_controller.dart';
import 'package:flutter_application_1/features/login/view/privacy_policy_page.dart';
import 'package:flutter_application_1/features/setting/view/edit_profile_page.dart';
import 'package:flutter_application_1/features/setting/view/favorites_page.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String _displayName = 'Seal';
  bool _isLoadingDisplayName = true;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _displayName = 'Seal';
        _isLoadingDisplayName = false;
      });
      return;
    }

    try {
      final row = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();

      final metadata = user.userMetadata ?? const <String, dynamic>{};
      final nextName = _firstNonEmpty([
            row?['username'],
            metadata['username'],
            metadata['name'],
            metadata['display_name'],
            user.email?.split('@').first,
          ]) ??
          'Seal';

      if (!mounted) {
        return;
      }

      setState(() {
        _displayName = nextName;
        _isLoadingDisplayName = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _displayName = _firstNonEmpty([
              user.userMetadata?['username'],
              user.userMetadata?['name'],
              user.userMetadata?['display_name'],
              user.email?.split('@').first,
            ]) ??
            'Seal';
        _isLoadingDisplayName = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _supabase.auth.signOut();
      await FirebaseAuth.instance.signOut();

      if (!mounted) {
        return;
      }

      Get.offAll(() => const LoginPage());
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ออกจากระบบไม่สำเร็จ: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    final ProfileAvatarController avatarController =
        Get.isRegistered<ProfileAvatarController>()
            ? Get.find<ProfileAvatarController>()
            : Get.put(ProfileAvatarController());

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: -8,
        leading: IconButton(
          icon: Image.asset(
            'assets/images/back.png',
            width: scale.rs(25, min: 21, max: 25),
            height: scale.rs(25, min: 21, max: 25),
            fit: BoxFit.contain,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'การตั้งค่า',
          style: GoogleFonts.mitr(
            textStyle: TextStyle(
              color: Color(0xFF4489D7),
              fontSize: scale.rf(22, min: 19, max: 22),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pageScale = ResponsiveScale.fromWidth(constraints.maxWidth);
            final horizontalPadding = constraints.maxWidth < 360
                ? pageScale.rs(16, min: 14, max: 18)
                : pageScale.rs(24, min: 20, max: 24);
            final avatarSize = pageScale.rs(150, min: 118, max: 150);
            final avatarEditPadding = pageScale.rs(8, min: 6, max: 8);
            final avatarEditIconSize = pageScale.rs(18, min: 15, max: 18);
            final avatarEditBorder = pageScale.rs(2, min: 1.5, max: 2.4);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    pageScale.rs(24, min: 18, max: 24),
                    horizontalPadding,
                    pageScale.rs(28, min: 22, max: 28),
                  ),
                  child: Obx(
                    () => Column(
                      children: [
                        SizedBox(height: pageScale.rs(16, min: 12, max: 16)),
                        GestureDetector(
                          onTap: () =>
                              _showAvatarPicker(context, avatarController),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: avatarSize,
                                height: avatarSize,
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
                                  padding: EdgeInsets.all(avatarEditPadding),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4489D7),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: avatarEditBorder,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: avatarEditIconSize,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: pageScale.rs(16, min: 12, max: 16)),
                        Text(
                          _isLoadingDisplayName ? '...' : _displayName,
                          style: GoogleFonts.mitr(
                            textStyle: TextStyle(
                              color: Color(0xFF4489D7),
                              fontSize: scale.rf(22, min: 19, max: 22),
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
                            textStyle: TextStyle(
                              color: Color(0xFF757575),
                              fontSize: pageScale.rf(15, min: 13, max: 15),
                            ),
                          ),
                        ),
                        SizedBox(height: pageScale.rs(30, min: 22, max: 30)),
                        _buildSettingItem(
                          context,
                          Image.asset('assets/images/person.png'),
                          'แก้ไขข้อมูล',
                          () async {
                            final shouldRefresh = await Get.to<bool>(
                                () => const EditProfilePage());
                            if (shouldRefresh == true) {
                              await _loadDisplayName();
                            }
                          },
                        ),
                        SizedBox(height: pageScale.rs(20, min: 14, max: 20)),
                        _buildSettingItem(
                          context,
                          Image.asset('assets/images/lock.png'),
                          'ความเป็นส่วนตัว',
                          () => Get.to(() => const PrivacyDetailPage()),
                        ),
                        SizedBox(height: pageScale.rs(20, min: 14, max: 20)),
                        _buildSettingItem(
                          context,
                          Image.asset('assets/images/heart.png'),
                          'รายการโปรด',
                          () => Get.to(() => const FavoritesPage()),
                        ),
                        SizedBox(height: pageScale.rs(56, min: 36, max: 56)),
                        _buildLogoutButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
              final crossAxisCount = constraints.maxWidth < 360 ? 3 : 4;
              final gridSpacing = scale.rs(14, min: 10, max: 14);

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  scale.rs(20, min: 16, max: 20),
                  scale.rs(20, min: 16, max: 20),
                  scale.rs(20, min: 16, max: 20),
                  scale.rs(24, min: 18, max: 24),
                ),
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
                            textStyle: TextStyle(
                              color: const Color(0xFF4489D7),
                              fontSize: scale.rf(22, min: 18, max: 22),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: scale.rs(6, min: 4, max: 6)),
                        Text(
                          'เลือกได้เฉพาะรูปที่แอปมีให้',
                          style: GoogleFonts.mitr(
                            textStyle: TextStyle(
                              color: const Color(0xFF757575),
                              fontSize: scale.rf(14, min: 12, max: 14),
                            ),
                          ),
                        ),
                        SizedBox(height: scale.rs(18, min: 12, max: 18)),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.avatarOptions.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: gridSpacing,
                            mainAxisSpacing: gridSpacing,
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
                                    width: scale.rs(3, min: 2, max: 3),
                                  ),
                                ),
                                padding:
                                    EdgeInsets.all(scale.rs(4, min: 2, max: 4)),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: AssetImage(avatarPath),
                                    ),
                                    if (isSelected)
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: CircleAvatar(
                                          radius:
                                              scale.rs(12, min: 10, max: 12),
                                          backgroundColor:
                                              const Color(0xFF4489D7),
                                          child: Icon(
                                            Icons.check,
                                            size:
                                                scale.rs(14, min: 12, max: 14),
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
              );
            },
          ),
        );
      },
    );
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  Widget _buildSettingItem(
    BuildContext context,
    Widget leading,
    String title,
    VoidCallback onTap,
  ) {
    final scale = context.responsive;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCEEFFE).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(scale.rs(25, min: 18, max: 25)),
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
          width: scale.rs(50, min: 40, max: 50),
          height: scale.rs(50, min: 40, max: 50),
          child: leading,
        ),
        title: Text(
          title,
          style: GoogleFonts.mitr(
            textStyle: TextStyle(
              color: const Color(0xFF4489D7),
              fontSize: scale.rf(18, min: 15, max: 18),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: const Color(0xFF757575),
          size: scale.rs(20, min: 16, max: 20),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: scale.rs(20, min: 14, max: 20),
          vertical: scale.rs(8, min: 4, max: 8),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final scale = context.responsive;

    return InkWell(
      borderRadius: BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
      onTap: _handleLogout,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: scale.rs(12, min: 8, max: 12),
          vertical: scale.rs(10, min: 8, max: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ออกจากระบบ',
              style: GoogleFonts.mitr(
                textStyle: TextStyle(
                  color: const Color(0xFF9E9E9E),
                  fontSize: scale.rf(18, min: 15, max: 18),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: scale.rs(12, min: 8, max: 12)),
            Image.asset(
              'assets/images/exit.png',
              width: scale.rs(34, min: 26, max: 34),
              height: scale.rs(34, min: 26, max: 34),
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

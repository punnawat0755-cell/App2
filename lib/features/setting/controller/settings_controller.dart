import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/login/view/login.dart';
import 'package:flutter_application_1/features/profile/controller/profile_avatar_controller.dart';
import 'package:flutter_application_1/features/setting/service/profile_service.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsController extends GetxController {
  SettingsController({
    ProfileService? profileService,
    SupabaseClient? supabaseClient,
  })  : _profileService = profileService ?? ProfileService(),
        _supabase = supabaseClient ?? Supabase.instance.client;

  final ProfileService _profileService;
  final SupabaseClient _supabase;

  late final ProfileAvatarController avatarController;

  final isLoading = false.obs;
  final displayName = 'Seal'.obs;
  final email = ''.obs;
  final bio = ''.obs;

  @override
  void onInit() {
    super.onInit();
    avatarController = Get.isRegistered<ProfileAvatarController>()
        ? Get.find<ProfileAvatarController>()
        : Get.put(ProfileAvatarController());
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      isLoading.value = true;
      final profile = await _profileService.fetchProfile();
      displayName.value = profile['displayName']?.toString() ?? 'Seal';
      email.value = profile['email']?.toString() ?? '';
      bio.value = profile['bio']?.toString() ?? '';
    } catch (error) {
      Get.snackbar(
        'Profile unavailable',
        '$error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    Get.offAll(() => const LoginPage());
  }

  Future<void> pickAvatar(BuildContext context) async {
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
                final selectedAvatar = avatarController.avatarUrl.value;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose avatar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E4A77),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pick one of the in-app profile avatars.',
                      style: TextStyle(
                        color: Color(0xFF6D7B8B),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: avatarController.avatarOptions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        final avatarPath = avatarController.avatarOptions[index];
                        final isSelected = selectedAvatar == avatarPath;

                        return GestureDetector(
                          onTap: () async {
                            await avatarController.saveAvatar(avatarPath);
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
    await loadProfile();
  }
}

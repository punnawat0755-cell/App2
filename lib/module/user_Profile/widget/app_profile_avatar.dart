import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/user_Profile/app_user_controller.dart';
import 'package:get/get.dart';

class AppProfileAvatar extends StatelessWidget {
  const AppProfileAvatar({
    super.key,
    required this.radius,
    this.borderWidth = 2,
    this.borderColor = Colors.white,
    this.showNotificationDot = false,
    this.onTap,
  });

  final double radius;
  final double borderWidth;
  final Color borderColor;
  final bool showNotificationDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<AppUserController>()
        ? Get.find<AppUserController>()
        : Get.put(AppUserController(), permanent: true);

    Widget avatar = Obx(() {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: borderWidth),
              image: DecorationImage(
                image: controller.avatarImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (showNotificationDot && controller.hasNewNotification.value)
            Positioned(
              top: -4,
              right: -5,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFEE6855),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      );
    });

    if (onTap == null) return avatar;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: avatar,
    );
  }
}

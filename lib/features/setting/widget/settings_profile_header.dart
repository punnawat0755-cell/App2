import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/profile/controller/profile_avatar_controller.dart';

class SettingsProfileHeader extends StatelessWidget {
  const SettingsProfileHeader({
    super.key,
    required this.avatarController,
    required this.displayName,
    required this.email,
    required this.bio,
    required this.onAvatarTap,
    required this.onEditTap,
  });

  final ProfileAvatarController avatarController;
  final String displayName;
  final String email;
  final String bio;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E5A96),
            Color(0xFF4F9BE6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33255D96),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 34,
                    backgroundImage: avatarController.avatarImageProvider,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC857),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Color(0xFF17324D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFFD7EAFF),
                    fontSize: 13,
                  ),
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFEAF4FF),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onEditTap,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E5A96),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Edit profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

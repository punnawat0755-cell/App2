import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/chat/userchat/services/chat_user_service.dart';
import 'package:flutter_application_1/chat/userchat/views/chat_user_view.dart';

const Color _namPrimary = Color(0xFF5CD9FF);
const Color _namPrimaryDark = Color(0xFF4489D7);
const Color _namBackground = Color(0xFFEFFBFF);

class UserListScreen extends StatefulWidget {
  final String currentUserId;

  const UserListScreen({super.key, required this.currentUserId});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ChatUserService _chatService = ChatUserService();

  String _safeName(dynamic username) {
    if (username is String) {
      return username;
    }
    if (username is Map && username.isNotEmpty) {
      final value = username.values.first;
      if (value is String) {
        return value;
      }
    }
    return 'Unknown User';
  }

  String _safeImageUrl(dynamic image) {
    if (image is String && image.trim().isNotEmpty) {
      return image;
    }
    return '';
  }

  Future<void> _openChat(QueryDocumentSnapshot user) async {
    final chatRoomId =
        await _chatService.createChatRoom(widget.currentUserId, user.id);
    if (!mounted) {
      return;
    }

    final data = user.data() as Map<String, dynamic>;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatUserView(
          chatId: chatRoomId,
          currentUserId: widget.currentUserId,
          recipientUserId: user.id,
          nameUser: _safeName(data['username']),
          emailUser: (data['email'] ?? '') as String,
          imgUser: _safeImageUrl(data['img']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _namBackground,
      appBar: AppBar(
        title: const Text('แชท NAM'),
        centerTitle: true,
        backgroundColor: _namPrimary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .where(FieldPath.documentId, isNotEqualTo: widget.currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ยังไม่พบผู้ใช้อื่น'));
          }

          final users = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final chatId =
                  ([widget.currentUserId, user.id]..sort()).join('_');

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, latestSnapshot) {
                  final latest = latestSnapshot.data?.docs.firstOrNull;
                  final latestData = latest?.data() as Map<String, dynamic>?;
                  final latestText = (latestData?['text'] ?? '') as String;
                  final isUnread = latestData != null &&
                      latestData['senderId'] != widget.currentUserId &&
                      (latestData['isRead'] ?? false) == false;

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _openChat(user),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isUnread
                                ? _namPrimary.withValues(alpha: 0.8)
                                : Colors.grey.withValues(alpha: 0.2),
                            width: isUnread ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _namPrimaryDark.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: _namBackground,
                              backgroundImage:
                                  _safeImageUrl(data['img']).isNotEmpty
                                      ? NetworkImage(_safeImageUrl(data['img']))
                                      : null,
                              child: _safeImageUrl(data['img']).isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _safeName(data['username']),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isUnread
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: _namPrimaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    latestText.isNotEmpty
                                        ? latestText
                                        : 'เริ่มบทสนทนา',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          Colors.black.withValues(alpha: 0.65),
                                      fontWeight: isUnread
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: _namPrimaryDark,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
//
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/chat/userchat/services/ChatUserService.dart';
import 'package:flutter_application_1/chat/userchat/views/ChatUserView.dart';

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
      appBar: AppBar(title: const Text('Chat')),
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
            return const Center(child: Text('No users found'));
          }

          final users = snapshot.data!.docs;

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
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

                  return ListTile(
                    onTap: () => _openChat(user),
                    leading: CircleAvatar(
                      backgroundImage: _safeImageUrl(data['img']).isNotEmpty
                          ? NetworkImage(_safeImageUrl(data['img']))
                          : null,
                      child: _safeImageUrl(data['img']).isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      _safeName(data['username']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    subtitle: latestText.isNotEmpty
                        ? Text(
                            latestText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          )
                        : const Text('Start conversation'),
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

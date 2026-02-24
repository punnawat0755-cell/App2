import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/chat/userchat/services/chat_user_service.dart';

const Color _namPrimary = Color(0xFF5CD9FF);
const Color _namPrimaryDark = Color(0xFF4489D7);
const Color _namBackground = Color(0xFFEFFBFF);

class ChatUserView extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String recipientUserId;
  final String nameUser;
  final String emailUser;
  final String imgUser;

  const ChatUserView({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.recipientUserId,
    required this.nameUser,
    required this.emailUser,
    required this.imgUser,
  });

  @override
  State<ChatUserView> createState() => _ChatUserViewState();
}

class _ChatUserViewState extends State<ChatUserView> {
  final TextEditingController _messageController = TextEditingController();
  final ChatUserService _chatService = ChatUserService();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead(List<QueryDocumentSnapshot> messages) async {
    for (final message in messages) {
      final data = message.data() as Map<String, dynamic>;
      final isRead = (data['isRead'] ?? false) as bool;
      final senderId = (data['senderId'] ?? '') as String;

      if (!isRead && senderId != widget.currentUserId) {
        FirebaseFirestore.instance
            .collection('Chats')
            .doc(widget.chatId)
            .collection('messages')
            .doc(message.id)
            .update({'isRead': true});
      }
    }
  }

  Future<void> _showMessageActions({
    required bool isMe,
    required String messageId,
    required String text,
  }) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy message'),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete message',
                    style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );

    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message copied')),
      );
    } else if (action == 'delete') {
      await _chatService.deleteMessage(widget.chatId, messageId);
    }
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Today';
    }
    if (date.year == now.year) {
      return DateFormat('E, dd MMM').format(date);
    }
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _namBackground,
      appBar: AppBar(
        backgroundColor: _namPrimary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: widget.imgUser.trim().isNotEmpty
                  ? NetworkImage(widget.imgUser)
                  : null,
              child: widget.imgUser.trim().isEmpty
                  ? const Icon(Icons.person, color: _namPrimaryDark)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.nameUser,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    widget.emailUser,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                final messages = snapshot.data!.docs;
                _markAsRead(messages);

                final groupedMessages = <String, List<QueryDocumentSnapshot>>{};
                for (final message in messages) {
                  final data = message.data() as Map<String, dynamic>;
                  final timestamp = data['timestamp'];
                  if (timestamp is! Timestamp) {
                    continue;
                  }
                  final date = timestamp.toDate();
                  final key = DateFormat('yyyy-MM-dd').format(date);
                  groupedMessages.putIfAbsent(key, () => []).add(message);
                }

                final dateKeys = groupedMessages.keys.toList()..sort();

                return ListView.builder(
                  reverse: false,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  itemCount: dateKeys.length,
                  itemBuilder: (context, index) {
                    final dateKey = dateKeys[index];
                    final date = DateTime.parse(dateKey);
                    final dateMessages = groupedMessages[dateKey] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _namPrimary.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _formatDateLabel(date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: _namPrimaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        ...dateMessages.map((message) {
                          final data = message.data() as Map<String, dynamic>;
                          final text = (data['text'] ?? '') as String;
                          final senderId = (data['senderId'] ?? '') as String;
                          final isMe = senderId == widget.currentUserId;
                          final isRead = (data['isRead'] ?? false) as bool;

                          final timestamp = data['timestamp'];
                          final timeText = timestamp is Timestamp
                              ? DateFormat('HH:mm').format(timestamp.toDate())
                              : '--:--';

                          return GestureDetector(
                            onLongPress: () => _showMessageActions(
                              isMe: isMe,
                              messageId: message.id,
                              text: text,
                            ),
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.only(
                                  top: 4,
                                  bottom: 4,
                                  left: isMe ? 60 : 0,
                                  right: isMe ? 0 : 60,
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: text == '👍'
                                            ? Colors.transparent
                                            : (isMe
                                                ? _namPrimary
                                                : Colors.white),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: text == '👍'
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: _namPrimaryDark
                                                      .withValues(alpha: 0.08),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                      ),
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          fontSize: text == '👍' ? 36 : 14,
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          timeText,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black45,
                                          ),
                                        ),
                                        if (isMe)
                                          Text(
                                            isRead ? '  Read' : '',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _namPrimaryDark.withValues(
                                                  alpha: 0.8),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _namPrimaryDark.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) async {
                        await _chatService.sendMessage(
                          widget.chatId,
                          widget.currentUserId,
                          _messageController.text,
                          _messageController,
                          widget.recipientUserId,
                        );
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: _namPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () async {
                      if (_messageController.text.trim().isNotEmpty) {
                        await _chatService.sendMessage(
                          widget.chatId,
                          widget.currentUserId,
                          _messageController.text,
                          _messageController,
                          widget.recipientUserId,
                        );
                      } else {
                        await _chatService.sendMessage(
                          widget.chatId,
                          widget.currentUserId,
                          '👍',
                          _messageController,
                          widget.recipientUserId,
                        );
                      }
                      setState(() {});
                    },
                    color: Colors.white,
                    icon: Icon(
                      _messageController.text.trim().isNotEmpty
                          ? Icons.send
                          : Icons.thumb_up_alt_outlined,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/chat/userchat/models/usermessage.model.dart';

class ChatUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserMessage?> getLatestMessageStream(String chatId) {
    return _firestore
        .collection('Chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = snapshot.docs.first.data();
      final timestamp = data['timestamp'];
      if (timestamp is! Timestamp) {
        return null;
      }

      return UserMessage(
        senderId: (data['senderId'] ?? '') as String,
        text: (data['text'] ?? '') as String,
        timestamp: timestamp.toDate(),
        isRead: (data['isRead'] ?? false) as bool,
      );
    });
  }

  Future<String> createChatRoom(
    String currentUserId,
    String recipientUserId,
  ) async {
    final users = [currentUserId, recipientUserId]..sort();
    final chatRoomId = users.join('_');

    await _firestore.collection('Chats').doc(chatRoomId).set({
      'users': users,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatRoomId;
  }

  Future<void> sendMessage(
    String chatId,
    String currentUserId,
    String message,
    TextEditingController messageController,
    String recipientUserId,
  ) async {
    final text = message.trim();
    if (text.isEmpty) {
      return;
    }

    await _firestore
        .collection('Chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'receiverId': recipientUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    messageController.clear();
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('Chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
}

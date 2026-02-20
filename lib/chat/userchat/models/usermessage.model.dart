import 'package:cloud_firestore/cloud_firestore.dart';

class UserMessage {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  UserMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isRead,
  });

  factory UserMessage.fromFirestore(Map<String, dynamic> data) {
    return UserMessage(
        senderId: data['senderId'] as String,
        text: data['text'] as String,
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        isRead: data['isRead']);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/chat/userchat/models/usermessage.model.dart';

class ChatUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _chatCollection = 'Chats';
  static const String _queueCollection = 'RandomQueue';

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

    await _firestore.collection(_chatCollection).doc(chatRoomId).set({
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
        .collection(_chatCollection)
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
        .collection(_chatCollection)
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> enterRandomQueue(
    String userId, {
    required MatchRole role,
  }) async {
    await _firestore.collection(_queueCollection).doc(userId).set({
      'uid': userId,
      'status': 'waiting',
      'mode': role.value,
      'chatId': null,
      'matchedWith': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> leaveRandomQueue(String userId) async {
    await _firestore.collection(_queueCollection).doc(userId).set({
      'status': 'idle',
      'mode': null,
      'chatId': null,
      'matchedWith': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String? _extractChatId(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final status = (data['status'] ?? '') as String;
    if (status != 'matched') {
      return null;
    }
    final chatId = data['chatId'];
    return chatId is String && chatId.isNotEmpty ? chatId : null;
  }

  Stream<String?> watchMatchedChatId(String userId) {
    return _firestore.collection(_queueCollection).doc(userId).snapshots().map(
          (snap) => _extractChatId(snap.data()),
        );
  }

  Future<String?> tryMatchWithWaitingUser(
    String userId, {
    required MatchRole role,
  }) async {
    final myRef = _firestore.collection(_queueCollection).doc(userId);
    final now = DateTime.now();
    final activeThreshold = now.subtract(const Duration(seconds: 25));
    final targetMode = role.target.value;

    for (var attempt = 0; attempt < 5; attempt++) {
      final waiting = await _firestore
          .collection(_queueCollection)
          .where('status', isEqualTo: 'waiting')
          .where('mode', isEqualTo: targetMode)
          .limit(50)
          .get();

      if (waiting.docs.isEmpty) {
        return null;
      }

      QueryDocumentSnapshot<Map<String, dynamic>>? candidate;
      for (final doc in waiting.docs) {
        if (doc.id == userId) {
          continue;
        }

        final data = doc.data();
        final updatedAt = data['updatedAt'];
        if (updatedAt is Timestamp &&
            updatedAt.toDate().isBefore(activeThreshold)) {
          continue;
        }

        if (updatedAt == null || updatedAt is Timestamp) {
          candidate = doc;
          break;
        }
      }

      if (candidate == null) {
        return null;
      }

      final otherUserId = candidate.id;
      final otherRef = _firestore.collection(_queueCollection).doc(otherUserId);
      final pair = [userId, otherUserId];
      final chatId = _newRandomChatId();
      final chatRef = _firestore.collection(_chatCollection).doc(chatId);

      try {
        await _firestore.runTransaction((tx) async {
          final mySnap = await tx.get(myRef);
          final otherSnap = await tx.get(otherRef);

          final myData = mySnap.data();
          final otherData = otherSnap.data();
          final myStatus = (myData?['status'] ?? '') as String;
          final otherStatus = (otherData?['status'] ?? '') as String;
          final myMode = (myData?['mode'] ?? '') as String;
          final otherMode = (otherData?['mode'] ?? '') as String;

          if (myStatus != 'waiting' || otherStatus != 'waiting') {
            throw StateError('queue changed');
          }
          if (myMode != role.value || otherMode != targetMode) {
            throw StateError('queue changed');
          }

          tx.set(
              chatRef,
              {
                'users': pair,
                'isRandom': true,
                'matchType': 'seeker_counselor',
                'randomState': 'active',
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));

          tx.set(
              myRef,
              {
                'status': 'matched',
                'mode': role.value,
                'chatId': chatId,
                'matchedWith': otherUserId,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));

          tx.set(
              otherRef,
              {
                'status': 'matched',
                'mode': targetMode,
                'chatId': chatId,
                'matchedWith': userId,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));
        });

        return chatId;
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  Future<void> endRandomChat({
    required String chatId,
    required String endedByUserId,
  }) async {
    final chatRef = _firestore.collection(_chatCollection).doc(chatId);
    final chatSnap = await chatRef.get();
    final data = chatSnap.data();
    final users =
        (data?['users'] as List<dynamic>? ?? []).whereType<String>().toList();

    await _deleteAllMessages(chatId);

    final batch = _firestore.batch();
    batch.delete(chatRef);
    for (final uid in users) {
      final queueRef = _firestore.collection(_queueCollection).doc(uid);
      batch.set(
          queueRef,
          {
            'status': 'idle',
            'mode': null,
            'chatId': null,
            'matchedWith': null,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }
    await batch.commit();
  }

  String _newRandomChatId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts ^ (ts >> 7)).toRadixString(36);
    return 'random_${ts}_$rand';
  }

  Future<void> _deleteAllMessages(String chatId) async {
    const batchSize = 350;
    while (true) {
      final snap = await _firestore
          .collection(_chatCollection)
          .doc(chatId)
          .collection('messages')
          .limit(batchSize)
          .get();

      if (snap.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}

enum MatchRole {
  seeker('seeker'),
  counselor('counselor');

  const MatchRole(this.value);
  final String value;

  MatchRole get target =>
      this == MatchRole.seeker ? MatchRole.counselor : MatchRole.seeker;
}

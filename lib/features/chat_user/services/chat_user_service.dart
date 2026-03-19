import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_application_1/core/services/content_moderation_service.dart';
import 'package:flutter_application_1/features/chat_user/models/usermessage.model.dart';

/// สถานะผลลัพธ์หลังการพยายามส่งข้อความจาก UI
enum SendMessageStatus { sent, blocked, skipped }

/// รูปแบบผลลัพธ์ที่ service ส่งกลับให้ UI
class SendMessageResult {
  const SendMessageResult({
    required this.status,
    this.reason,
  });

  final SendMessageStatus status;
  final String? reason;
}

/// บทบาทผู้ใช้ในระบบจับคู่
/// - `counselor` map เป็น `listener` เพื่อรองรับชื่อบทบาทเดิม
enum MatchRole {
  seeker('seeker'),
  listener('listener'), // ใน DB ใช้คำว่า listener
  counselor(
      'listener'); // เผื่อ Controller ส่ง counselor มา ให้ค่าเป็น listener

  const MatchRole(this.value);
  final String value;

  MatchRole get target =>
      this == MatchRole.seeker ? MatchRole.listener : MatchRole.seeker;
}

class ActiveRandomChatSession {
  const ActiveRandomChatSession({
    required this.chatId,
    required this.role,
    required this.recipientUserId,
  });

  final String chatId;
  final MatchRole role;
  final String recipientUserId;
}

class ChatUserService extends GetxService {
  // Dependencies หลักของ service
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ContentModerationService _moderationService =
      ContentModerationService.instance;

  // Firestore collections
  static const String _chatCollection = 'Chats';
  static const String _queueCollection = 'RandomQueue';

  MatchRole _matchRoleFromDbValue(String value) {
    switch (value) {
      case 'listener':
        return MatchRole.listener;
      case 'seeker':
      default:
        return MatchRole.seeker;
    }
  }

  // ----------------------------------------------------------------
  // 1. Firebase Basic Chat Operations (รับ-ส่งข้อความ)
  // ----------------------------------------------------------------

  /// ดึง stream ของข้อความล่าสุดในห้องแชท
  /// ใช้สำหรับแสดง preview ในหน้า list หรือสถานะล่าสุด
  Stream<UserMessage?> getLatestMessageStream(String chatId) {
    return _firestore
        .collection(_chatCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('localTimestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      final timestamp = data['localTimestamp'] ?? data['timestamp'];
      if (timestamp is! Timestamp) return null;

      return UserMessage(
        senderId: (data['senderId'] ?? '') as String,
        text: (data['text'] ?? '') as String,
        timestamp: timestamp.toDate(),
        isRead: (data['isRead'] ?? false) as bool,
      );
    });
  }

  /// สร้าง/อัปเดตห้องแชท 1:1
  /// ใช้การ sort id เพื่อให้คู่เดิมได้ room id เดิมทุกครั้ง
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

  /// ส่งข้อความเข้าแชท
  /// ลำดับ: trim -> moderate -> เขียน Firestore -> clear input
  Future<SendMessageResult> sendMessage(
    String chatId,
    String currentUserId,
    String message,
    TextEditingController messageController,
    String? recipientUserId,
  ) async {
    final text = message.trim();
    if (text.isEmpty) {
      return const SendMessageResult(status: SendMessageStatus.skipped);
    }

    final moderation = await _moderationService.moderateText(
      source: 'chat_message',
      text: text,
      metadata: {
        'chatId': chatId,
        'senderId': currentUserId,
        'receiverId': recipientUserId ?? '',
      },
    );

    if (!moderation.allow) {
      return SendMessageResult(
        status: SendMessageStatus.blocked,
        reason: moderation.reason,
      );
    }

    final safeText = moderation.safeText.trim().isNotEmpty
        ? moderation.safeText.trim()
        : text;

    await _firestore
        .collection(_chatCollection)
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'receiverId': recipientUserId ?? '',
      'text': safeText,
      // ให้มีเวลา client เสมอ เพื่อกันเอกสารถูกมองข้ามตอน orderBy
      'localTimestamp': Timestamp.now(),
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    messageController.clear();
    return const SendMessageResult(status: SendMessageStatus.sent);
  }

  /// ลบข้อความเดียวในห้องแชท
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection(_chatCollection)
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // ----------------------------------------------------------------
  // 2. Queue Management (ใช้ Firestore เพื่อความเร็ว Realtime)
  // ----------------------------------------------------------------

  /// ให้ user เข้าคิวสุ่มหาคู่โดยระบุบทบาท
  Future<void> enterRandomQueue(
    String userId, {
    required MatchRole role,
  }) async {
    String dbRole = role.value;
    if (role == MatchRole.counselor) dbRole = 'listener';

    final queueRef = _firestore.collection(_queueCollection).doc(userId);
    // เริ่มคิวใหม่ทุกครั้ง: เคลียร์ chat เดิมทิ้งเพื่อไม่ให้เด้งกลับห้องเก่า
    await queueRef.set({
      'uid': userId,
      'status': 'waiting',
      'mode': dbRole,
      'chatId': null,
      'matchedWith': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // (Optional) อาจจะเรียก Supabase RPC เพื่อบันทึก Log การเข้าคิวได้
  }

  /// ให้ user ออกจากคิว และรีเซ็ตสถานะเป็น idle
  Future<void> leaveRandomQueue(String userId) async {
    await _firestore.collection(_queueCollection).doc(userId).set({
      'status': 'idle',
      'mode': null,
      'chatId': null,
      'matchedWith': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// helper: คืนค่า chatId เมื่อสถานะ queue เป็น matched เท่านั้น
  String? _extractChatId(Map<String, dynamic>? data) {
    if (data == null) return null;
    final status = (data['status'] ?? '') as String;
    if (status != 'matched') return null;
    final chatId = data['chatId'];
    return chatId is String && chatId.isNotEmpty ? chatId : null;
  }

  /// stream ติดตามการ match ของ user ปัจจุบัน
  Stream<String?> watchMatchedChatId(String userId) {
    return _firestore
        .collection(_queueCollection)
        .doc(userId)
        .snapshots()
        .map((snap) => _extractChatId(snap.data()));
  }

  Future<ActiveRandomChatSession?> getActiveRandomChatSession(
    String userId,
  ) async {
    final queueSnap =
        await _firestore.collection(_queueCollection).doc(userId).get();
    final queueData = queueSnap.data();
    final status = (queueData?['status'] ?? '') as String;
    final chatId = (queueData?['chatId'] ?? '') as String;

    if (status != 'matched' || chatId.trim().isEmpty) {
      return null;
    }

    final chatSnap =
        await _firestore.collection(_chatCollection).doc(chatId).get();
    if (!chatSnap.exists) {
      return null;
    }

    final chatData = chatSnap.data();
    final randomState = (chatData?['randomState'] ?? '') as String;
    if (randomState == 'ended') {
      return null;
    }

    final users = (chatData?['users'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    if (!users.contains(userId)) {
      return null;
    }

    final recipientUserId = users.firstWhere(
      (id) => id != userId,
      orElse: () => '',
    );
    if (recipientUserId.isEmpty) {
      return null;
    }

    final role = _matchRoleFromDbValue((queueData?['mode'] ?? '') as String);
    return ActiveRandomChatSession(
      chatId: chatId,
      role: role,
      recipientUserId: recipientUserId,
    );
  }

  Future<void> preloadChatHistory(String chatId) async {
    await _firestore.collection(_chatCollection).doc(chatId).get();
    await _firestore
        .collection(_chatCollection)
        .doc(chatId)
        .collection('messages')
        .get();
  }

  // ----------------------------------------------------------------
  // 3. Matching Logic (Logic หลัก)
  // ----------------------------------------------------------------

  /// พยายามจับคู่กับผู้ใช้ที่กำลังรอในคิว
  /// ใช้ transaction กัน race condition ระหว่างการจับคู่พร้อมกันหลายเครื่อง
  Future<String?> tryMatchWithWaitingUser(
    String userId, {
    required MatchRole role,
  }) async {
    final myDbRole = (role == MatchRole.counselor) ? 'listener' : role.value;
    final targetMode = (role == MatchRole.seeker) ? 'listener' : 'seeker';

    final myRef = _firestore.collection(_queueCollection).doc(userId);
    final rng = Random();
    final myQueueSnap = await myRef.get();
    final myLastMatchedWith =
        (myQueueSnap.data()?['lastMatchedWith'] ?? '') as String;

    // พยายามหาคู่ 5 ครั้ง
    for (var attempt = 0; attempt < 5; attempt++) {
      final waiting = await _firestore
          .collection(_queueCollection)
          .where('status', isEqualTo: 'waiting')
          .where('mode', isEqualTo: targetMode)
          .limit(50) // ดึงมาสุ่ม
          .get();

      if (waiting.docs.isEmpty) return null;

      final candidates = waiting.docs.where((doc) => doc.id != userId).toList();
      if (candidates.isEmpty) return null;

      // ถ้ามีตัวเลือกมากกว่า 1 คน ให้พยายามหลบคู่ล่าสุดก่อน
      final preferred = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
        candidates,
      )..removeWhere((doc) => doc.id == myLastMatchedWith);

      final pool = preferred.isNotEmpty ? preferred : candidates;
      final candidate = pool[rng.nextInt(pool.length)];

      // เจอคู่แล้ว เริ่มทำ Transaction
      final otherUserId = candidate.id;
      final otherRef = _firestore.collection(_queueCollection).doc(otherUserId);
      final pair = [userId, otherUserId];
      final chatId = _newRandomChatId(); // สร้าง ID ห้องแชทใหม่
      final chatRef = _firestore.collection(_chatCollection).doc(chatId);

      try {
        await _firestore.runTransaction((tx) async {
          final mySnap = await tx.get(myRef);
          final otherSnap = await tx.get(otherRef);

          final myData = mySnap.data();
          final otherData = otherSnap.data();
          final otherMode = (otherData?['mode'] ?? '') as String;

          // ตรวจสอบสถานะล่าสุดอีกครั้งใน Transaction (กัน Race Condition)
          if ((myData?['status'] ?? '') != 'waiting' ||
              (otherData?['status'] ?? '') != 'waiting') {
            throw StateError('queue changed');
          }
          if (otherMode != targetMode) {
            throw StateError('role changed');
          }

          // สร้างห้องแชท
          tx.set(
              chatRef,
              {
                'users': pair,
                'isRandom': true,
                'matchType': 'seeker_listener',
                'randomState': 'active',
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
                'sessionId': chatId,
              },
              SetOptions(merge: true));

          // อัปเดตสถานะตัวเอง
          tx.set(
              myRef,
              {
                'status': 'matched',
                'mode': myDbRole,
                'chatId': chatId,
                'matchedWith': otherUserId,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));

          // อัปเดตสถานะคู่สนทนา
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
      } on Exception catch (e, stack) {
        debugPrint(
          'tryMatchWithWaitingUser attempt $attempt failed: $e\n$stack',
        );
        continue; // ถ้า Transaction ล้มเหลว ให้ลองใหม่
      }
    }

    debugPrint(
        'tryMatchWithWaitingUser: exhausted all retry attempts for user $userId');
    return null;
  }

  // ----------------------------------------------------------------
  // 4. End Chat & Feedback (การจบแชทและการให้คะแนน)
  // ----------------------------------------------------------------

  /// จบแชทสุ่ม:
  /// 1) mark ห้องเป็น ended
  /// 2) เคลียร์ queue ของผู้ใช้ทั้งสองคน
  Future<void> endRandomChat({
    required String chatId,
    required String endedByUserId,
  }) async {
    final chatRef = _firestore.collection(_chatCollection).doc(chatId);
    final chatSnap = await chatRef.get();
    final data = chatSnap.data();
    final users =
        (data?['users'] as List<dynamic>? ?? []).whereType<String>().toList();

    // ✅ ปรับปรุง: อัปเดตสถานะเป็น 'ended' ก่อน แต่ "อย่าเพิ่งลบข้อความ"
    // เพื่อให้ Frontend สามารถดึงข้อความมานับคำ (Word Count) ได้ก่อนส่ง Feedback
    await chatRef.update({
      'randomState': 'ended',
      'endedBy': endedByUserId,
      'endedAt': FieldValue.serverTimestamp(),
    });

    // เคลียร์ Queue ของ User ทั้งคู่ให้ว่าง (กลับเป็น idle)
    final batch = _firestore.batch();
    for (final uid in users) {
      final peerId = users.firstWhere((id) => id != uid, orElse: () => '');
      final queueRef = _firestore.collection(_queueCollection).doc(uid);
      batch.set(
          queueRef,
          {
            'status': 'idle',
            'mode': null,
            'chatId': null,
            'matchedWith': null,
            'lastMatchedWith': peerId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }
    await batch.commit();

    // หมายเหตุ: การลบข้อความจริง (deleteAllMessages) ควรทำหลังจาก Submit Feedback เสร็จสิ้น
    // หรือปล่อยให้เป็นหน้าที่ของ Admin script ก็ได้
  }

  /// บันทึก feedback ของ session ลง Firestore
  Future<void> submitFeedback({
    required String sessionId,
    required String chatId,
    required String fromUserId,
    required String toUserId,
    required String fromRole,
    required String toRole,
    required int rating,
    required String comment,
    required bool starred,
    required int wordCount,
  }) async {
    await _firestore.collection('ChatFeedback').add({
      'sessionId': sessionId,
      'chatId': chatId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromRole': fromRole,
      'toRole': toRole,
      'rating': rating,
      'comment': comment,
      'starred': starred,
      'wordCount': wordCount,
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint("✅ Feedback saved to Firestore (Words: $wordCount)");
  }

  // ----------------------------------------------------------------
  // Helper Methods
  // ----------------------------------------------------------------

  /// สร้าง chat id แบบสุ่มโดยอิง timestamp เพื่อโอกาสชนต่ำ
  String _newRandomChatId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts ^ (ts >> 7)).toRadixString(36);
    return 'random_${ts}_$rand';
  }

  /// ลบข้อความทั้งหมดในห้องแชท และลบ document ห้องทิ้งท้าย
  Future<void> deleteAllMessages(String chatId) async {
    const batchSize = 350;
    while (true) {
      final snap = await _firestore
          .collection(_chatCollection)
          .doc(chatId)
          .collection('messages')
          .limit(batchSize)
          .get();

      if (snap.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    // ลบห้องแชททิ้งท้าย
    await _firestore.collection(_chatCollection).doc(chatId).delete();
  }
}

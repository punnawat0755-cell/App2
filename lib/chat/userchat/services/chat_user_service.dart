import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ Import Supabase Client (ตรวจสอบ path ให้ถูกต้องตามโปรเจกต์ของคุณ)
import 'package:flutter_application_1/chat/userchat/models/usermessage.model.dart';

// ✅ แก้ Enum ให้ตรงกับที่ Controller ส่งมา
enum MatchRole {
  seeker('seeker'),
  listener('listener'), // ใน DB ใช้คำว่า listener
  counselor('listener'); // เผื่อ Controller ส่ง counselor มา ให้ค่าเป็น listener

  const MatchRole(this.value);
  final String value;

  MatchRole get target =>
      this == MatchRole.seeker ? MatchRole.listener : MatchRole.seeker;
}

class ChatUserService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ✅ ใช้ตัวแปร supabase จาก supabase_client.dart หรือเรียก Supabase.instance.client โดยตรง
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _chatCollection = 'Chats';
  static const String _queueCollection = 'RandomQueue';

  // ----------------------------------------------------------------
  // 1. Firebase Basic Chat Operations (รับ-ส่งข้อความ)
  // ----------------------------------------------------------------

  Stream<UserMessage?> getLatestMessageStream(String chatId) {
    return _firestore
        .collection(_chatCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      final timestamp = data['timestamp'];
      if (timestamp is! Timestamp) return null;

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
    String? recipientUserId,
  ) async {
    final text = message.trim();
    if (text.isEmpty) return;

    messageController.clear();

    await _firestore
        .collection(_chatCollection)
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'receiverId': recipientUserId ?? '',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

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

  Future<void> enterRandomQueue(
    String userId, {
    required MatchRole role,
  }) async {
    String dbRole = role.value;
    if (role == MatchRole.counselor) dbRole = 'listener';

    // บันทึกลง Firestore เพื่อให้ Client อื่นๆ เห็นสถานะและจับคู่ได้
    await _firestore.collection(_queueCollection).doc(userId).set({
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
    if (data == null) return null;
    final status = (data['status'] ?? '') as String;
    if (status != 'matched') return null;
    final chatId = data['chatId'];
    return chatId is String && chatId.isNotEmpty ? chatId : null;
  }

  Stream<String?> watchMatchedChatId(String userId) {
    return _firestore
        .collection(_queueCollection)
        .doc(userId)
        .snapshots()
        .map((snap) => _extractChatId(snap.data()));
  }

  // ----------------------------------------------------------------
  // 3. Matching Logic (Logic หลัก)
  // ----------------------------------------------------------------

  Future<String?> tryMatchWithWaitingUser(
    String userId, {
    required MatchRole role,
  }) async {
    final myDbRole = (role == MatchRole.counselor) ? 'listener' : role.value;
    final targetMode = (role == MatchRole.seeker) ? 'listener' : 'seeker';

    final myRef = _firestore.collection(_queueCollection).doc(userId);
    final now = DateTime.now();
    final activeThreshold = now.subtract(const Duration(seconds: 25));

    // พยายามหาคู่ 5 ครั้ง
    for (var attempt = 0; attempt < 5; attempt++) {
      final waiting = await _firestore
          .collection(_queueCollection)
          .where('status', isEqualTo: 'waiting')
          .where('mode', isEqualTo: targetMode)
          .limit(50) // ดึงมาสุ่ม
          .get();

      if (waiting.docs.isEmpty) return null;

      QueryDocumentSnapshot<Map<String, dynamic>>? candidate;
      
      // กรองหาคนที่ Active อยู่จริงๆ
      for (final doc in waiting.docs) {
        if (doc.id == userId) continue; // ไม่จับคู่ตัวเอง

        final data = doc.data();
        final updatedAt = data['updatedAt'];
        
        // เช็คเวลาล่าสุด
        if (updatedAt is Timestamp &&
            updatedAt.toDate().isBefore(activeThreshold)) {
          continue;
        }

        if (updatedAt == null || updatedAt is Timestamp) {
          candidate = doc;
          break;
        }
      }

      if (candidate == null) return null;

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

          // ตรวจสอบสถานะล่าสุดอีกครั้งใน Transaction (กัน Race Condition)
          if ((myData?['status'] ?? '') != 'waiting' ||
              (otherData?['status'] ?? '') != 'waiting') {
            throw StateError('queue changed');
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
                'supaSessionId': null, // เดี๋ยวมาเติมหลังจากสร้างใน Supabase เสร็จ
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

        // ✅ 3.1 สร้าง Session ใน Supabase (หลังจากจับคู่สำเร็จใน Firebase)
        // เพื่อใช้เก็บสถิติและคำนวณเหรียญ
        _createSupabaseSession(
          chatId: chatId,
          myUserId: userId,
          otherUserId: otherUserId,
          myRole: myDbRole,
        );

        return chatId;
      } catch (_) {
        continue; // ถ้า Transaction ล้มเหลว ให้ลองใหม่
      }
    }

    return null;
  }

  // Helper: สร้าง Session ใน Supabase และนำ ID กลับมาแปะใน Firebase
  Future<void> _createSupabaseSession({
    required String chatId,
    required String myUserId,
    required String otherUserId,
    required String myRole,
  }) async {
    try {
      final seekerId = (myRole == 'seeker') ? myUserId : otherUserId;
      final listenerId = (myRole == 'seeker') ? otherUserId : myUserId;

      // Insert ลงตาราง chat_sessions
      final response = await _supabase
          .from('chat_sessions')
          .insert({
            'seeker_id': seekerId,
            'listener_id': listenerId,
            'status': 'active',
            'started_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('id')
          .single();

      final supaSessionId = response['id'].toString();

      // อัปเดต Firestore ว่าห้องนี้ผูกกับ Session ไหนใน Supabase
      await _firestore.collection(_chatCollection).doc(chatId).update({
        'supaSessionId': supaSessionId,
      });
      
      debugPrint("✅ Supabase Session Created: $supaSessionId");
    } catch (e) {
      debugPrint("❌ Create Supabase Session Error: $e");
      // ไม่ throw error เพื่อให้การแชทดำเนินต่อไปได้แม้ Supabase จะมีปัญหาชั่วคราว
    }
  }

  // ----------------------------------------------------------------
  // 4. End Chat & Feedback (การจบแชทและการให้คะแนน)
  // ----------------------------------------------------------------

  Future<void> endRandomChat({
    required String chatId,
    required String endedByUserId,
  }) async {
    final chatRef = _firestore.collection(_chatCollection).doc(chatId);
    final chatSnap = await chatRef.get();
    final data = chatSnap.data();
    final users = (data?['users'] as List<dynamic>? ?? []).whereType<String>().toList();

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
    
    // หมายเหตุ: การลบข้อความจริง (deleteAllMessages) ควรทำหลังจาก Submit Feedback เสร็จสิ้น
    // หรือปล่อยให้เป็นหน้าที่ของ Admin script ก็ได้
  }

  // ✅ ฟังก์ชันใหม่: ส่ง Feedback + จำนวนคำ ไปยัง Supabase (เพื่อรับเหรียญ)
  Future<void> submitFeedback({
    required String sessionId, // ต้องใช้ ID ของ Supabase (supaSessionId)
    required int rating,
    required String comment,
    required bool starred,
    required int wordCount, // รับค่าจำนวนคำที่นับได้จาก Frontend
  }) async {
    try {
      // เรียก RPC ใน Supabase (SQL ที่อัปเดตไปล่าสุด)
      await _supabase.rpc('submit_feedback_and_reward', params: {
        'p_session_id': sessionId,
        'p_rating': rating,
        'p_comment': comment,
        'p_starred': starred,
        'p_word_count': wordCount,
      });
      debugPrint("✅ Feedback & Reward Submitted (Words: $wordCount)");
    } catch (e) {
      debugPrint("❌ Feedback Error: $e");
      rethrow;
    }
  }

  // ----------------------------------------------------------------
  // Helper Methods
  // ----------------------------------------------------------------

  String _newRandomChatId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts ^ (ts >> 7)).toRadixString(36);
    return 'random_${ts}_$rand';
  }

  // ฟังก์ชันลบข้อความ (เรียกใช้เมื่อต้องการล้างข้อมูลห้องแชทจริงๆ)
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

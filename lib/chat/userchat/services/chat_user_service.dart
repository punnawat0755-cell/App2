import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'package:flutter_application_1/chat/userchat/models/usermessage.model.dart';

enum SendMessageStatus { sent, blocked, skipped }

class SendMessageResult {
  const SendMessageResult({
    required this.status,
    this.reason,
  });

  final SendMessageStatus status;
  final String? reason;
}

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
  late final http.Client _httpClient;

  static const String _chatCollection = 'Chats';
  static const String _queueCollection = 'RandomQueue';
  static const String _n8nModerationWebhook = String.fromEnvironment(
    'N8N_MODERATION_WEBHOOK',
    defaultValue: 'https://n8n.tgstack.dev/webhook/HowAreYou',
  );
  static const bool _moderationFailOpen = bool.fromEnvironment(
    'N8N_MODERATION_FAIL_OPEN',
    defaultValue: true,
  );
  static const bool _allowBadCertificate = bool.fromEnvironment(
    'N8N_ALLOW_BAD_CERT',
    defaultValue: true,
  );
  static const String _allowBadCertificateHosts = String.fromEnvironment(
    'N8N_ALLOW_BAD_CERT_HOSTS',
    defaultValue: 'n8n.tgstack.dev',
  );
  static const Duration _moderationTimeout = Duration(seconds: 6);

  ChatUserService() {
    _httpClient = _buildHttpClient();
  }

  @override
  void onClose() {
    _httpClient.close();
    super.onClose();
  }

  // ----------------------------------------------------------------
  // 1. Firebase Basic Chat Operations (รับ-ส่งข้อความ)
  // ----------------------------------------------------------------

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

    final moderation = await _moderateMessage(
      chatId: chatId,
      senderId: currentUserId,
      receiverId: recipientUserId ?? '',
      text: text,
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

  Future<_ModerationResult> _moderateMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    if (_n8nModerationWebhook.trim().isEmpty) {
      return _ModerationResult.allow(text);
    }
    final webhookUri = Uri.tryParse(_n8nModerationWebhook);
    debugPrint(
      'n8n moderation request url=$_n8nModerationWebhook host=${webhookUri?.host ?? '-'}',
    );

    try {
      final response = await _httpClient
          .post(
            webhookUri ?? Uri.parse(_n8nModerationWebhook),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'content_moderate',
              'chatId': chatId,
              'senderId': senderId,
              'receiverId': receiverId,
              'message': text,
              'text': text,
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            }),
          )
          .timeout(_moderationTimeout);

      debugPrint(
        'n8n moderation http=${response.statusCode} body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackOnModerationError(text, 'http-${response.statusCode}');
      }

      if (response.body.trim().isEmpty) {
        return _fallbackOnModerationError(text, 'empty-body');
      }

      final payload = _parseModerationPayload(response.body);
      if (payload == null) {
        return _fallbackOnModerationError(text, 'invalid-payload');
      }

      final status = (payload['status'] ?? '').toString().trim().toLowerCase();
      final allowed = _readBool(payload, const ['allowed', 'allow']);
      final explicitProfanity = _readBool(
            payload,
            const ['isProfane', 'profanity', 'containsProfanity'],
          ) ==
          true;
      final safeText = _readSafeText(payload, text);

      debugPrint('n8n moderation payload=$payload');

      if (allowed != null) {
        if (allowed) {
          return _ModerationResult.allow(safeText);
        }
        return const _ModerationResult.block('moderation-blocked-by-n8n');
      }

      if (explicitProfanity ||
          status == 'block' ||
          status == 'blocked' ||
          status == 'reject') {
        return const _ModerationResult.block('moderation-blocked-by-n8n');
      }

      if (status == 'mask' ||
          status == 'sanitize' ||
          status == 'sanitized' ||
          status == 'allow' ||
          status == 'allowed' ||
          status == 'ok') {
        return _ModerationResult.allow(safeText);
      }

      return _fallbackOnModerationError(text, 'unknown-status:$status');
    } on TimeoutException {
      debugPrint('n8n moderation timeout');
      return _fallbackOnModerationError(text, 'timeout');
    } catch (e) {
      debugPrint('n8n moderation failed: $e');
      return _fallbackOnModerationError(text, 'exception');
    }
  }

  _ModerationResult _fallbackOnModerationError(String text, String reason) {
    if (_moderationFailOpen) {
      return _ModerationResult.allow(text);
    }
    return _ModerationResult.block('moderation-unavailable:$reason');
  }

  Map<String, dynamic>? _asMapPayload(dynamic decoded) {
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  Map<String, dynamic>? _parseModerationPayload(String body) {
    final trimmed = body.trim();

    try {
      final decoded = jsonDecode(trimmed);
      final payload = _asMapPayload(decoded);
      if (payload != null) {
        return payload;
      }
    } catch (_) {
      // fallback to lightweight parser for plain-text webhook responses
    }

    final normalized = trimmed.toLowerCase();
    if (normalized == 'ok' ||
        normalized == 'allow' ||
        normalized == 'allowed' ||
        normalized == 'true' ||
        normalized == 'pass') {
      return {'allowed': true};
    }
    if (normalized == 'block' ||
        normalized == 'blocked' ||
        normalized == 'false' ||
        normalized == 'reject') {
      return {'allowed': false};
    }

    return null;
  }

  http.Client _buildHttpClient() {
    if (!_allowBadCertificate) {
      return http.Client();
    }

    final configuredHosts = _allowBadCertificateHosts
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    final webhookHost = Uri.tryParse(_n8nModerationWebhook)?.host.toLowerCase();
    if (webhookHost != null && webhookHost.isNotEmpty) {
      configuredHosts.add(webhookHost);
    }

    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        final isAllowed = configuredHosts.contains(host.toLowerCase());
        if (isAllowed) {
          debugPrint(
            'n8n moderation warning: accepting untrusted cert from $host:$port',
          );
        } else {
          debugPrint(
            'n8n moderation blocked untrusted cert from non-allowed host $host:$port',
          );
        }
        return isAllowed;
      };

    return IOClient(ioClient);
  }

  bool? _readBool(Map<String, dynamic> payload, List<String> keys) {
    final keySet = keys.map((e) => e.toLowerCase()).toSet();
    // Priority 1: respect top-level field first (the direct webhook contract).
    for (final entry in payload.entries) {
      if (!keySet.contains(entry.key.toLowerCase())) continue;
      final parsed = _parseDynamicBool(entry.value);
      if (parsed != null) return parsed;
    }

    // Priority 2: scan nested payloads.
    // If both true/false appear in different branches, false should win.
    return _readBoolRecursive(payload, keySet);
  }

  bool? _readBoolRecursive(dynamic node, Set<String> keys) {
    bool foundTrue = false;

    if (node is Map) {
      final map = Map<String, dynamic>.from(node);

      for (final entry in map.entries) {
        final key = entry.key.toLowerCase();
        if (keys.contains(key)) {
          final parsed = _parseDynamicBool(entry.value);
          if (parsed != null) {
            if (!parsed) return false;
            foundTrue = true;
          }
        }
      }

      for (final value in map.values) {
        final nested = _readBoolRecursive(value, keys);
        if (nested != null) {
          if (!nested) return false;
          foundTrue = true;
        }
      }
      return foundTrue ? true : null;
    }

    if (node is List) {
      for (final item in node) {
        final nested = _readBoolRecursive(item, keys);
        if (nested != null) {
          if (!nested) return false;
          foundTrue = true;
        }
      }
    }
    return foundTrue ? true : null;
  }

  bool? _parseDynamicBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final value = raw.trim().toLowerCase();
      if (value == 'true' || value == '1' || value == 'yes') return true;
      if (value == 'false' || value == '0' || value == 'no') return false;
    }
    return null;
  }

  String _readSafeText(Map<String, dynamic> payload, String fallback) {
    const keys = [
      'cleanMessage',
      'sanitizedText',
      'safeText',
      'maskedText',
      'message',
      'text',
    ];

    for (final key in keys) {
      final raw = payload[key];
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }
    return fallback;
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
      } catch (_) {
        continue; // ถ้า Transaction ล้มเหลว ให้ลองใหม่
      }
    }

    return null;
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

  // บันทึก Feedback ลง Firestore
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

class _ModerationResult {
  const _ModerationResult({
    required this.allow,
    required this.safeText,
    required this.reason,
  });

  factory _ModerationResult.allow(String text) => _ModerationResult(
        allow: true,
        safeText: text,
        reason: '',
      );

  const _ModerationResult.block(String reasonCode)
      : allow = false,
        safeText = '',
        reason = reasonCode;

  final bool allow;
  final String safeText;
  final String reason;
}

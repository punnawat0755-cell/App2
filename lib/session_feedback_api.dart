import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// 1. Model สำหรับเก็บข้อมูล Feedback
// ---------------------------------------------------------------------------
class SessionFeedback {
  final String sessionId;
  final String fromUserId; // รับมาปกติใน Flutter (แต่ไม่ได้ส่งเข้า API เพราะ DB ดึงจาก Token)
  final String toUserId;
  final String fromRole;
  final String toRole;
  final int rating;
  final String comment;
  final bool starred;
  final int wordCount;

  SessionFeedback({
    required this.sessionId,
    required this.fromUserId,
    required this.toUserId,
    required this.fromRole,
    required this.toRole,
    required this.rating,
    required this.comment,
    required this.starred,
    required this.wordCount,
  });

  // 🟢 แปลง Object เป็น Map สำหรับส่งไปที่ RPC Function
  // สังเกตว่าชื่อ Key ต้องตั้งให้ตรงกับ Parameter ของ Function (p_...) ที่เราสร้างไว้ใน DB
  Map<String, dynamic> toRpcJson() {
    return {
      'p_session_id': sessionId,
      'p_to_user_id': toUserId,
      'p_from_role': fromRole,
      'p_to_role': toRole,
      'p_rating': rating,
      'p_comment': comment,
      'p_starred': starred,
      'p_word_count': wordCount,
    };
  }
}

// ---------------------------------------------------------------------------
// 2. API Service สำหรับส่งข้อมูล (แบบ HTTP Request)
// ---------------------------------------------------------------------------
class FeedbackApiService {
  
  /// ส่งข้อมูลผ่าน HTTP POST ไปยัง Supabase RPC
  Future<bool?> createFeedback(SessionFeedback feedback, String token) async {
    try {
      const String supabaseUrl = 'https://dvbagdhjlklmysjjuvht.supabase.co'; 
      const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2YmFnZGhqbGtsbXlzamp1dmh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgzNzQ0MjcsImV4cCI6MjA4Mzk1MDQyN30.pqinIw8uza_02BRRheQrBLNnRK0InCBBXG00HmB0Bys';
      
      // 🟢 จุดสำคัญ: เปลี่ยน URL ไปยิงที่ /rest/v1/rpc/ ตามด้วยชื่อ Function
      final Uri url = Uri.parse('$supabaseUrl/rest/v1/rpc/submit_feedback');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ส่ง Token ของ User เพื่อให้ DB รู้ว่าใครเป็นคนส่ง
          'apikey': anonKey,
        },
        // ส่ง Body เป็น JSON ที่มี key ตรงกับพารามิเตอร์ (p_...)
        body: jsonEncode(feedback.toRpcJson()), 
      );

      // Status Code 200, 201 หรือ 204 ถือว่าสำเร็จ
      if (response.statusCode >= 200 && response.statusCode <= 204) {
        debugPrint('บันทึก Feedback สำเร็จผ่าน HTTP Request');
        return true; 
      } else {
        debugPrint('Failed to submit feedback. Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating feedback via API: $e');
      return null;
    }
  }
}
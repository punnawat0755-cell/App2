import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// หากคุณใช้ Supabase Client ในการ Insert ข้อมูลโดยตรง สามารถ Uncomment บรรทัดด้านล่างได้
// import 'package:flutter_application_1/supabase_client.dart';

// ---------------------------------------------------------------------------
// 1. Model สำหรับเก็บข้อมูล Feedback
// ---------------------------------------------------------------------------
class SessionFeedback {
  final String sessionId;
  final String fromUserId;
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

  // แปลง Object เป็น Map สำหรับส่งไปที่ API หรือ Database
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'from_role': fromRole,
      'to_role': toRole,
      'rating': rating,
      'comment': comment,
      'is_starred': starred, // ปรับชื่อ Field ให้ตรงกับ Database ของคุณ
      'word_count': wordCount,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

// ---------------------------------------------------------------------------
// 2. API Service สำหรับส่งข้อมูล
// ---------------------------------------------------------------------------
class FeedbackApiService {
  
  /// วิธีที่ 1: การใช้ HTTP Request ยิงเข้า Supabase REST API หรือ Edge Function โดยใช้ Token
  Future<bool?> createFeedback(SessionFeedback feedback, String token) async {
    try {
  
      const String supabaseUrl = 'https://dvbagdhjlklmysjjuvht.supabase.co'; 
      const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2YmFnZGhqbGtsbXlzamp1dmh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgzNzQ0MjcsImV4cCI6MjA4Mzk1MDQyN30.pqinIw8uza_02BRRheQrBLNnRK0InCBBXG00HmB0Bys';
      
      // ตัวอย่าง URL สำหรับยิงเข้า Table 'session_feedbacks' ตรงๆ
      final Uri url = Uri.parse('$supabaseUrl/rest/v1/session_feedbacks');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ใช้ Token ของ User ที่ล็อกอิน
          'apikey': anonKey,
          'Prefer': 'return=minimal'
        },
        body: jsonEncode(feedback.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true; // ส่งข้อมูลสำเร็จ
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

  /// ------------------------------------------------------------------------
  /// วิธีที่ 2 (ทางเลือก): หากต้องการใช้ Supabase Client Insert ลง Table โดยตรง 
  /// (ถ้าใช้ตัวนี้ ไม่จำเป็นต้องใช้ parameter 'token' ก็ได้ เพราะ Supabase จัดการ Auth ให้แล้ว)
  /// ------------------------------------------------------------------------
  /*
  Future<bool?> createFeedbackWithClient(SessionFeedback feedback) async {
    try {
      await supabase
          .from('session_feedbacks') // ชื่อ Table ใน Supabase
          .insert(feedback.toJson());
      return true;
    } catch (e) {
      debugPrint('Error inserting feedback via Supabase Client: $e');
      return null;
    }
  }
  */
}
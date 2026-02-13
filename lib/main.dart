import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_application_1/chat/userchat/bindings/chat_binding.dart';
import 'package:flutter_application_1/chat/userchat/views/Login&RegisterChat.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';

// Local notifications instance
final FlutterLocalNotificationsPlugin _localNoti = FlutterLocalNotificationsPlugin();

// Android notification channel (สำคัญสำหรับ Android 8+)
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for important notifications.',
  importance: Importance.high,
);

Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  await _localNoti.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (resp) {
      debugPrint('Notification tapped. payload=${resp.payload}');
    },
  );

  final androidPlugin =
      _localNoti.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  // สร้าง notification channel
  await androidPlugin?.createNotificationChannel(_androidChannel);

  // ✅ ขอ permission สำหรับ Android 13+
  await androidPlugin?.requestNotificationsPermission();
}

// handler ตอนมีข้อความเข้ามาใน background/terminated
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('BG message: ${message.messageId} data=${message.data}');
}

/// Subscribe topics สำหรับ broadcast จาก n8n
Future<void> _subscribeTopics(FirebaseMessaging messaging) async {
  // ปรับรายชื่อ topic ตามที่คุณใช้ใน n8n ได้เลย
  const topics = ['general', 'morning', 'night', 'advisors'];

  for (final t in topics) {
    await messaging.subscribeToTopic(t);
    debugPrint('Subscribed to topic: $t');
  }
}

Future<String?> setupFCM() async {
  final messaging = FirebaseMessaging.instance;

  // ขอ permission (iOS ต้องขอแน่ ๆ / Android 13+ ก็ต้องขอ)
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('Permission: ${settings.authorizationStatus}');

  // Subscribe topic หลัง permission ผ่าน (แนะนำทำหลัง login ก็ได้)
  await _subscribeTopics(messaging);

  // เอา token
  final token = await messaging.getToken();
  debugPrint('FCM Token: $token');

  // (ทางเลือก) ฟัง token เปลี่ยน
  messaging.onTokenRefresh.listen((newToken) {
    debugPrint('FCM Token refreshed: $newToken');
  });

  // ตอนแอปอยู่หน้า: รับข้อความแล้ว “โชว์เป็น notification” ด้วย local noti
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint('FG message: ${message.messageId} data=${message.data}');

    final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    await _localNoti.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  });

  // ผู้ใช้กด notification แล้วเปิดแอป (จาก background)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Opened from notification: ${message.messageId}');
  });

  // กรณีเปิดแอปจากสถานะปิด (terminated) ด้วยการกด notification
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('Opened from terminated: ${initialMessage.messageId}');
  }

  return token;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // register background handler (ต้องทำก่อนใช้งานอื่น)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await _initLocalNotifications();
  final token = await setupFCM();

  runApp(MyApp(token: token));
}

class MyApp extends StatelessWidget {
  final String? token;
  const MyApp({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('FCM Setup')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FCM Token (คัดลอกไปใช้ทดสอบได้)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SelectableText(
                token == null ? 'Token not available yet.' : token!,
              ),
              const SizedBox(height: 16),
              const Text(
                'Subscribed topics:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('- general\n- morning\n- night\n- advisors'),
              const SizedBox(height: 16),
              const Text(
                'ทดสอบจาก n8n:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'ตั้ง topic ใน n8n เป็น "general" แล้วใส่ title/body จากนั้น Execute → ควรเด้งทันที',
              ),

              InkWell(
                onTap: (){
                   Get.to(()=> AuthCheck(),binding: UserChatBinding());
                },
                child: Text(
                  'Chat'
                ),
              ),

             
            ],
          ),
        ),
      ),
    );
  }
}

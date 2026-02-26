import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const String _broadcastTopic = 'all_users';

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'chat_high_importance',
    'Chat Notifications',
    description: 'Notifications for incoming chat messages',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _local.initialize(initSettings);

    final androidImpl = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_androidChannel);
    await androidImpl?.requestNotificationsPermission();

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    await _subscribeAllUsersTopic(messaging);
    final token = await messaging.getToken();
    debugPrint('FCM token: $token');
    await _saveTokenForCurrentUser(token);

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        return;
      }
      await _subscribeAllUsersTopic(messaging);
      final freshToken = await messaging.getToken();
      await _saveTokenForCurrentUser(freshToken);
    });

    supabase.Supabase.instance.client.auth.onAuthStateChange
        .listen((event) async {
      if (event.session?.user == null) {
        return;
      }
      final freshToken = await messaging.getToken();
      await _saveTokenForCurrentUser(freshToken);
    });

    messaging.onTokenRefresh.listen((newToken) async {
      await _subscribeAllUsersTopic(messaging);
      await _saveTokenForCurrentUser(newToken);
    });

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    _initialized = true;
  }

  static Future<void> _saveTokenForCurrentUser(String? token) async {
    if (token == null || token.isEmpty) {
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return;
    }

    final supabaseUser = supabase.Supabase.instance.client.auth.currentUser;
    final userMetadata = supabaseUser?.userMetadata;

    final email = _firstNonEmpty([
      supabaseUser?.email,
      firebaseUser.email,
    ]);
    final displayName = _firstNonEmpty([
      _readMetadataString(userMetadata, 'display_name'),
      _readMetadataString(userMetadata, 'full_name'),
      _readMetadataString(userMetadata, 'name'),
      firebaseUser.displayName,
    ]);
    final username = _resolveUsername(
      firebaseUser: firebaseUser,
      email: email,
      displayName: displayName,
      userMetadata: userMetadata,
    );

    final payload = <String, dynamic>{
      'fcmTokens': FieldValue.arrayUnion([token]),
      'username': username,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (email != null) {
      payload['email'] = email;
    }
    if (displayName != null) {
      payload['displayName'] = displayName;
    }

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(firebaseUser.uid)
        .set(payload, SetOptions(merge: true));
  }

  static String _resolveUsername({
    required User firebaseUser,
    required Map<String, dynamic>? userMetadata,
    String? email,
    String? displayName,
  }) {
    final metadataUsername = _firstNonEmpty([
      _readMetadataString(userMetadata, 'username'),
      _readMetadataString(userMetadata, 'user_name'),
      _readMetadataString(userMetadata, 'preferred_username'),
    ]);
    if (metadataUsername != null) {
      return metadataUsername;
    }
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    if (email != null && email.isNotEmpty && email.contains('@')) {
      return email.split('@').first;
    }
    return 'user_${firebaseUser.uid.substring(0, 6)}';
  }

  static String? _readMetadataString(
      Map<String, dynamic>? metadata, String key) {
    final value = metadata?[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = _resolveTitle(message);
    final body = _resolveBody(message);
    if (title.isEmpty && body.isEmpty) {
      debugPrint('FCM arrived but no title/body in notification or data');
      return;
    }

    await _local.show(
      message.hashCode,
      title.isEmpty ? 'Notification' : title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_high_importance',
          'Chat Notifications',
          channelDescription: 'Notifications for incoming chat messages',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> _subscribeAllUsersTopic(
      FirebaseMessaging messaging) async {
    await messaging.subscribeToTopic(_broadcastTopic);
    debugPrint('Subscribed to topic: $_broadcastTopic');
  }

  static String _resolveTitle(RemoteMessage message) {
    final nTitle = message.notification?.title;
    if (nTitle != null && nTitle.trim().isNotEmpty) {
      return nTitle.trim();
    }
    final dataTitle = message.data['title'];
    if (dataTitle is String && dataTitle.trim().isNotEmpty) {
      return dataTitle.trim();
    }
    return '';
  }

  static String _resolveBody(RemoteMessage message) {
    final nBody = message.notification?.body;
    if (nBody != null && nBody.trim().isNotEmpty) {
      return nBody.trim();
    }
    final dataBody = message.data['body'];
    if (dataBody is String && dataBody.trim().isNotEmpty) {
      return dataBody.trim();
    }
    final dataMessage = message.data['message'];
    if (dataMessage is String && dataMessage.trim().isNotEmpty) {
      return dataMessage.trim();
    }
    return '';
  }
}

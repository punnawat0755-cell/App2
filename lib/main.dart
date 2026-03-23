import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_env.dart';
import 'core/responsive/app_responsive_frame.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:flutter_application_1/app/navigation/bottom_nav_bar.dart';
import 'features/login/view/login.dart';
import 'features/login/view/splash_screen_page.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.load();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final supabaseUrl = AppEnv.string(
    'SUPABASE_URL',
    compileTimeValue: const bool.hasEnvironment('SUPABASE_URL')
        ? const String.fromEnvironment('SUPABASE_URL')
        : null,
  );
  final supabaseAnonKey = AppEnv.string(
    'SUPABASE_ANON_KEY',
    compileTimeValue: const bool.hasEnvironment('SUPABASE_ANON_KEY')
        ? const String.fromEnvironment('SUPABASE_ANON_KEY')
        : null,
  );

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing Supabase config. Add SUPABASE_URL and SUPABASE_ANON_KEY to .env.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("Notification Init Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'How Are You',
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }

        return AppResponsiveFrame(child: child);
      },
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.mitrTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const AuthStateHandler(),
    );
  }
}

class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  State<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  // ใช้ shared client จาก core/supabase/supabase_client.dart
  final _authStream = supabase.auth.onAuthStateChange;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreenPage();
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return const BottomNavBar();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_env.dart';
import 'core/services/coin_service.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:flutter_application_1/app/navigation/bottom_nav_bar.dart';
import 'features/login/view/login_page.dart';
import 'features/login/view/privacy_policy_page.dart';
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

  Get.put(CoinService(), permanent: true);

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
        final media = MediaQuery.of(context);
        final widthScale = (media.size.width / 390).clamp(0.92, 1.04);
        final userScale = media.textScaler.scale(1);
        final mergedScale = (userScale * widthScale).clamp(0.90, 1.08);

        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(mergedScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
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
  Future<bool>? _pdpaAcceptedFuture;
  String? _pdpaCheckedUserId;

  Future<bool> _loadPdpaAccepted(String userId) async {
    final response = await supabase
        .from('profiles')
        .select('pdpa_accepted_at')
        .eq('id', userId)
        .maybeSingle();
    return response != null && response['pdpa_accepted_at'] != null;
  }

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
          final userId = session.user.id;
          if (_pdpaAcceptedFuture == null || _pdpaCheckedUserId != userId) {
            _pdpaCheckedUserId = userId;
            _pdpaAcceptedFuture = _loadPdpaAccepted(userId);
          }

          return FutureBuilder<bool>(
            future: _pdpaAcceptedFuture,
            builder: (context, pdpaSnapshot) {
              if (pdpaSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreenPage();
              }

              final isAccepted = pdpaSnapshot.data ?? false;
              if (isAccepted) {
                return const BottomNavBar();
              }

              return PrivacyPolicyPage(
                popOnAccept: false,
                onAccepted: () {
                  if (!mounted) return;
                  setState(() {
                    _pdpaAcceptedFuture = Future<bool>.value(true);
                  });
                },
              );
            },
          );
        } else {
          _pdpaAcceptedFuture = null;
          _pdpaCheckedUserId = null;
          return const LoginPage();
        }
      },
    );
  }
}

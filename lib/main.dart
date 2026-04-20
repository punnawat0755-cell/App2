import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_env.dart';
import 'core/services/auth_session_marker.dart';
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
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
      home: const AppBootstrapGate(),
    );
  }
}

class AppBootstrapGate extends StatefulWidget {
  const AppBootstrapGate({super.key});

  @override
  State<AppBootstrapGate> createState() => _AppBootstrapGateState();
}

class _AppBootstrapGateState extends State<AppBootstrapGate> {
  late Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      AppEnv.load(),
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
    ]);

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

    await _validatePersistedSession();
    await _ensureProfileForAuthenticatedUser();

    if (!Get.isRegistered<CoinService>()) {
      Get.put(CoinService(), permanent: true);
    }

    unawaited(_initializeNotificationsInBackground());
  }

  Future<void> _initializeNotificationsInBackground() async {
    try {
      await NotificationService.initialize();
    } catch (e, st) {
      debugPrint("Notification Init Error: $e");
      debugPrint("Notification Init Stack: $st");
    }
  }

  Future<void> _validatePersistedSession() async {
    final session = supabase.auth.currentSession;
    if (session == null) {
      return;
    }

    final canReuseSession = await AuthSessionMarker.canReusePersistedSession();
    if (!canReuseSession) {
      debugPrint(
        'Persisted session found without explicit login marker. Signing out.',
      );
      await supabase.auth.signOut();
      return;
    }

    try {
      await supabase.auth.getUser();
    } catch (error) {
      debugPrint('Invalid persisted session. Signing out: $error');
      await supabase.auth.signOut();
      await AuthSessionMarker.clearExplicitLoginMarker();
    }
  }

  Future<void> _ensureProfileForAuthenticatedUser() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    try {
      await supabase.rpc('ensure_my_profile');
      return;
    } catch (_) {}

    try {
      await supabase.from('profiles').upsert({
        'id': currentUser.id,
        'coins': 0,
      });
    } catch (error) {
      debugPrint('Unable to ensure profile row: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreenPage();
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Initialization failed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _bootstrapFuture = _initializeApp();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const AuthStateHandler();
      },
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
        final session = snapshot.data?.session ?? supabase.auth.currentSession;
        final currentUser = supabase.auth.currentUser;
        final isAuthenticated = session != null && currentUser != null;

        if (isAuthenticated) {
          final userId = currentUser.id;
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

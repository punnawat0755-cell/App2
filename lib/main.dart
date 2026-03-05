import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/bottonbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';
import 'module/home/view/home_view.dart';
import 'module/login/view/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dvbagdhjlklmysjjuvht.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2YmFnZGhqbGtsbXlzamp1dmh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgzNzQ0MjcsImV4cCI6MjA4Mzk1MDQyN30.pqinIw8uza_02BRRheQrBLNnRK0InCBBXG00HmB0Bys',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // locale: const Locale('th', 'TH'),
      debugShowCheckedModeBanner: false,
      title: 'Supabase Flutter App',
      theme: ThemeData(
        useMaterial3: true,

        // แบบที่ 1: เปลี่ยนฟอนต์ทั้งแอป (แนะนำ)
        // คุณสามารถเปลี่ยน .kanitTextTheme เป็น .promptTextTheme หรือ .robotoTextTheme ได้ตามใจชอบ
        textTheme: GoogleFonts.mitrTextTheme(Theme.of(context).textTheme),

        // ถ้าต้องการปรับสีหลักด้วย (Optional)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: BottomNavBar(),
    );
  }
}

class AuthStateController extends GetxController {
  final RxBool isLoading = true.obs;
  final Rxn<Session> session = Rxn<Session>();
  StreamSubscription<AuthState>? _authSub;

  @override
  void onInit() {
    super.onInit();
    session.value = supabase.auth.currentSession;
    isLoading.value = false;
    _authSub = supabase.auth.onAuthStateChange.listen((state) {
      session.value = state.session;
      isLoading.value = false;
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }
}

class AuthStateHandler extends StatelessWidget {
  const AuthStateHandler({super.key});

  static final AuthStateController _controller = Get.put(AuthStateController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (_controller.session.value == null) return LoginPage();
      return HomePage();
    });
  }
}

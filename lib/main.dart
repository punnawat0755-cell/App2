import 'package:flutter/material.dart';
import 'package:flutter_application_1/bottonbar.dart';
import 'package:flutter_application_1/module/feed/view/feed_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';
import 'module/home/view/home.dart';
import 'module/login/view/login.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supabase Flutter App',
      theme: ThemeData(
        useMaterial3: true,

        // แบบที่ 1: เปลี่ยนฟอนต์ทั้งแอป (แนะนำ)
        // คุณสามารถเปลี่ยน .kanitTextTheme เป็น .promptTextTheme หรือ .robotoTextTheme ได้ตามใจชอบ
        textTheme: GoogleFonts.promptTextTheme(Theme.of(context).textTheme),

        // ถ้าต้องการปรับสีหลักด้วย (Optional)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: BottomNavBar(),
    );
  }
}

class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  State<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  late final Stream<AuthState> _stream = supabase.auth.onAuthStateChange;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _stream,
      builder: (context, snapshot) {
        // UX: กันกระพริบตอนเริ่ม
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = supabase.auth.currentSession;
        if (session == null) return const LoginPage();
        return const HomePage();
      },
    );
  }
}

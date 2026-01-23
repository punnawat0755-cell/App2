import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dvbagdhjlklmysjjuvht.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2YmFnZGhqbGtsbXlzamp1dmh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgzNzQ0MjcsImV4cCI6MjA4Mzk1MDQyN30.pqinIw8uza_02BRRheQrBLNnRK0InCBBXG00HmB0Bys',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

/* ------------------------------ THEME ------------------------------ */

class AppColors {
  static const lightBg = Color(0xFFEAF4FF); // ฟ้าอ่อน
  static const primaryBlue = Color(0xFF0D47A1); // ฟ้าเข้ม (ปุ่มหลัก)
  static const softBlue = Color(0xFF90CAF9); // ฟ้าอ่อน (accent)
  static const textDark = Color(0xFF0B1B2B);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primaryBlue,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.lightBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.textDark,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.95),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.6),
      ),
      labelStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.75)),
      prefixIconColor: AppColors.primaryBlue,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // แก้: ต้องเป็น CardThemeData ไม่ใช่ CardTheme
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}

/* ------------------------------ APP ------------------------------ */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final start = supabase.auth.currentSession != null
        ? const HomePage()
        : const LoginPage();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supabase App',
      theme: buildAppTheme(),
      home: start,
    );
  }
}

/* ------------------------------ UI HELPERS ------------------------------ */

Widget authCard({
  required BuildContext context,
  required String title,
  required String subtitle,
  required IconData icon,
  required List<Widget> children,
}) {
  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.cloud,
                    size: 33,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 300),
                const SizedBox(height: 77),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textDark.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 18),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void showError(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), backgroundColor: Colors.red),
  );
}

void showSuccess(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), backgroundColor: Colors.green),
  );
}

/* ------------------------------ LOGIN ------------------------------ */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _hidePw = true;

  Future<void> _login() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user == null) {
        throw const AuthException('เข้าสู่ระบบไม่สำเร็จ');
      }

      // อัปเดต last_login ผ่าน RPC
      await supabase.rpc('ensure_my_profile');
      await supabase.rpc('touch_last_login');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      showError(context, _prettyAuthMessage(e.message));
    } catch (e) {
      if (!mounted) return;
      showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: authCard(
        context: context,
        title: 'เข้าสู่ระบบ',
        subtitle: 'ล็อกอินเพื่อเข้าใช้งานระบบ',
        icon: Icons.lock,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _hidePw,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidePw = !_hidePw),
                icon: Icon(_hidePw ? Icons.visibility : Icons.visibility_off),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text('LOGIN'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            ),
            child: const Text('สร้างบัญชีใหม่'),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- REGISTER ----------------------------- */

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _hidePw = true;

  Future<void> _register() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final username = _usernameController.text.trim();
      final fullName = _nameController.text.trim();

      if (email.isEmpty ||
          password.isEmpty ||
          username.isEmpty ||
          fullName.isEmpty) {
        throw const AuthException('กรุณากรอกข้อมูลให้ครบ');
      }

      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': fullName,
        },
      );

      if (res.user == null) {
        throw const AuthException('สมัครไม่สำเร็จ กรุณาลองใหม่');
      }

      if (!mounted) return;

      showSuccess(
        context,
        'สมัครสำเร็จ! ถ้าเปิดยืนยันอีเมล ให้ไปกดยืนยันก่อนล็อกอิน',
      );

      Navigator.pop(context);
    } on AuthException catch (e) {
      if (!mounted) return;
      showError(context, _prettyAuthMessage(e.message));
    } catch (e) {
      if (!mounted) return;
      showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: authCard(
        context: context,
        title: 'สร้างบัญชีใหม่',
        subtitle: 'กรอกข้อมูลเพื่อสมัครสมาชิก',
        icon: Icons.person_add,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _hidePw,
            decoration: InputDecoration(
              labelText: 'Password (ขั้นต่ำ 6 ตัว)',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidePw = !_hidePw),
                icon: Icon(_hidePw ? Icons.visibility : Icons.visibility_off),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'ชื่อ-นามสกุล',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _register,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text('REGISTER'),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------- HOME ------------------------------- */

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<Map<String, dynamic>?> _getProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('ยังไม่ได้ล็อกอิน');

    // maybeSingle() คืนค่า Map<String, dynamic>? อยู่แล้ว
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลัก'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final profile = snapshot.data;
          final name = (profile?['full_name'] ?? '-').toString();
          final username = (profile?['username'] ?? '-').toString();

          String lastLogin = '-';
          final rawLast = profile?['last_login'];
          if (rawLast != null) {
            final dt = DateTime.parse(rawLast.toString()).toLocal();
            final mm = dt.minute.toString().padLeft(2, '0');
            lastLogin = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:$mm';
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.softBlue.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.verified_user,
                            size: 38,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'สวัสดี, $name',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$username',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Email'),
                          subtitle: Text(email),
                        ),
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: const Text('เข้าใช้งานล่าสุด'),
                          subtitle: Text(lastLogin),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ------------------------------ HELPERS ----------------------------- */

String _prettyAuthMessage(String message) {
  final m = message.toLowerCase();

  if (m.contains('only request this after')) {
    return 'คุณกดขอสมัครซ้ำเร็วเกินไป กรุณารอประมาณ 1 นาที แล้วลองใหม่';
  }
  if (m.contains('invalid login credentials')) {
    return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
  }
  if (m.contains('user already registered')) {
    return 'อีเมลนี้ถูกใช้งานแล้ว';
  }
  if (m.contains('password should be at least')) {
    return 'รหัสผ่านสั้นเกินไป';
  }

  return message;
}

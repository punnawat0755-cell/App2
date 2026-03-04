import 'package:flutter/material.dart';
import 'package:flutter_application_1/bottom_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// สมมติว่าไฟล์นี้มีตัวแปร supabase global อยู่ ถ้าไม่มีให้ใช้ Supabase.instance.client แทน
import 'register.dart';
import 'policy.dart';

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

  // ประกาศ supabase client ให้อ่านง่ายขึ้น
  final supabase = Supabase.instance.client;

  // ---------- helpers ----------
  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: Colors.red),
    );
  }

  String _prettyAuthMessage(String message) {
    final m = message.toLowerCase();
    if (m.contains('only request this after')) {
      return 'คุณกดขอทำรายการซ้ำเร็วเกินไป กรุณารอประมาณ 1 นาที แล้วลองใหม่';
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
  // -----------------------------------------------

  // 📌 ฟังก์ชันจัดการหลัง Login (เช็ค PDPA) อยู่ใน _LoginPageState ถูกต้องแล้ว
  Future<void> _handlePostLogin() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      debugPrint('--- 🔍 กำลังดึงข้อมูล PDPA ของ: ${user.id} ---');

      final response = await supabase
          .from('profiles')
          .select('pdpa_accepted_at')
          .eq('id', user.id)
          .maybeSingle();

      debugPrint('--- 📦 ข้อมูลที่ได้จาก DB: $response ---');

      final hasAccepted =
          response != null && response['pdpa_accepted_at'] != null;

      if (!mounted) return;

      if (hasAccepted) {
        debugPrint('--- ✅ ยอมรับแล้ว เข้าหน้า BottomNavBar ได้เลย ---');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNavBar()),
        );
      } else {
        debugPrint('--- ⚠️ ยังไม่ยอมรับ กำลังเรียก Dialog ---');

        // เปิดหน้าเงื่อนไข/นโยบาย และรอรับผลลัพธ์
        final bool? isAccepted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
        );

        if (!mounted) return;

        if (isAccepted == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BottomNavBar()),
          );
        } else {
          // ถ้ากดกากบาท (X) บังคับ Logout
          await supabase.auth.signOut();
          _showError('คุณต้องยอมรับเงื่อนไข PDPA เพื่อใช้งานแอป');
        }
      }
    } catch (e) {
      debugPrint('--- ❌ Error checking PDPA: $e ---');
      if (mounted) {
        _showError('ดึงข้อมูลระบบล้มเหลว: $e');
      }
    }
  }

  // 📌 ฟังก์ชัน Login หลัก
  Future<void> _login() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.user == null) {
        throw const AuthException('เข้าสู่ระบบไม่สำเร็จ');
      }

      // เรียก RPC อัปเดตข้อมูลเบื้องต้น
      await supabase.rpc('ensure_my_profile');
      await supabase.rpc('touch_last_login');

      if (!mounted) return;

      // 📌 เรียกฟังก์ชันเช็ค PDPA ทันทีที่ล็อกอินผ่าน
      await _handlePostLogin();
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(_prettyAuthMessage(e.message));
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
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

  // ---------------- UI Widgets ----------------
  static const _mainBlue = Color(0xFF4A89D8);
  static const _lightBlue = Color(0xFF64BFFF);
  static const _fieldGrey = Color(0xFFF3F3F3);

  Widget _roundedField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required VoidCallback? onPressed,
    required bool loading,
  }) {
    return SizedBox(
      height: 55,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Image.asset(
                    'assets/images/How 1.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _mainBlue,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _roundedField(
                    controller: _emailController,
                    icon: Icons.person,
                    hint: 'อีเมล',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _roundedField(
                    controller: _passwordController,
                    icon: Icons.lock,
                    hint: 'รหัสผ่าน',
                    obscure: _hidePw,
                    suffix: IconButton(
                      onPressed: () => setState(() => _hidePw = !_hidePw),
                      icon: Icon(
                        _hidePw ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'ลืมรหัสผ่าน?',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _primaryButton(
                    text: 'เข้าสู่ระบบ',
                    onPressed: _isLoading ? null : _login,
                    loading: _isLoading,
                  ),
                  const SizedBox(height: 130),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ยังไม่มีบัญชีใช่ไหม? ',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterPage()),
                        ),
                        child: const Text(
                          'ลงทะเบียน',
                          style: TextStyle(
                            color: _lightBlue,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

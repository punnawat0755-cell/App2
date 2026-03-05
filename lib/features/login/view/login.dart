import 'package:flutter/material.dart';
import 'package:flutter_application_1/bottom_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  final supabase = Supabase.instance.client;

  static const _mainBlue = Color(0xFF4A89D8);
  static const _lightBlue = Color(0xFF64BFFF);
  static const _fieldGrey = Color(0xFFF3F3F3);

  void _showError(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: Colors.red),
    );
  }

  String _prettyAuthMessage(String message) {
    final m = message.toLowerCase();
    if (m.contains('only request this after')) {
      return 'คุณกดทำรายการซ้ำเร็วเกินไป กรุณารอประมาณ 1 นาที';
    }
    if (m.contains('invalid login credentials')) {
      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    }
    if (m.contains('user already registered')) {
      return 'อีเมลนี้ถูกใช้งานแล้ว';
    }
    return message;
  }

  Future<void> _handlePostLogin() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('profiles')
          .select('pdpa_accepted_at')
          .eq('id', user.id)
          .maybeSingle();

      final hasAccepted =
          response != null && response['pdpa_accepted_at'] != null;

      if (!mounted) return;

      if (hasAccepted) {
        _navigateToHome();
      } else {
        final bool? isAccepted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => const PrivacyPolicyPage()),
        );

        if (!mounted) return;

        if (isAccepted == true) {
          _navigateToHome();
        } else {
          await supabase.auth.signOut();
          _showError('คุณต้องยอมรับเงื่อนไข PDPA เพื่อใช้งานแอป');
        }
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาดในการตรวจสอบข้อมูล: $e');
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BottomNavBar()),
    );
  }

  Future<void> _login() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthException('เข้าสู่ระบบไม่สำเร็จ');
      }

      // พยายามเรียก RPC ถ้ามี
      try {
        await supabase.rpc('ensure_my_profile');
      } catch (_) {
        // fallback สร้าง profile ถ้าไม่มี
        await supabase.from('profiles').upsert({'id': response.user!.id});
      }

      try {
        await supabase.rpc('touch_last_login');
      } catch (_) {}

      await _handlePostLogin();
    } on AuthException catch (e) {
      _showError(_prettyAuthMessage(e.message));
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('กรุณากรอกอีเมลก่อน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ส่งลิงก์รีเซ็ตรหัสผ่านไปที่อีเมลแล้ว')),
      );
    } on AuthException catch (e) {
      _showError(_prettyAuthMessage(e.message));
    } catch (e) {
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
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
          padding:
              const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Image.asset(
                'assets/images/How 1.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (ctx, obj, st) =>
                    const Icon(Icons.image,
                        size: 100, color: Colors.grey),
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
                keyboardType:
                    TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _roundedField(
                controller: _passwordController,
                icon: Icons.lock,
                hint: 'รหัสผ่าน',
                obscure: _hidePw,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _hidePw = !_hidePw),
                  icon: Icon(
                    _hidePw
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed:
                      _isLoading ? null : _forgotPassword,
                  child: const Text(
                    'ลืมรหัสผ่าน?',
                    style:
                        TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _primaryButton(
                text: 'เข้าสู่ระบบ',
                onPressed:
                    _isLoading ? null : _login,
                loading: _isLoading,
              ),
              const SizedBox(height: 100),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    'ยังไม่มีบัญชีใช่ไหม? ',
                    style:
                        TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const RegisterPage(),
                      ),
                    ),
                    child: const Text(
                      'ลงทะเบียน',
                      style: TextStyle(
                        color: _lightBlue,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
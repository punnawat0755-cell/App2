import 'package:flutter/material.dart';
import 'package:flutter_application_1/bottom_bar.dart';
import 'package:flutter_application_1/module/policy/view/policy_view.dart';
import 'package:flutter_application_1/module/reset/view/reset_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'register_view.dart';

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

  static const _blue = Color(0xFF1E88FF);

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
          MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
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

      try {
        await supabase.rpc('ensure_my_profile');
      } catch (_) {
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

  void _openResetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(
          initialEmail: _emailController.text.trim(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _pillField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black.withValues(alpha: 0.22),
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.black.withValues(alpha: 0.25),
            size: 20,
          ),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _blueButton({
    required String text,
    required VoidCallback? onPressed,
    required bool loading,
  }) {
    return SizedBox(
      height: 46,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF22C6FF), Color(0xFF1E88FF)],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: Colors.black.withValues(alpha: 0.10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        Image.asset(
                          'assets/images/How 1.png',
                          width: 66,
                          height: 66,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _blue,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _pillField(
                    controller: _emailController,
                    icon: Icons.person_outline,
                    hint: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _pillField(
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    hint: 'Password',
                    obscure: _hidePw,
                    suffix: IconButton(
                      onPressed: () => setState(() => _hidePw = !_hidePw),
                      icon: Icon(
                        _hidePw ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black.withValues(alpha: 0.25),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _openResetPassword,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: Colors.black.withValues(alpha: 0.30),
                      ),
                      child: const Text(
                        'Forget password?',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _blueButton(
                    text: 'Login',
                    onPressed: _isLoading ? null : _login,
                    loading: _isLoading,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't Have An Account?",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withValues(alpha: 0.30),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: _blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

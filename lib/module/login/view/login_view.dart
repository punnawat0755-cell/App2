import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase_client.dart';
import '../../home/view/home_view.dart';
import 'register_view.dart';

class LoginController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxBool hidePw = true.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  String prettyAuthMessage(String message) {
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

  Future<String?> login() async {
    if (isLoading.value) return null;
    isLoading.value = true;

    try {
      final response = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.user == null) {
        throw const AuthException('เข้าสู่ระบบไม่สำเร็จ');
      }

      await supabase.rpc('ensure_my_profile');
      await supabase.rpc('touch_last_login');

      Get.off(() => HomePage());
      return null;
    } on AuthException catch (e) {
      return prettyAuthMessage(e.message);
    } catch (e) {
      return 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }
}

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final LoginController controller = Get.isRegistered<LoginController>()
      ? Get.find<LoginController>()
      : Get.put(LoginController());

  Widget _pillField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
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
                          const Icon(
                            Icons.flutter_dash,
                            size: 44,
                            color: Color(0xFF1E88FF),
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
                        color: Color(0xFF1E88FF),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _pillField(
                      controller: controller.emailController,
                      icon: Icons.person_outline,
                      hint: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _pillField(
                      controller: controller.passwordController,
                      icon: Icons.lock_outline,
                      hint: 'Password',
                      obscure: controller.hidePw.value,
                      suffix: IconButton(
                        onPressed: () =>
                            controller.hidePw.value = !controller.hidePw.value,
                        icon: Icon(
                          controller.hidePw.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.black.withValues(alpha: 0.25),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
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
                      onPressed: controller.isLoading.value
                          ? null
                          : () async {
                              final errorText = await controller.login();
                              if (errorText != null && errorText.isNotEmpty) {
                                Get.snackbar(
                                  'Error',
                                  errorText,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 3),
                                );
                              }
                            },
                      loading: controller.isLoading.value,
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
                          onPressed: () => Get.to(() => RegisterPage()),
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
                              color: Color(0xFF1E88FF),
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
      ),
    );
  }
}

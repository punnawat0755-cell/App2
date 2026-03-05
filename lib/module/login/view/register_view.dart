import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase_client.dart';
import 'login_view.dart';

class RegisterController extends GetxController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool hidePw = true.obs;
  final Rxn<DateTime> birthday = Rxn<DateTime>();
  final RxString sex = 'Female'.obs;

  @override
  void onClose() {
    usernameController.dispose();
    birthdayController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  String prettyAuthMessage(String message) {
    final m = message.toLowerCase();

    if (m.contains('only request this after')) {
      return 'คุณกดขอทำรายการซ้ำเร็วเกินไป กรุณารอประมาณ 1 นาที แล้วลองใหม่';
    }
    if (m.contains('user already registered')) {
      return 'อีเมลนี้ถูกใช้งานแล้ว';
    }
    if (m.contains('password should be at least')) {
      return 'รหัสผ่านสั้นเกินไป';
    }
    if (m.contains('email not confirmed')) {
      return 'ยังไม่ได้ยืนยันอีเมล กรุณาไปกดยืนยันในอีเมลก่อน';
    }
    return message;
  }

  String toIsoDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  void setBirthday(DateTime value) {
    birthday.value = value;
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    birthdayController.text = '$dd/$mm/${value.year}';
  }

  Future<String?> register() async {
    if (isLoading.value) return null;
    isLoading.value = true;

    try {
      final username = usernameController.text.trim();
      final email = emailController.text.trim();
      final phone = phoneController.text.trim();
      final password = passwordController.text.trim();

      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        throw const AuthException('กรุณากรอกข้อมูลให้ครบ (Name, Email, Password)');
      }
      if (birthday.value == null) {
        throw const AuthException('กรุณาเลือกวันเกิด');
      }

      String gender;
      switch (sex.value) {
        case 'Male':
          gender = 'male';
          break;
        case 'Female':
          gender = 'female';
          break;
        default:
          gender = 'other';
      }

      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'gender': gender,
          'birth_date': toIsoDate(birthday.value!),
          'phone': phone,
        },
      );

      if (res.user == null) {
        throw const AuthException('สมัครไม่สำเร็จ กรุณาลองใหม่');
      }

      Get.snackbar(
        'สำเร็จ',
        'สมัครสำเร็จ! ถ้าเปิดยืนยันอีเมล ให้ไปกดยืนยันก่อนล็อกอิน',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.off(() => LoginPage());
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

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final RegisterController controller = Get.isRegistered<RegisterController>()
      ? Get.find<RegisterController>()
      : Get.put(RegisterController());

  static const _bg = Colors.white;
  static const _blue = Color(0xFF1E88FF);

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _pillField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool readOnly = false,
    bool obscure = false,
    VoidCallback? onTap,
    Widget? suffix,
  }) {
    return Container(
      height: 44,
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
        keyboardType: keyboardType,
        readOnly: readOnly,
        obscureText: obscure,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black.withValues(alpha: 0.22),
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
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

  Widget _sexButton(String value) {
    final selected = controller.sex.value == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.sex.value = value,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF79D7FF) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.10),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ]
                : [],
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: selected
                  ? const Color(0xFF0D47A1)
                  : Colors.black.withValues(alpha: 0.35),
            ),
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
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _pickBirthday(BuildContext context) async {
    final now = DateTime.now();
    final initial = controller.birthday.value ??
        DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked == null) return;
    controller.setBirthday(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    const Text(
                      'Create New\nAccount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _blue,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(alignment: Alignment.centerLeft, child: _label('Name')),
                    _pillField(controller: controller.usernameController, hint: ''),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: _label('Birthday')),
                    _pillField(
                      controller: controller.birthdayController,
                      hint: '',
                      readOnly: true,
                      onTap: () => _pickBirthday(context),
                      suffix: IconButton(
                        onPressed: () => _pickBirthday(context),
                        icon: Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: _label('Sex')),
                    Row(
                      children: [
                        _sexButton('Male'),
                        const SizedBox(width: 10),
                        _sexButton('Female'),
                        const SizedBox(width: 10),
                        _sexButton('None'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: _label('Email')),
                    _pillField(
                      controller: controller.emailController,
                      hint: '',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _label('Number Phone'),
                    ),
                    _pillField(
                      controller: controller.phoneController,
                      hint: '',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: _label('Password')),
                    _pillField(
                      controller: controller.passwordController,
                      hint: '',
                      obscure: controller.hidePw.value,
                      suffix: IconButton(
                        onPressed: () =>
                            controller.hidePw.value = !controller.hidePw.value,
                        icon: Icon(
                          controller.hidePw.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 20,
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _blueButton(
                      text: 'Sign Up',
                      onPressed: controller.isLoading.value
                          ? null
                          : () async {
                              final errorText = await controller.register();
                              if (errorText != null && errorText.isNotEmpty) {
                                Get.snackbar(
                                  'Error',
                                  errorText,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            },
                      loading: controller.isLoading.value,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'already have an account? ',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withValues(alpha: 0.28),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.off(() => LoginPage()),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Login',
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
      ),
    );
  }
}

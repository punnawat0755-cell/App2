import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _hidePw = true;

  DateTime? _birthday;
  String _sex = 'Female';

  // ---------- helpers ----------
  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: Colors.green),
    );
  }

  String _prettyAuthMessage(String message) {
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
  // ----------------------------

  String _toIsoDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd'; // YYYY-MM-DD
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = _birthday ?? DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked == null) return;

    setState(() {
      _birthday = picked;
      // แสดงแบบ dd/MM/yyyy ในช่อง (อ่านง่าย)
      final dd = picked.day.toString().padLeft(2, '0');
      final mm = picked.month.toString().padLeft(2, '0');
      _birthdayController.text = '$dd/$mm/${picked.year}';
    });
  }

  Future<void> _register() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        throw const AuthException(
            'กรุณากรอกข้อมูลให้ครบ (Name, Email, Password)');
      }
      if (_birthday == null) {
        throw const AuthException('กรุณาเลือกวันเกิด');
      }

      // map เพศให้สอดคล้องกับ DB
      String gender;
      switch (_sex) {
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
          // ชื่อต้องตรงกับ DB trigger
          'gender': gender,
          'birth_date': _toIsoDate(_birthday!), // YYYY-MM-DD
          'phone': phone,
        },
      );

      if (res.user == null) {
        throw const AuthException('สมัครไม่สำเร็จ กรุณาลองใหม่');
      }

      if (!mounted) return;

      _showSuccess('สมัครสำเร็จ! ถ้าเปิดยืนยันอีเมล ให้ไปกดยืนยันก่อนล็อกอิน');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
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
    _usernameController.dispose();
    _birthdayController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------- UI ----------
  static const _mainBlue = Color(0xFF4A89D8);
  static const _lightBlue = Color(0xFF64BFFF);
  static const _fieldGrey = Color(0xFFF3F3F3);

  Widget _buildInputLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    IconData? suffixIcon,
    Widget? suffix,
    bool readOnly = false,
    bool obscure = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldGrey,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        obscureText: obscure,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54),
          suffixIcon: suffix ??
              (suffixIcon != null
                  ? Icon(suffixIcon, color: Colors.grey)
                  : null),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _sexButton(String value) {
    final selected = _sex == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sex = value),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFC7E9FF) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? _lightBlue : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: selected ? _mainBlue : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required VoidCallback? onPressed,
    required bool loading,
  }) {
    final scale = context.responsive;
    return SizedBox(
      height: scale.rs(55, min: 50, max: 56),
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
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: scale.rf(20, min: 17.5, max: 20.5),
                  fontWeight: FontWeight.bold,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
            final horizontalPadding = constraints.maxWidth < 360 ? 18.0 : 28.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'สร้างบัญชีใหม่',
                        style: TextStyle(
                          fontSize: scale.rf(28, min: 24, max: 28),
                          fontWeight: FontWeight.bold,
                          color: _mainBlue,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildInputLabel('ชื่อผู้ใช้งาน', isRequired: true),
                      _buildTextField(
                          controller: _usernameController, hint: 'แมวน้ำ'),
                      _buildInputLabel('วันเกิด', isRequired: true),
                      _buildTextField(
                        controller: _birthdayController,
                        hint: '17/12/2004',
                        readOnly: true,
                        onTap: _pickBirthday,
                        suffixIcon: Icons.calendar_today_outlined,
                        suffix: IconButton(
                          onPressed: _pickBirthday,
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      _buildInputLabel('เพศ', isRequired: true),
                      Row(
                        children: [
                          _sexButton('Male'),
                          const SizedBox(width: 10),
                          _sexButton('Female'),
                          const SizedBox(width: 10),
                          _sexButton('None'),
                        ],
                      ),
                      _buildInputLabel('อีเมล'),
                      _buildTextField(
                        controller: _emailController,
                        hint: '',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildInputLabel('เบอร์โทรศัพท์'),
                      _buildTextField(
                        controller: _phoneController,
                        hint: '',
                        keyboardType: TextInputType.phone,
                      ),
                      _buildInputLabel('รหัสผ่าน', isRequired: true),
                      _buildTextField(
                        controller: _passwordController,
                        hint: '',
                        obscure: _hidePw,
                        suffix: IconButton(
                          onPressed: () => setState(() => _hidePw = !_hidePw),
                          icon: Icon(
                            _hidePw ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _primaryButton(
                        text: 'ลงทะเบียน',
                        onPressed: _isLoading ? null : _register,
                        loading: _isLoading,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'มีบัญชีอยู่แล้ว? ',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            ),
                            child: const Text(
                              'เข้าสู่ระบบ',
                              style: TextStyle(
                                color: _lightBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                decorationColor: _lightBlue,
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
            );
          },
        ),
      ),
    );
  }
}

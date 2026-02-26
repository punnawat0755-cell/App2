import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase_client.dart';
import 'login.dart';

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
        throw const AuthException('กรุณากรอกข้อมูลให้ครบ (Name, Email, Password)');
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
  static const _bg = Color(0xFFE9F7FF);
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
    final selected = _sex == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sex = value),
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF79D7FF) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : Colors.black.withValues(alpha: 0.10),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                      color: Colors.black.withValues(alpha: 0.08),
                    )
                  ]
                : [],
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: selected ? const Color(0xFF0D47A1) : Colors.black.withValues(alpha: 0.35),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  _pillField(controller: _usernameController, hint: ''),
                  const SizedBox(height: 12),

                  Align(alignment: Alignment.centerLeft, child: _label('Birthday')),
                  _pillField(
                    controller: _birthdayController,
                    hint: '',
                    readOnly: true,
                    onTap: _pickBirthday,
                    suffix: IconButton(
                      onPressed: _pickBirthday,
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
                    controller: _emailController,
                    hint: '',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),

                  Align(alignment: Alignment.centerLeft, child: _label('Number Phone')),
                  _pillField(
                    controller: _phoneController,
                    hint: '',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  Align(alignment: Alignment.centerLeft, child: _label('Password')),
                  _pillField(
                    controller: _passwordController,
                    hint: '',
                    obscure: _hidePw,
                    suffix: IconButton(
                      onPressed: () => setState(() => _hidePw = !_hidePw),
                      icon: Icon(
                        _hidePw ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  _blueButton(
                    text: 'Sign Up',
                    onPressed: _isLoading ? null : _register,
                    loading: _isLoading,
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
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
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
    );
  }
}

import 'package:flutter/material.dart';
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
  final _lastPeriodController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _hidePw = true;

  DateTime? _birthday;
  String _sex = 'Female';

  static const _mainBlue = Color(0xFF4A89D8);
  static const _lightBlue = Color(0xFF64BFFF);
  static const _fieldGrey = Color(0xFFF3F3F3);

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

  String _toIsoDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  String _formatShortDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return '$dd/$mm/$yy';
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

    if (picked == null || !mounted) return;

    setState(() {
      _birthday = picked;
      _birthdayController.text = _formatDate(picked);
    });
  }

  Future<void> _pickLastPeriodRange() async {
    final now = DateTime.now();
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 5)),
        end: now,
      ),
    );

    if (pickedRange == null || !mounted) return;

    setState(() {
      _lastPeriodController.text =
          '${_formatShortDate(pickedRange.start)}-${_formatShortDate(pickedRange.end)}';
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
          'กรุณากรอกข้อมูลให้ครบ (Name, Email, Password)',
        );
      }
      if (_birthday == null) {
        throw const AuthException('กรุณาเลือกวันเกิด');
      }

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
          'gender': gender,
          'birth_date': _toIsoDate(_birthday!),
          'phone': phone,
        },
      );

      if (res.user == null) {
        throw const AuthException('สมัครไม่สำเร็จ กรุณาลองใหม่');
      }

      final hasSession =
          res.session != null || supabase.auth.currentSession != null;
      if (hasSession) {
        try {
          await supabase.auth.signOut();
        } catch (_) {}
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
    _lastPeriodController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
              fontSize: 18,
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
    required String hintText,
    bool isPassword = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    VoidCallback? onTap,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldGrey,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        readOnly: readOnly,
        keyboardType: keyboardType,
        onTap: onTap,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black54),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderButton(String label) {
    final isSelected = _sex == label;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sex = label),
        child: Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFC7E9FF) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? _lightBlue : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? _mainBlue : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'สร้างบัญชีใหม่',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _mainBlue,
                ),
              ),
              const SizedBox(height: 30),
              _buildInputLabel('ชื่อผู้ใช้งาน', isRequired: true),
              _buildTextField(
                controller: _usernameController,
                hintText: 'แมวน้ำ',
              ),
              _buildInputLabel('วันเกิด', isRequired: true),
              _buildTextField(
                controller: _birthdayController,
                hintText: '17/12/2004',
                readOnly: true,
                onTap: _pickBirthday,
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
                  _buildGenderButton('Male'),
                  _buildGenderButton('Female'),
                ],
              ),
              const SizedBox(height: 15),
              _buildInputLabel('อีเมล'),
              _buildTextField(
                controller: _emailController,
                hintText: '',
                keyboardType: TextInputType.emailAddress,
              ),
              _buildInputLabel('เบอร์โทรศัพท์'),
              _buildTextField(
                controller: _phoneController,
                hintText: '',
                keyboardType: TextInputType.phone,
              ),
              _buildInputLabel('รหัสผ่าน', isRequired: true),
              _buildTextField(
                controller: _passwordController,
                hintText: '',
                isPassword: _hidePw,
                suffix: IconButton(
                  onPressed: () => setState(() => _hidePw = !_hidePw),
                  icon: Icon(
                    _hidePw ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                ),
              ),
              if (_sex == 'Female') ...[
                _buildInputLabel('ประจำเดือนครั้งล่าสุด'),
                _buildTextField(
                  controller: _lastPeriodController,
                  hintText: 'dd/mm/yyyy - dd/mm/yyyy',
                  readOnly: true,
                  onTap: _pickLastPeriodRange,
                  suffix: IconButton(
                    onPressed: _pickLastPeriodRange,
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ลงทะเบียน',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'มีบัญชีอยู่แล้ว? ',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                    child: const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        color: _lightBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
  }
}

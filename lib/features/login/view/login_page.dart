import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/navigation/bottom_nav_bar.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/core/services/auth_session_marker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'privacy_policy_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const int _maxInitialPeriodDays = 14;

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

  String _toIsoDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String? _readStringIgnoreCase(
      Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      for (final entry in source.entries) {
        if (entry.key.toLowerCase() != key.toLowerCase()) continue;
        final value = entry.value?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return null;
  }

  bool? _readBoolIgnoreCase(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      for (final entry in source.entries) {
        if (entry.key.toLowerCase() != key.toLowerCase()) continue;
        final value = entry.value;
        if (value is bool) return value;
        final normalized = value?.toString().trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return null;
    return _dateOnly(parsed);
  }

  int _periodRangeDays(DateTimeRange range) =>
      _dateOnly(range.end).difference(_dateOnly(range.start)).inDays + 1;

  Future<bool> _seedInitialPeriodToCalendar(DateTimeRange range) async {
    final start = _dateOnly(range.start);
    final end = _dateOnly(range.end);
    final days = end.difference(start).inDays + 1;
    if (days <= 0 || days > _maxInitialPeriodDays) return false;

    for (var i = 0; i < days; i++) {
      final day = start.add(Duration(days: i));
      await supabase.rpc(
        'save_calendar_health_log',
        params: {
          'p_log_date': _toIsoDate(day),
          'p_is_menstruating': true,
          'p_symptoms': <String>[],
          'p_flow_level': null,
          'p_pain_level': null,
          'p_notes': null,
        },
      );
    }

    return true;
  }

  Future<void> _syncInitialPeriodFromMetadataIfNeeded() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final metadata = Map<String, dynamic>.from(
      user.userMetadata ?? const <String, dynamic>{},
    );
    final gender = _readStringIgnoreCase(metadata, const ['gender', 'sex']);
    if ((gender ?? '').trim().toLowerCase() != 'female') return;

    final alreadySeeded = _readBoolIgnoreCase(
          metadata,
          const ['initial_period_seeded', 'initialPeriodSeeded'],
        ) ??
        false;
    if (alreadySeeded) return;

    final start = _parseDate(
      _readStringIgnoreCase(
        metadata,
        const ['last_period_start_date', 'lastPeriodStartDate'],
      ),
    );
    final end = _parseDate(
      _readStringIgnoreCase(
        metadata,
        const ['last_period_end_date', 'lastPeriodEndDate'],
      ),
    );
    if (start == null || end == null) return;

    final safeRange = DateTimeRange(
      start: start,
      end: end.isBefore(start) ? start : end,
    );
    final dayCount = _periodRangeDays(safeRange);
    if (dayCount <= 0 || dayCount > _maxInitialPeriodDays) return;

    final seeded = await _seedInitialPeriodToCalendar(safeRange);
    if (!seeded) return;

    try {
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'last_period_start_date': _toIsoDate(safeRange.start),
            'last_period_end_date': _toIsoDate(safeRange.end),
            'initial_period_seeded': true,
          },
        ),
      );
    } catch (_) {}
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
        await supabase.from('profiles').upsert({
          'id': response.user!.id,
          'coins': 0,
        });
      }

      try {
        await supabase.rpc('touch_last_login');
      } catch (_) {}

      await AuthSessionMarker.markExplicitLoginCompleted();
      await _syncInitialPeriodFromMetadataIfNeeded();

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
        const SnackBar(content: Text('ส่งลิงก์รีเซ็ตรหัสผ่านไปที่อีเมลแล้ว')),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String iconAsset,
    required ResponsiveScale scale,
    TextInputType? keyboardType,
    bool isPassword = false,
    Widget? suffixIcon,
    double? iconSize,
    bool reserveSuffixSpace = false,
  }) {
    return Container(
      height: scale.rs(62, min: 56, max: 64),
      decoration: BoxDecoration(
        color: _fieldGrey,
        borderRadius: BorderRadius.circular(scale.rs(20, min: 18, max: 20)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: scale.rf(18, min: 15, max: 17),
          color: const Color(0xFF5D5D5D),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: const Color(0xFFBDBDBD),
            fontSize: scale.rf(16, min: 14, max: 16),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(scale.rs(14, min: 12, max: 14)),
            child: Image.asset(
              iconAsset,
              width: iconSize ?? scale.rs(30, min: 22, max: 28),
              height: iconSize ?? scale.rs(30, min: 22, max: 28),
              fit: BoxFit.contain,
            ),
          ),
          suffixIcon: suffixIcon ??
              (reserveSuffixSpace
                  ? SizedBox(
                      width: scale.rs(48, min: 44, max: 48),
                      height: scale.rs(48, min: 44, max: 48),
                    )
                  : null),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: scale.rs(4, min: 2, max: 6),
            vertical: scale.rs(16, min: 14, max: 16),
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
            final horizontalPadding = constraints.maxWidth < 360
                ? scale.rs(18, min: 16, max: 18)
                : scale.rs(34, min: 24, max: 40);
            final logoSize = scale.rs(160, min: 132, max: 180);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: scale.rs(20, min: 16, max: 24),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: scale.rs(80, min: 36, max: 100)),
                      Transform.scale(
                        scale: constraints.maxWidth < 360 ? 1.28 : 1.5,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.flutter_dash,
                            size: logoSize,
                            color: _mainBlue,
                          ),
                        ),
                      ),
                      SizedBox(height: scale.rs(24, min: 18, max: 26)),
                      Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(
                          fontSize: scale.rf(28, min: 23, max: 28),
                          fontWeight: FontWeight.bold,
                          color: _mainBlue,
                        ),
                      ),
                      SizedBox(height: scale.rs(20, min: 16, max: 20)),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'อีเมล',
                        iconAsset: 'assets/images/Customer.png',
                        keyboardType: TextInputType.emailAddress,
                        scale: scale,
                        reserveSuffixSpace: true,
                      ),
                      SizedBox(height: scale.rs(18, min: 14, max: 18)),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'รหัสผ่าน',
                        iconAsset: 'assets/images/lock.png',
                        iconSize: scale.rs(36, min: 26, max: 34),
                        isPassword: _hidePw,
                        scale: scale,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _hidePw = !_hidePw),
                          icon: Icon(
                            _hidePw ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                            size: scale.rs(22, min: 20, max: 22),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _forgotPassword,
                          child: Text(
                            'ลืมรหัสผ่าน?',
                            style: TextStyle(
                              color: const Color(0xFF8D8D8D),
                              fontSize: scale.rf(14, min: 12.5, max: 14),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: scale.rs(20, min: 16, max: 22)),
                      SizedBox(
                        width: double.infinity,
                        height: scale.rs(55, min: 50, max: 56),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _lightBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                scale.rs(20, min: 18, max: 20),
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: scale.rs(20, min: 18, max: 20),
                                  height: scale.rs(20, min: 18, max: 20),
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'เข้าสู่ระบบ',
                                  style: TextStyle(
                                    fontSize: scale.rf(18, min: 16, max: 18),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: scale.rs(130, min: 56, max: 180)),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'ยังไม่มีบัญชีใช่ไหม? ',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: scale.rf(16, min: 14, max: 16),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            ),
                            child: Text(
                              'ลงทะเบียน',
                              style: TextStyle(
                                color: _lightBlue,
                                fontWeight: FontWeight.w500,
                                fontSize: scale.rf(16, min: 14, max: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: scale.rs(20, min: 16, max: 20)),
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

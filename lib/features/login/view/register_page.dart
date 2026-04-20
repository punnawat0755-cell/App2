import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const int _maxInitialPeriodDays = 14;

  final _usernameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _lastPeriodController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _hidePw = true;

  DateTime? _birthday;
  DateTimeRange? _lastPeriodRange;
  String _sex = 'Female';

  static const _mainBlue = Color(0xFF4A89D8);
  static const _lightBlue = Color(0xFF64BFFF);
  static const _fieldGrey = Color(0xFFF3F3F3);

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: Colors.red),
    );
  }

  bool _isValidPhone(String phone) => RegExp(r'^\d{10}$').hasMatch(phone);

  Future<bool> _isUsernameTaken(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      return false;
    }

    try {
      final row = await supabase
          .from('profiles')
          .select('id')
          .ilike('username', normalized)
          .limit(1)
          .maybeSingle();
      return row != null;
    } on PostgrestException {
      // Skip pre-check when table access is blocked by RLS and rely on DB
      // unique constraints to catch duplicates.
      return false;
    }
  }

  String _prettyPostgrestMessage(PostgrestException error) {
    final code = (error.code ?? '').trim();
    final message = error.message.trim();
    final details = error.details?.toString().trim() ?? '';
    final hint = (error.hint ?? '').trim();
    final combined = '$message $details $hint'.toLowerCase();

    if (code == '23505') {
      if (combined.contains('username')) {
        return 'ชื่อนี้มีคนใช้แล้ว';
      }
      if (combined.contains('email')) {
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      }
      return 'ข้อมูลนี้ถูกใช้งานแล้ว';
    }

    if (message.isNotEmpty) {
      return message;
    }
    if (details.isNotEmpty) {
      return details;
    }
    if (hint.isNotEmpty) {
      return hint;
    }
    return 'บันทึกข้อมูลไม่สำเร็จ';
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

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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
    final pickedRange = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => _PeriodRangePickerDialog(
        firstDate: DateTime(1900),
        lastDate: DateTime(now.year, now.month, now.day),
      ),
    );

    if (pickedRange == null || !mounted) return;

    final safeRange = DateTimeRange(
      start: _dateOnly(pickedRange.start),
      end: _dateOnly(pickedRange.end),
    );
    final dayCount = _periodRangeDays(safeRange);
    if (dayCount > _maxInitialPeriodDays) {
      _showError('ช่วงประจำเดือนต้องไม่เกิน $_maxInitialPeriodDays วัน');
      return;
    }

    setState(() {
      _lastPeriodRange = safeRange;
      _lastPeriodController.text =
          '${_formatShortDate(safeRange.start)}-${_formatShortDate(safeRange.end)}';
    });
  }

  Future<void> _register() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim().toLowerCase();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      final missingRequiredFields = <String>[];
      if (username.isEmpty) {
        missingRequiredFields.add('ชื่อผู้ใช้งาน');
      }
      if (_birthday == null) {
        missingRequiredFields.add('วันเกิด');
      }
      if (_sex.trim().isEmpty) {
        missingRequiredFields.add('เพศ');
      }
      if (email.isEmpty) {
        missingRequiredFields.add('อีเมล');
      }
      if (password.isEmpty) {
        missingRequiredFields.add('รหัสผ่าน');
      }

      if (missingRequiredFields.isNotEmpty) {
        throw AuthException(
          'กรุณากรอกข้อมูลที่จำเป็นให้ครบ: '
          '${missingRequiredFields.join(', ')}',
        );
      }

      if (phone.isNotEmpty && !_isValidPhone(phone)) {
        throw const AuthException('เบอร์โทรศัพท์ต้องเป็นตัวเลข 10 หลัก');
      }

      final isTaken = await _isUsernameTaken(username);
      if (isTaken) {
        throw const AuthException('ชื่อนี้มีคนใช้แล้ว');
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

      final selectedPeriodRange = gender == 'female' ? _lastPeriodRange : null;

      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'gender': gender,
          'birth_date': _toIsoDate(_birthday!),
          'phone': phone,
          if (selectedPeriodRange != null)
            'last_period_start_date': _toIsoDate(selectedPeriodRange.start),
          if (selectedPeriodRange != null)
            'last_period_end_date': _toIsoDate(selectedPeriodRange.end),
          if (selectedPeriodRange != null) 'initial_period_seeded': false,
        },
      );

      if (res.user == null) {
        throw const AuthException('สมัครไม่สำเร็จ กรุณาลองใหม่');
      }

      final hasSession =
          res.session != null || supabase.auth.currentSession != null;
      if (hasSession && selectedPeriodRange != null) {
        final seeded = await _seedInitialPeriodToCalendar(selectedPeriodRange);
        if (seeded) {
          try {
            await supabase.auth.updateUser(
              UserAttributes(
                data: {
                  'last_period_start_date':
                      _toIsoDate(selectedPeriodRange.start),
                  'last_period_end_date': _toIsoDate(selectedPeriodRange.end),
                  'initial_period_seeded': true,
                },
              ),
            );
          } catch (_) {}
        }
      }
      if (hasSession) {
        try {
          await supabase.auth.signOut();
        } catch (_) {}
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _showError(_prettyPostgrestMessage(e));
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
              fontWeight: FontWeight.w500,
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
    List<TextInputFormatter>? inputFormatters,
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
        inputFormatters: inputFormatters,
        onTap: onTap,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF5D5D5D),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          // 💡 2. แก้ตรงนี้: เปลี่ยนเป็นสีเทาอ่อน BDBDBD
          hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
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
            borderRadius: BorderRadius.circular(20),
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
              _buildInputLabel('อีเมล', isRequired: true),
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
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
              const SizedBox(height: 30),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
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
                    style: TextStyle(color: Colors.grey, fontSize: 16),
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
    );
  }
}

class _PeriodRangePickerDialog extends StatefulWidget {
  const _PeriodRangePickerDialog({
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_PeriodRangePickerDialog> createState() =>
      _PeriodRangePickerDialogState();
}

class _PeriodRangePickerDialogState extends State<_PeriodRangePickerDialog> {
  DateTime? startDate;
  DateTime? endDate;
  late DateTime displayMonth;

  bool get _isPickingEnd => startDate != null && endDate == null;

  @override
  void initState() {
    super.initState();
    displayMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
  }

  String get _displayText {
    final fmt = DateFormat('EEE, MMM d');
    if (startDate == null) return fmt.format(widget.lastDate);
    if (endDate == null) return fmt.format(startDate!);
    return '${fmt.format(startDate!)} - ${fmt.format(endDate!)}';
  }

  void _onDatePicked(DateTime date) {
    setState(() {
      if (startDate == null || endDate != null) {
        startDate = date;
        endDate = null;
        displayMonth = DateTime(date.year, date.month);
        return;
      }

      if (date.isBefore(startDate!)) return;

      endDate = date;
      displayMonth = DateTime(date.year, date.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = startDate != null && endDate != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _displayText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: null,
                  icon: Icon(
                    Icons.edit,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.black.withValues(alpha: 0.12)),
            _RangeMonthCalendar(
              displayMonth: displayMonth,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              startDate: startDate,
              endDate: endDate,
              isPickingEnd: _isPickingEnd,
              onMonthChanged: (newMonth) {
                setState(() => displayMonth = newMonth);
              },
              onDayPicked: _onDatePicked,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: canSubmit
                        ? () => Navigator.of(context).pop(
                              DateTimeRange(start: startDate!, end: endDate!),
                            )
                        : null,
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeMonthCalendar extends StatelessWidget {
  const _RangeMonthCalendar({
    required this.displayMonth,
    required this.firstDate,
    required this.lastDate,
    required this.startDate,
    required this.endDate,
    required this.isPickingEnd,
    required this.onMonthChanged,
    required this.onDayPicked,
  });

  final DateTime displayMonth;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isPickingEnd;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDayPicked;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  DateTime _prevMonth(DateTime month) => DateTime(month.year, month.month - 1);

  DateTime _nextMonth(DateTime month) => DateTime(month.year, month.month + 1);

  bool _isMonthBefore(DateTime a, DateTime b) =>
      a.year < b.year || (a.year == b.year && a.month < b.month);

  bool _isMonthAfter(DateTime a, DateTime b) =>
      a.year > b.year || (a.year == b.year && a.month > b.month);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final firstMonth = _firstOfMonth(firstDate);
    final lastMonth = _firstOfMonth(lastDate);
    final canPrev = !_isMonthBefore(_prevMonth(displayMonth), firstMonth);
    final canNext = !_isMonthAfter(_nextMonth(displayMonth), lastMonth);

    final monthLabel = DateFormat('MMMM yyyy').format(displayMonth);
    final firstDayOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final daysInMonth = DateTime(
      displayMonth.year,
      displayMonth.month + 1,
      0,
    ).day;
    final firstDayOffset = firstDayOfMonth.weekday % 7;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      monthLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: canPrev
                    ? () => onMonthChanged(_prevMonth(displayMonth))
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: canNext
                    ? () => onMonthChanged(_nextMonth(displayMonth))
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Dow('S'),
              _Dow('M'),
              _Dow('T'),
              _Dow('W'),
              _Dow('T'),
              _Dow('F'),
              _Dow('S'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              DateTime normalize(DateTime d) =>
                  DateTime(d.year, d.month, d.day);
              bool isBeforeDay(DateTime a, DateTime b) =>
                  normalize(a).isBefore(normalize(b));
              bool isAfterDay(DateTime a, DateTime b) =>
                  normalize(a).isAfter(normalize(b));

              final rowWidth = constraints.maxWidth;
              final cellWidth = rowWidth / 7;
              const childAspectRatio = 1.15;
              final cellHeight = cellWidth / childAspectRatio;
              const rowSpacing = 8.0;
              const bandHeight = 36.0;

              final totalCells = firstDayOffset + daysInMonth;
              final rowCount = (totalCells + 6) ~/ 7;

              Widget buildDayCell(DateTime date, int day) {
                final isBeforeMin = isBeforeDay(
                  date,
                  DateTime(firstDate.year, firstDate.month, firstDate.day),
                );
                final isAfterMax = isAfterDay(
                  date,
                  DateTime(lastDate.year, lastDate.month, lastDate.day),
                );
                final isBeforeStart = isPickingEnd &&
                    startDate != null &&
                    isBeforeDay(
                      date,
                      DateTime(
                        startDate!.year,
                        startDate!.month,
                        startDate!.day,
                      ),
                    );
                final disabled = isBeforeMin || isAfterMax || isBeforeStart;

                final isStart =
                    startDate != null && _isSameDay(date, startDate!);
                final isEnd = endDate != null && _isSameDay(date, endDate!);

                final textColor = disabled
                    ? Colors.black.withValues(alpha: 0.28)
                    : Colors.black.withValues(alpha: 0.9);

                return GestureDetector(
                  onTap: disabled ? null : () => onDayPicked(date),
                  behavior: HitTestBehavior.opaque,
                  child: Align(
                    alignment: Alignment.center,
                    child: (isStart || isEnd)
                        ? Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$day',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : Text(
                            '$day',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                );
              }

              return Column(
                children: List.generate(rowCount, (row) {
                  final rowDates = List<DateTime?>.generate(7, (col) {
                    final index = row * 7 + col;
                    if (index < firstDayOffset) return null;
                    final day = index - firstDayOffset + 1;
                    if (day < 1 || day > daysInMonth) return null;
                    return DateTime(displayMonth.year, displayMonth.month, day);
                  });

                  final rowFirst = rowDates.firstWhere(
                    (d) => d != null,
                    orElse: () => null,
                  );
                  final rowLast = rowDates.lastWhere(
                    (d) => d != null,
                    orElse: () => null,
                  );

                  Widget? rangeBand;
                  if (startDate != null &&
                      endDate != null &&
                      rowFirst != null &&
                      rowLast != null) {
                    final dpr = MediaQuery.of(context).devicePixelRatio;
                    double snap(double v) => (v * dpr).round() / dpr;

                    final startN = normalize(startDate!);
                    final endN = normalize(endDate!);
                    final rowFirstN = normalize(rowFirst);
                    final rowLastN = normalize(rowLast);

                    if (!isAfterDay(startN, rowLastN) &&
                        !isBeforeDay(endN, rowFirstN)) {
                      final segStart =
                          isBeforeDay(startN, rowFirstN) ? rowFirstN : startN;
                      final segEnd =
                          isAfterDay(endN, rowLastN) ? rowLastN : endN;

                      final segStartCol = rowDates.indexWhere(
                        (d) => d != null && _isSameDay(d, segStart),
                      );
                      final segEndCol = rowDates.lastIndexWhere(
                        (d) => d != null && _isSameDay(d, segEnd),
                      );

                      if (segStartCol >= 0 && segEndCol >= segStartCol) {
                        final top = (cellHeight - bandHeight) / 2;
                        var left = rowWidth * (segStartCol / 7);
                        var right = rowWidth * ((segEndCol + 1) / 7);

                        left = snap(left);
                        right = snap(right);

                        if (right > left) {
                          rangeBand = Positioned(
                            left: left,
                            width: right - left,
                            top: top,
                            height: bandHeight,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFFCEEFFE),
                                borderRadius: BorderRadius.horizontal(
                                  left: _isSameDay(segStart, startN)
                                      ? const Radius.circular(18)
                                      : Radius.zero,
                                  right: _isSameDay(segEnd, endN)
                                      ? const Radius.circular(18)
                                      : Radius.zero,
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    }
                  }

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: row == rowCount - 1 ? 0 : rowSpacing,
                    ),
                    child: SizedBox(
                      height: cellHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          if (rangeBand != null) rangeBand,
                          Row(
                            children: List.generate(7, (col) {
                              final date = rowDates[col];
                              if (date == null) {
                                return const Expanded(child: SizedBox.expand());
                              }

                              return Expanded(
                                child: buildDayCell(date, date.day),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Dow extends StatelessWidget {
  const _Dow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

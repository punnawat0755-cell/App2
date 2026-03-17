import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter_application_1/module/user_Profile/app_user_controller.dart';

// ==========================================
// 💡 1. SignupController (จัดการ Logic ทั้งหมด)
// ==========================================
class SignupController extends GetxController {
  final RxString selectedGender = 'หญิง'.obs;

  late final TextEditingController birthdayController;
  late final TextEditingController lastPeriodController;

  @override
  void onInit() {
    super.onInit();
    birthdayController = TextEditingController();
    lastPeriodController = TextEditingController();
  }

  @override
  void onClose() {
    birthdayController.dispose();
    lastPeriodController.dispose();
    super.onClose();
  }

  void setGender(String gender) {
    selectedGender.value = gender;
  }

  // เลือกวันเกิด (แบบวันเดียว)
  Future<void> pickBirthday(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    birthdayController.text = DateFormat('dd/MM/yyyy').format(picked);
  }

  // 💡 เลือกช่วงประจำเดือน (แบบ Popup มีแถบเชื่อมสีฟ้า)
  Future<void> pickLastPeriodRange(BuildContext context) async {
    final now = DateTime.now();
    final pickedRange = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => _PeriodRangePickerDialog(
        firstDate: DateTime(1950),
        lastDate: DateTime(now.year, now.month, now.day),
      ),
    );
    if (pickedRange == null) return;

    final fmt = DateFormat('dd/MM/yy');
    lastPeriodController.text =
        '${fmt.format(pickedRange.start)}-${fmt.format(pickedRange.end)}';
  }
} // 👈 ปิด SignupController ให้ถูกต้อง

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

  String get _headerText {
    if (startDate == null) return 'Select start date';
    if (endDate == null) return 'Select end date';
    return 'Select date';
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayText,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                        ? () => Navigator.of(
                            context,
                          ).pop(DateTimeRange(start: startDate!, end: endDate!))
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

  final DateTime displayMonth; // yyyy-mm-01
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isPickingEnd;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDayPicked;

  static const _rangeFill = Color(0xFFC7E9FF);

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
    final firstDayOffset = firstDayOfMonth.weekday % 7; // Sunday = 0

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
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
                final isBeforeStart =
                    isPickingEnd &&
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
                      final segStart = isBeforeDay(startN, rowFirstN)
                          ? rowFirstN
                          : startN;
                      final segEnd = isAfterDay(endN, rowLastN)
                          ? rowLastN
                          : endN;

                      final segStartCol = rowDates.indexWhere(
                        (d) => d != null && _isSameDay(d, segStart),
                      );
                      final segEndCol = rowDates.lastIndexWhere(
                        (d) => d != null && _isSameDay(d, segEnd),
                      );

                      if (segStartCol >= 0 && segEndCol >= segStartCol) {
                        final top = (cellHeight - bandHeight) / 2;

                        // ทำให้แถบสี "ติดกันสนิท" และอยู่ "ทับหลังวันเริ่ม-จบ"
                        // คำนวณเป็นสัดส่วนของความกว้างทั้งแถวเพื่อเลี่ยงช่องว่างจากเศษพิกเซล
                        var left = rowWidth * (segStartCol / 7);
                        var right = rowWidth * ((segEndCol + 1) / 7);

                        left = snap(left);
                        right = snap(right);

                        if (right <= left) {
                          rangeBand = null;
                        } else {
                          final width = right - left;

                          rangeBand = Positioned(
                            left: left,
                            width: width,
                            top: top,
                            height: bandHeight,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _rangeFill,
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

// ==========================================
// 💡 2. Signup UI (หน้าจอลงทะเบียน)
// ==========================================
class Signup extends StatelessWidget {
  Signup({super.key});

  final SignupController controller = Get.isRegistered<SignupController>()
      ? Get.find<SignupController>()
      : Get.put(SignupController());

  @override
  Widget build(BuildContext context) {
    const Color mainBlue = Color(0xFF4A89D8);
    const Color lightBlue = Color(0xFF64BFFF);
    const Color fieldGrey = Color(0xFFF3F3F3);

    return Obx(
      () => Scaffold(
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
                    color: mainBlue,
                  ),
                ),
                const SizedBox(height: 30),
                _buildInputLabel('ชื่อผู้ใช้งาน', isRequired: true),
                _buildTextField(hintText: 'แมวน้ำ', fillColor: fieldGrey),
                _buildInputLabel('วันเกิด', isRequired: true),
                _buildTextField(
                  controller: controller.birthdayController,
                  hintText: '17/12/2004',
                  fillColor: fieldGrey,
                  suffixAssetPath: 'assets/images/calendar.png',
                  readOnly: true,
                  onTap: () => controller.pickBirthday(context),
                  suffixOnTap: () => controller.pickBirthday(context),
                ),
                _buildInputLabel('เพศ', isRequired: true),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGenderButton(context, 'ชาย'),
                    _buildGenderButton(context, 'หญิง'),
                    _buildGenderButton(context, 'LGBTQ+'),
                  ],
                ),
                const SizedBox(height: 15),
                _buildInputLabel('อีเมล'),
                _buildTextField(hintText: '', fillColor: fieldGrey),
                _buildInputLabel('เบอร์โทรศัพท์'),
                _buildTextField(hintText: '', fillColor: fieldGrey),
                _buildInputLabel('รหัสผ่าน', isRequired: true),
                _buildTextField(
                  hintText: '',
                  fillColor: fieldGrey,
                  isPassword: true,
                ),
                // 💡 แสดงเฉพาะถ้าเลือกเพศหญิง
                if (controller.selectedGender.value == 'หญิง') ...[
                  _buildInputLabel('ประจำเดือนครั้งล่าสุด'),
                  _buildTextField(
                    controller: controller.lastPeriodController,
                    hintText: 'dd/mm/yyyy - dd/mm/yyyy',
                    fillColor: fieldGrey,
                    suffixAssetPath: 'assets/images/calendar.png',
                    readOnly: true,
                    onTap: () => controller.pickLastPeriodRange(context),
                    suffixOnTap: () => controller.pickLastPeriodRange(context),
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      final userController =
                          Get.isRegistered<AppUserController>()
                          ? Get.find<AppUserController>()
                          : Get.put(AppUserController(), permanent: true);
                      userController.gender.value =
                          controller.selectedGender.value;
                      debugPrint(
                        'ลงทะเบียนเรียบร้อย: ${controller.lastPeriodController.text}',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lightBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
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
                      onTap: () => Get.back(),
                      child: const Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(
                          color: lightBlue,
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
      ),
    );
  }

  // --- Widget ตัวช่วยสร้าง UI ---
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
    TextEditingController? controller,
    required String hintText,
    required Color fillColor,
    String? suffixAssetPath,
    bool isPassword = false,
    bool readOnly = false,
    VoidCallback? onTap,
    VoidCallback? suffixOnTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black54),
          suffixIcon: suffixAssetPath != null
              ? IconButton(
                  onPressed: suffixOnTap ?? onTap,
                  icon: Image.asset(
                    suffixAssetPath,
                    width: 20,
                    height: 20,
                    color: Colors.grey,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderButton(BuildContext context, String gender) {
    return Obx(() {
      final bool isSelected = controller.selectedGender.value == gender;
      return GestureDetector(
        onTap: () => controller.setGender(gender),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.25,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFC7E9FF) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF64BFFF)
                  : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              gender,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4A89D8) : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    });
  }
}

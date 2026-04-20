import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/features/profile/controller/profile_avatar_controller.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late final ProfileAvatarController _avatarController;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _didChangeProfile = false;
  String? _activeField;
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  String _username = 'แมวน้ำ';
  String _gender = 'female';
  DateTime? _birthDate;
  String _email = '';
  String _phone = '';

  bool _isValidPhone(String phone) => RegExp(r'^\d{10}$').hasMatch(phone);

  Future<bool> _isUsernameTakenByOtherUser({
    required String username,
    required String currentUserId,
  }) async {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      return false;
    }

    try {
      final row = await _supabase
          .from('profiles')
          .select('id')
          .neq('id', currentUserId)
          .ilike('username', normalized)
          .limit(1)
          .maybeSingle();
      return row != null;
    } on PostgrestException {
      // If lookup is blocked by RLS, continue and rely on unique constraints.
      return false;
    }
  }

  String _prettyAuthMessage(String message) {
    final m = message.toLowerCase();
    if (m.contains('user already registered')) {
      return 'อีเมลนี้ถูกใช้งานแล้ว';
    }
    if (m.contains('email address is invalid')) {
      return 'อีเมลไม่ถูกต้อง';
    }
    if (m.contains('only request this after')) {
      return 'คุณกดทำรายการซ้ำเร็วเกินไป กรุณารอสักครู่แล้วลองใหม่';
    }
    return message;
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

  @override
  void initState() {
    super.initState();
    _avatarController = Get.isRegistered<ProfileAvatarController>()
        ? Get.find<ProfileAvatarController>()
        : Get.put(ProfileAvatarController());
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final row = await _supabase
          .from('profiles')
          .select('username, gender, birth_date, phone')
          .eq('id', user.id)
          .maybeSingle();

      final metadata = user.userMetadata ?? const <String, dynamic>{};

      if (!mounted) {
        return;
      }

      setState(() {
        _username = _firstNonEmpty([
              row?['username'],
              metadata['username'],
              metadata['name'],
              metadata['display_name'],
              user.email?.split('@').first,
            ]) ??
            'แมวน้ำ';
        _gender = _normalizeGender(row?['gender'] ?? metadata['gender']);
        _birthDate = _parseDate(row?['birth_date'] ?? metadata['birth_date']);
        _email = user.email?.trim() ?? '';
        _phone = _firstNonEmpty([
              row?['phone'],
              metadata['phone'],
            ]) ??
            '';

        _nameController.text = _username;
        _emailController.text = _email;
        _phoneController.text = _phone;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _email = user.email?.trim() ?? '';
        _emailController.text = _email;
        _isLoading = false;
      });

      Get.snackbar(
        'โหลดข้อมูลไม่สำเร็จ',
        '$error',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _birthDate = picked;
      _activeField = 'birth';
    });
  }

  Future<void> _saveActiveField() async {
    final user = _supabase.auth.currentUser;
    if (user == null || _isSaving || _activeField == null) {
      return;
    }

    String? nextEmail;

    switch (_activeField) {
      case 'name':
        final value = _nameController.text.trim();
        if (value.isEmpty) {
          _showError('กรุณากรอกชื่อผู้ใช้');
          return;
        }
        final isTaken = await _isUsernameTakenByOtherUser(
          username: value,
          currentUserId: user.id,
        );
        if (isTaken) {
          _showError('ชื่อนี้มีคนใช้แล้ว');
          return;
        }
        _username = value;
        break;
      case 'gender':
        break;
      case 'birth':
        if (_birthDate == null) {
          _showError('กรุณาเลือกวันเกิด');
          return;
        }
        break;
      case 'email':
        final value = _emailController.text.trim().toLowerCase();
        if (value.isEmpty || !value.contains('@')) {
          _showError('กรุณากรอกอีเมลให้ถูกต้อง');
          return;
        }
        nextEmail = value;
        _email = value;
        break;
      case 'phone':
        final value = _phoneController.text.trim();
        if (value.isNotEmpty && !_isValidPhone(value)) {
          _showError('เบอร์โทรศัพท์ต้องเป็นตัวเลข 10 หลัก');
          return;
        }
        _phone = value;
        break;
      case 'password':
        return;
    }

    setState(() => _isSaving = true);

    try {
      final profilePayload = <String, dynamic>{
        'id': user.id,
        'username': _username,
        'gender': _gender,
        'birth_date': _birthDate == null
            ? null
            : DateFormat('yyyy-MM-dd').format(_birthDate!),
        'phone': _phone,
      };

      await _supabase.from('profiles').upsert(profilePayload);

      await _supabase.auth.updateUser(
        UserAttributes(
          email: nextEmail,
          data: <String, dynamic>{
            'username': _username,
            'gender': _gender,
            'birth_date': profilePayload['birth_date'],
            'phone': _phone,
          },
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _didChangeProfile = true;
        _activeField = null;
      });

      Get.snackbar(
        nextEmail != null ? 'อัปเดตอีเมลแล้ว' : 'บันทึกข้อมูลแล้ว',
        nextEmail != null
            ? 'ถ้าระบบให้ยืนยันอีเมล โปรดตรวจกล่องข้อความของคุณ'
            : 'ข้อมูลส่วนตัวถูกอัปเดตเรียบร้อย',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } on PostgrestException catch (error) {
      _showError(_prettyPostgrestMessage(error));
    } on AuthException catch (error) {
      _showError(_prettyAuthMessage(error.message));
    } catch (error) {
      _showError('บันทึกไม่สำเร็จ: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showAvatarPicker() async {
    var pendingAvatar = _avatarController.avatarUrl.value;
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
                  final crossAxisCount = constraints.maxWidth < 360 ? 3 : 4;
                  final spacing = scale.rs(14, min: 10, max: 14);
                  final canSubmit =
                      !isSubmitting && !_avatarController.isSaving.value;

                  Future<void> submitSelection() async {
                    if (!canSubmit) {
                      return;
                    }

                    if (pendingAvatar == _avatarController.avatarUrl.value) {
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                      return;
                    }

                    setModalState(() => isSubmitting = true);
                    final saved = await _avatarController.saveAvatar(
                      pendingAvatar,
                    );
                    if (!sheetContext.mounted) {
                      return;
                    }

                    if (saved) {
                      _didChangeProfile = true;
                      Navigator.of(sheetContext).pop();
                      return;
                    }

                    setModalState(() => isSubmitting = false);
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      scale.rs(24, min: 16, max: 24),
                      scale.rs(10, min: 8, max: 12),
                      scale.rs(24, min: 16, max: 24),
                      scale.rs(28, min: 20, max: 28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: scale.rs(78, min: 64, max: 78),
                            height: scale.rs(7, min: 5, max: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC7C7C7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        SizedBox(height: scale.rs(16, min: 12, max: 16)),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'เลือกรูปโปรไฟล์',
                                style: GoogleFonts.mitr(
                                  textStyle: TextStyle(
                                    color: const Color(0xFF4489D7),
                                    fontSize: scale.rf(18, min: 17, max: 20),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            FilledButton(
                              onPressed: canSubmit ? submitSelection : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2FB8F5),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: scale.rs(20, min: 16, max: 20),
                                  vertical: scale.rs(10, min: 8, max: 10),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: isSubmitting
                                  ? SizedBox(
                                      width: scale.rs(18, min: 16, max: 18),
                                      height: scale.rs(18, min: 16, max: 18),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'ตกลง',
                                      style: GoogleFonts.mitr(
                                        textStyle: TextStyle(
                                          fontSize:
                                              scale.rf(16, min: 14, max: 16),
                                          fontWeight: FontWeight.w600,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        SizedBox(height: scale.rs(18, min: 12, max: 18)),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _avatarController.avatarOptions.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                          ),
                          itemBuilder: (context, index) {
                            final avatarPath =
                                _avatarController.avatarOptions[index];
                            final isSelected = pendingAvatar == avatarPath;

                            return GestureDetector(
                              onTap: isSubmitting
                                  ? null
                                  : () {
                                      setModalState(
                                        () => pendingAvatar = avatarPath,
                                      );
                                    },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF9EDCF8)
                                        : Colors.transparent,
                                    width: scale.rs(3, min: 2, max: 3),
                                  ),
                                ),
                                padding: EdgeInsets.all(
                                  scale.rs(4, min: 2, max: 4),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: AssetImage(avatarPath),
                                    ),
                                    if (isSelected)
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: CircleAvatar(
                                          radius:
                                              scale.rs(12, min: 10, max: 12),
                                          backgroundColor:
                                              const Color(0xFF8D8D8D),
                                          child: Icon(
                                            Icons.check,
                                            size:
                                                scale.rs(14, min: 12, max: 14),
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _activateField(String field) {
    setState(() {
      _activeField = field;
      if (field == 'name') {
        _nameController.text = _username;
      } else if (field == 'email') {
        _emailController.text = _email;
      } else if (field == 'phone') {
        _phoneController.text = _phone;
      }
    });
  }

  void _resetPasswordForm() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _showOldPassword = false;
    _showNewPassword = false;
    _showConfirmPassword = false;
  }

  Future<void> _savePasswordChange(StateSetter setModalState) async {
    final user = _supabase.auth.currentUser;
    if (user == null || _isSaving) {
      return;
    }

    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showError('กรุณากรอกข้อมูลให้ครบ');
      return;
    }

    if (newPassword.length < 6) {
      _showError('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
      return;
    }

    if (newPassword != confirmPassword) {
      _showError('รหัสผ่านใหม่และยืนยันรหัสผ่านไม่ตรงกัน');
      return;
    }

    setState(() => _isSaving = true);
    setModalState(() {});

    try {
      await _supabase.auth.signInWithPassword(
        email: _email,
        password: oldPassword,
      );

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (!mounted) {
        return;
      }

      _didChangeProfile = true;
      _resetPasswordForm();
      Navigator.of(context).pop();
      Get.snackbar(
        'เปลี่ยนรหัสผ่านแล้ว',
        'ข้อมูลส่วนตัวถูกอัปเดตเรียบร้อย',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (error) {
      _showError('$error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'บันทึกไม่สำเร็จ',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _showPasswordPanel() async {
    _resetPasswordForm();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final scale = ResponsiveScale.fromWidth(
              MediaQuery.sizeOf(context).width,
            );

            return SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  scale.rs(24, min: 18, max: 24),
                  scale.rs(12, min: 10, max: 12),
                  scale.rs(24, min: 18, max: 24),
                  scale.rs(16, min: 12, max: 18),
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: scale.rs(45, min: 40, max: 45),
                        height: scale.rs(5, min: 4, max: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    SizedBox(height: scale.rs(18, min: 14, max: 18)),
                    Text(
                      'แก้ไขรหัสผ่าน',
                      style: GoogleFonts.mitr(
                        textStyle: TextStyle(
                          color: const Color(0xFF4489D7),
                          fontSize: scale.rf(20, min: 18, max: 20),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: scale.rs(16, min: 12, max: 16)),
                    _buildPasswordField(
                      scale: scale,
                      label: 'กรุณาใส่รหัสเดิม',
                      controller: _oldPasswordController,
                      isVisible: _showOldPassword,
                      onToggle: () => setModalState(
                        () => _showOldPassword = !_showOldPassword,
                      ),
                    ),
                    SizedBox(height: scale.rs(12, min: 10, max: 12)),
                    _buildPasswordField(
                      scale: scale,
                      label: 'กรุณาใส่รหัสใหม่',
                      controller: _newPasswordController,
                      isVisible: _showNewPassword,
                      onToggle: () => setModalState(
                        () => _showNewPassword = !_showNewPassword,
                      ),
                    ),
                    SizedBox(height: scale.rs(12, min: 10, max: 12)),
                    _buildPasswordField(
                      scale: scale,
                      label: 'กรุณายืนยันรหัส',
                      controller: _confirmPasswordController,
                      isVisible: _showConfirmPassword,
                      onToggle: () => setModalState(
                        () => _showConfirmPassword = !_showConfirmPassword,
                      ),
                    ),
                    SizedBox(height: scale.rs(24, min: 20, max: 28)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () => _savePasswordChange(setModalState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF20C2FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: scale.rs(14, min: 12, max: 14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'บันทึก',
                                style: GoogleFonts.mitr(
                                  textStyle: TextStyle(
                                    fontSize: scale.rf(16, min: 15, max: 16),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appScale = context.responsive;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Get.back(result: _didChangeProfile);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: appScale.rs(45, min: 40, max: 45),
          titleSpacing: 2,
          leading: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.back(result: _didChangeProfile),
            child: Padding(
              padding: EdgeInsets.only(left: appScale.rs(5, min: 8, max: 10)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/images/back.png',
                  width: appScale.rs(25, min: 21, max: 25),
                  height: appScale.rs(25, min: 21, max: 25),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          title: Text(
            'แก้ไขข้อมูล',
            style: GoogleFonts.mitr(
              textStyle: TextStyle(
                color: const Color(0xFF4B88D8),
                fontSize: appScale.rf(22, min: 19, max: 22),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final scale =
                        ResponsiveScale.fromWidth(constraints.maxWidth);
                    final horizontalPadding = constraints.maxWidth < 360
                        ? scale.rs(18, min: 14, max: 22)
                        : scale.rs(30, min: 24, max: 30);
                    // final avatarRadius = scale.rs(85, min: 62, max: 75);
                    // final editIconSize = scale.rs(28, min: 22, max: 28);

                    final double avatarRadius = 85.0;
                    final editIconSize = scale.rs(28, min: 22, max: 28);

                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            scale.rs(10, min: 8, max: 12), // ลดระยะขอบบนลง
                            horizontalPadding,
                            scale.rs(28, min: 22, max: 28),
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: scale.rs(16, min: 20, max: 30)),
                              Obx(
                                () => Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius:
                                                scale.rs(10, min: 8, max: 10),
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: avatarRadius,
                                        // backgroundColor: Colors.grey.shade200,
                                        backgroundImage: _avatarController
                                            .avatarImageProvider,
                                      ),
                                    ),
                                    Positioned(
                                      right: 7,
                                      bottom: scale.rs(0, min: 4, max: 8),
                                      child: GestureDetector(
                                        onTap: _showAvatarPicker,
                                        child: Image.asset(
                                          'assets/images/loop.png',
                                          width: scale.rs(40, min: 40, max: 52),
                                          height:
                                              scale.rs(40, min: 40, max: 52),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: scale.rs(28, min: 20, max: 28)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_activeField == 'name')
                                    SizedBox(
                                      width: scale.rs(180, min: 138, max: 190),
                                      child: TextField(
                                        controller: _nameController,
                                        autofocus: true,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.mitr(
                                          textStyle: TextStyle(
                                            color: const Color(0xFF4B88D8),
                                            fontSize:
                                                scale.rf(22, min: 18, max: 22),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      _username,
                                      style: GoogleFonts.mitr(
                                        textStyle: TextStyle(
                                          color: const Color(0xFF4B88D8),
                                          fontSize:
                                              scale.rf(22, min: 18, max: 22),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  SizedBox(width: scale.rs(8, min: 6, max: 8)),
                                  GestureDetector(
                                    onTap: () => _activateField('name'),
                                    child: Icon(
                                      Icons.edit,
                                      color: const Color(0xFF8A8A8A),
                                      size: editIconSize,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: scale.rs(30, min: 20, max: 30)),
                              _buildInfoCard(
                                scale: scale,
                                label: 'เพศ :',
                                value: _displayGender(_gender),
                                fieldKey: 'gender',
                                icon: Icons.edit,
                              ),
                              if (_activeField == 'gender')
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: scale.rs(14, min: 10, max: 14),
                                    bottom: scale.rs(4, min: 2, max: 4),
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: scale.rs(18, min: 10, max: 18),
                                    runSpacing: scale.rs(10, min: 6, max: 10),
                                    children: [
                                      _buildGenderChip('male', 'ชาย', scale),
                                      _buildGenderChip('female', 'หญิง', scale),
                                    ],
                                  ),
                                ),
                              SizedBox(height: scale.rs(18, min: 12, max: 18)),
                              _buildInfoCard(
                                scale: scale,
                                label: 'วันเกิด :',
                                value: _birthDate == null
                                    ? 'ยังไม่ได้เลือก'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(_birthDate!),
                                fieldKey: 'birth',
                                icon: Icons.calendar_month_outlined,
                                onIconTap: _selectBirthDate,
                              ),
                              SizedBox(height: scale.rs(18, min: 12, max: 18)),
                              _buildInfoCard(
                                scale: scale,
                                label: 'รหัส :',
                                value: '******',
                                fieldKey: 'password',
                                icon: Icons.edit,
                                onIconTap: _showPasswordPanel,
                              ),
                              SizedBox(height: scale.rs(18, min: 12, max: 18)),
                              _buildInfoCard(
                                scale: scale,
                                label: 'อีเมล :',
                                value: _activeField == 'email'
                                    ? null
                                    : _maskEmail(_email),
                                fieldKey: 'email',
                                icon: Icons.edit,
                                editor: TextField(
                                  controller: _emailController,
                                  autofocus: true,
                                  keyboardType: TextInputType.emailAddress,
                                  style: _cardTextStyle(scale),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              SizedBox(height: scale.rs(18, min: 12, max: 18)),
                              _buildInfoCard(
                                scale: scale,
                                label: 'เบอร์โทรศัพท์ :',
                                value: _activeField == 'phone'
                                    ? null
                                    : _maskPhone(_phone),
                                fieldKey: 'phone',
                                icon: Icons.edit,
                                editor: TextField(
                                  controller: _phoneController,
                                  autofocus: true,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  style: _cardTextStyle(scale),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_activeField != null) ...[
                                SizedBox(
                                  height: scale.rs(30, min: 20, max: 30),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isSaving ? null : _saveActiveField,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF20C2FF),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(
                                        vertical:
                                            scale.rs(14, min: 12, max: 14),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'บันทึก',
                                            style: GoogleFonts.mitr(
                                              textStyle: TextStyle(
                                                fontSize: scale.rf(16,
                                                    min: 15, max: 16),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard({
    required ResponsiveScale scale,
    required String label,
    required String fieldKey,
    required IconData icon,
    String? value,
    Widget? editor,
    VoidCallback? onIconTap,
  }) {
    final isActive = _activeField == fieldKey;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: scale.rs(78, min: 64, max: 78),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: scale.rs(20, min: 16, max: 20),
        vertical: scale.rs(16, min: 14, max: 16),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFCEEFFE),
        borderRadius: BorderRadius.circular(scale.rs(20, min: 18, max: 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: scale.rs(4, min: 3, max: 4),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.mitr(
              textStyle: TextStyle(
                color: const Color(0xFF4B88D8),
                fontSize: scale.rf(18, min: 15, max: 18),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: scale.rs(16, min: 10, max: 16)),
          Expanded(
            child: isActive && editor != null
                ? editor
                : Text(
                    value ?? '',
                    style: _cardTextStyle(scale),
                  ),
          ),
          GestureDetector(
            onTap: onIconTap ?? () => _activateField(fieldKey),
            child: Icon(
              icon,
              color: const Color(0xFF8A8A8A),
              size: scale.rs(24, min: 22, max: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String value, String label, ResponsiveScale scale) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        constraints: BoxConstraints(minWidth: scale.rs(98, min: 86, max: 98)),
        padding: EdgeInsets.symmetric(
          horizontal: scale.rs(18, min: 12, max: 18),
          vertical: scale.rs(9, min: 6, max: 9),
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB5EFFF) : Colors.white,
          borderRadius: BorderRadius.circular(scale.rs(22, min: 16, max: 22)),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF7FBFDD) : const Color(0xFF8D8D8D),
            width: 1.2,
          ),
        ),
        child: Text(
          textAlign: TextAlign.center,
          label,
          style: GoogleFonts.mitr(
            textStyle: TextStyle(
              color: const Color(0xFF8A8A8A),
              fontSize: scale.rf(15, min: 13, max: 15),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required ResponsiveScale scale,
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'[a-zA-Z0-9!@#\$%\^&\*\(\)_\+\-=]'),
        ),
      ],
      style: GoogleFonts.mitr(
        textStyle: TextStyle(
          color: const Color(0xFF4B88D8),
          fontSize: scale.rf(16, min: 14, max: 16),
          fontWeight: FontWeight.w500,
        ),
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.mitr(
          textStyle: TextStyle(
            color: const Color(0xFF9AA9B5),
            fontSize: scale.rf(15, min: 13, max: 15),
            fontWeight: FontWeight.w500,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF3F8FC),
        contentPadding: EdgeInsets.symmetric(
          horizontal: scale.rs(16, min: 14, max: 16),
          vertical: scale.rs(14, min: 12, max: 14),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF8A8A8A),
          ),
        ),
      ),
    );
  }

  TextStyle _cardTextStyle(ResponsiveScale scale) {
    return GoogleFonts.mitr(
      textStyle: TextStyle(
        color: const Color(0xFF4B88D8),
        fontSize: scale.rf(18, min: 15, max: 18),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _displayGender(String value) {
    switch (value) {
      case 'male':
        return 'ชาย';
      case 'female':
        return 'หญิง';
      default:
        return 'LGBTQ+';
    }
  }

  String _normalizeGender(dynamic value) {
    final text = value?.toString().trim().toLowerCase();
    switch (text) {
      case 'male':
      case 'man':
      case 'm':
      case 'ผู้ชาย':
        return 'male';
      case 'female':
      case 'woman':
      case 'f':
      case 'ผู้หญิง':
        return 'female';
      case 'lgbtq+':
      case 'lgbtq':
      case 'other':
      case 'non-binary':
      case 'nonbinary':
      case 'queer':
      default:
        return 'other';
    }
  }

  DateTime? _parseDate(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    final prefix = parts.isNotEmpty ? parts.first.trim() : '';
    final domain = parts.length > 1 ? parts[1] : '';

    if (prefix.isEmpty) {
      return '-';
    }

    if (prefix.length <= 3) {
      return '$prefix@$domain';
    }

    return '${prefix.substring(0, 3)}****@$domain';
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty) {
      return '-';
    }

    if (phone.length <= 4) {
      return phone;
    }

    return '${phone.substring(0, phone.length - 3)}***';
  }
}

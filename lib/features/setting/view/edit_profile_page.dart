import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _passwordController = TextEditingController();

  late final ProfileAvatarController _avatarController;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _didChangeProfile = false;
  String? _activeField;

  String _username = 'แมวน้ำ';
  String _gender = 'female';
  DateTime? _birthDate;
  String _email = '';
  String _phone = '';

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
    _passwordController.dispose();
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
        _passwordController.clear();
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

    String? nextPassword;
    String? nextEmail;

    switch (_activeField) {
      case 'name':
        final value = _nameController.text.trim();
        if (value.isEmpty) {
          _showError('กรุณากรอกชื่อผู้ใช้');
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
        final value = _emailController.text.trim();
        if (value.isEmpty || !value.contains('@')) {
          _showError('กรุณากรอกอีเมลให้ถูกต้อง');
          return;
        }
        nextEmail = value;
        _email = value;
        break;
      case 'phone':
        _phone = _phoneController.text.trim();
        break;
      case 'password':
        final value = _passwordController.text.trim();
        if (value.length < 6) {
          _showError('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
          return;
        }
        nextPassword = value;
        break;
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
          password: nextPassword,
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
        _passwordController.clear();
      });

      Get.snackbar(
        nextEmail != null
            ? 'อัปเดตอีเมลแล้ว'
            : nextPassword != null
                ? 'เปลี่ยนรหัสผ่านแล้ว'
                : 'บันทึกข้อมูลแล้ว',
        nextEmail != null
            ? 'ถ้าระบบให้ยืนยันอีเมล โปรดตรวจกล่องข้อความของคุณ'
            : 'ข้อมูลส่วนตัวถูกอัปเดตเรียบร้อย',
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

  Future<void> _showAvatarPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Obx(
              () {
                final selectedAvatar = _avatarController.avatarUrl.value;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เลือกรูปโปรไฟล์',
                      style: GoogleFonts.mitr(
                        textStyle: const TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _avatarController.avatarOptions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        final avatarPath =
                            _avatarController.avatarOptions[index];
                        final isSelected = selectedAvatar == avatarPath;

                        return GestureDetector(
                          onTap: () async {
                            await _avatarController.saveAvatar(avatarPath);
                            _didChangeProfile = true;
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4489D7)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: CircleAvatar(
                              backgroundImage: AssetImage(avatarPath),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
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
      } else if (field == 'password') {
        _passwordController.clear();
      }
    });
  }

  void _showError(String message) {
    Get.snackbar(
      'บันทึกไม่สำเร็จ',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          leadingWidth: 44,
          titleSpacing: 0,
          leading: IconButton(
            onPressed: () => Get.back(result: _didChangeProfile),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF7E7E7E),
              size: 24,
            ),
          ),
          title: Text(
            'แก้ไขข้อมูล',
            style: GoogleFonts.mitr(
              textStyle: const TextStyle(
                color: Color(0xFF4B88D8),
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      Obx(
                        () => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 100,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage:
                                  _avatarController.avatarImageProvider,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 8,
                              child: GestureDetector(
                                onTap: _showAvatarPicker,
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0E0E0),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.sync_alt_rounded,
                                    color: Color(0xFF8A8A8A),
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_activeField == 'name')
                            SizedBox(
                              width: 180,
                              child: TextField(
                                controller: _nameController,
                                autofocus: true,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.mitr(
                                  textStyle: const TextStyle(
                                    color: Color(0xFF4B88D8),
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
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
                                textStyle: const TextStyle(
                                  color: Color(0xFF4B88D8),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _activateField('name'),
                            child: const Icon(
                              Icons.edit,
                              color: Color(0xFF8A8A8A),
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _buildInfoCard(
                        label: 'เพศ :',
                        value: _displayGender(_gender),
                        fieldKey: 'gender',
                        icon: Icons.edit,
                      ),
                      if (_activeField == 'gender')
                        Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 4),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 18,
                            runSpacing: 10,
                            children: [
                              _buildGenderChip('male', 'ชาย'),
                              _buildGenderChip('female', 'หญิง'),
                              _buildGenderChip('other', 'LGBTQ+'),
                            ],
                          ),
                        ),
                      const SizedBox(height: 18),
                      _buildInfoCard(
                        label: 'วันเกิด :',
                        value: _birthDate == null
                            ? 'ยังไม่ได้เลือก'
                            : DateFormat('dd/MM/yyyy').format(_birthDate!),
                        fieldKey: 'birth',
                        icon: Icons.calendar_month_outlined,
                        onIconTap: _selectBirthDate,
                      ),
                      const SizedBox(height: 18),
                      _buildInfoCard(
                        label: 'รหัส :',
                        value: _activeField == 'password'
                            ? null
                            : (_passwordController.text.trim().isEmpty
                                ? '******'
                                : _passwordController.text.trim()),
                        fieldKey: 'password',
                        icon: Icons.edit,
                        editor: TextField(
                          controller: _passwordController,
                          autofocus: true,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9!@#\$%\^&\*\(\)_\+\-=]'),
                            ),
                          ],
                          style: _cardTextStyle(),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'กรอกรหัสผ่านใหม่',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildInfoCard(
                        label: 'อีเมล :',
                        value:
                            _activeField == 'email' ? null : _maskEmail(_email),
                        fieldKey: 'email',
                        icon: Icons.edit,
                        editor: TextField(
                          controller: _emailController,
                          autofocus: true,
                          keyboardType: TextInputType.emailAddress,
                          style: _cardTextStyle(),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildInfoCard(
                        label: 'เบอร์โทรศัพท์ :',
                        value:
                            _activeField == 'phone' ? null : _maskPhone(_phone),
                        fieldKey: 'phone',
                        icon: Icons.edit,
                        editor: TextField(
                          controller: _phoneController,
                          autofocus: true,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: _cardTextStyle(),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_activeField != null) ...[
                        const SizedBox(height: 30),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveActiveField,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D4983),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
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
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _buildInfoCard({
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
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFBFE8FF),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.mitr(
              textStyle: const TextStyle(
                color: Color(0xFF4B88D8),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: isActive && editor != null
                ? editor
                : Text(
                    value ?? '',
                    style: _cardTextStyle(),
                  ),
          ),
          GestureDetector(
            onTap: onIconTap ?? () => _activateField(fieldKey),
            child: Icon(
              icon,
              color: const Color(0xFF8A8A8A),
              size: 34,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String value, String label) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        constraints: const BoxConstraints(minWidth: 98),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8ED5FF) : Colors.white,
          borderRadius: BorderRadius.circular(22),
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _cardTextStyle() {
    return GoogleFonts.mitr(
      textStyle: const TextStyle(
        color: Color(0xFF4B88D8),
        fontSize: 18,
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

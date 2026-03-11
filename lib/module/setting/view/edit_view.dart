import 'dart:io'; // 💡 1. Import สำหรับ File
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_application_1/module/setting/view/setting_view.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // 💡 2. Import สำหรับเลือกรูปจากเครื่อง

// ==========================================
// 💡 Controller
// ==========================================
class EditProfileController extends GetxController {
  final RxnString activeField = RxnString();

  // --- ข้อมูลรูปโปรไฟล์ ---
  final RxString profileImagePath = ''.obs; // 💡 เก็บ path รูปที่เลือก
  final ImagePicker _picker = ImagePicker(); // 💡 ตัวเรียกเปิดแกลเลอรี่

  // --- ข้อมูลทั่วไป ---
  final RxString username = 'แมวน้ำ'.obs;
  final RxString gender = 'หญิง'.obs;
  final RxString birthday = '17/12/2004'.obs;

  late String originalName;
  late TextEditingController nameController;

  // --- ข้อมูลความเป็นส่วนตัว ---
  final RxString passwordValue = '1234567890'.obs;
  final RxString emailFull = 'kanthaka@gmail.com'.obs;
  final RxString phoneValue = '0987654321'.obs;

  late String originalPassword;
  late String originalEmail;
  late String originalPhone;

  late TextEditingController passwordController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void onInit() {
    super.onInit();
    originalName = username.value;
    originalPassword = passwordValue.value;
    originalEmail = emailFull.value;
    originalPhone = phoneValue.value;

    nameController = TextEditingController(text: username.value);
    passwordController = TextEditingController(text: passwordValue.value);
    emailController = TextEditingController(
      text: emailFull.value.split('@')[0],
    );
    phoneController = TextEditingController(text: phoneValue.value);
  }

  @override
  void onClose() {
    nameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  // 💡 ฟังก์ชันเปิดแกลเลอรี่และเลือกรูป
  Future<void> pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      profileImagePath.value = image.path;
    }
  }

  // --- ฟังก์ชันจัดรูปแบบ ---
  String formatPassword(String psw) {
    if (psw.length <= 5) return psw;
    return '${psw.substring(0, 5)}*****';
  }

  String formatEmail(String email) {
    final parts = email.split('@');
    final prefix = parts[0];
    final domain = parts.length > 1 ? parts[1] : 'gmail.com';
    if (prefix.length <= 3) return email;
    return '${prefix.substring(0, 3)}****@$domain';
  }

  String formatPhone(String phone) {
    if (phone.length <= 4) return phone;
    return phone.replaceRange(phone.length - 4, phone.length, '****');
  }

  // --- ฟังก์ชันการทำงาน ---
  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2004, 12, 17),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      birthday.value = DateFormat('dd/MM/yyyy').format(picked);
      activeField.value = 'birth';
    }
  }

  void activateField(String fieldKey) {
    activeField.value = fieldKey;
    if (fieldKey == 'name') {
      nameController.text = username.value;
    } else if (fieldKey == 'email') {
      emailController.text = emailFull.value.split('@')[0];
    } else if (fieldKey == 'password') {
      passwordController.text = passwordValue.value;
    } else if (fieldKey == 'phone') {
      phoneController.text = phoneValue.value;
    }
  }

  void save() {
    if (activeField.value == 'name') {
      username.value = nameController.text.trim().isEmpty
          ? originalName
          : nameController.text;
      originalName = username.value;
    } else if (activeField.value == 'password') {
      passwordValue.value = passwordController.text.isEmpty
          ? originalPassword
          : passwordController.text;
      originalPassword = passwordValue.value;
    } else if (activeField.value == 'email') {
      final prefix = emailController.text.trim();
      if (prefix.isNotEmpty) {
        emailFull.value = '$prefix@gmail.com';
        originalEmail = emailFull.value;
      }
    } else if (activeField.value == 'phone') {
      phoneValue.value = phoneController.text.isEmpty
          ? originalPhone
          : phoneController.text;
      originalPhone = phoneValue.value;
    }
    activeField.value = null;
  }
}

// ==========================================
// 💡 UI หน้า EditProfile
// ==========================================
class EditProfilePage extends StatelessWidget {
  EditProfilePage({super.key});

  final EditProfileController controller =
      Get.isRegistered<EditProfileController>()
      ? Get.find<EditProfileController>()
      : Get.put(EditProfileController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 45,
          titleSpacing: 2,
          leading: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.back(),
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Image.asset(
                'assets/images/back.png',
                width: 25,
                height: 25,
              ),
            ),
          ),
          title: const Text(
            'แก้ไขข้อมูล',
            style: TextStyle(
              color: Color(0xFF4489D7),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // --- 💡 ส่วนรูปโปรไฟล์และปุ่มอัปโหลด ---
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        // 💡 เปลี่ยนมาใช้ Obx เช็คว่ามีรูปในเครื่องหรือไม่
                        child: CircleAvatar(
                          radius: 75,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              controller.profileImagePath.value.isNotEmpty
                              ? FileImage(
                                      File(controller.profileImagePath.value),
                                    )
                                    as ImageProvider
                              : const NetworkImage(
                                  'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
                                ),
                        ),
                      ),

                      // 💡 ปุ่มเปลี่ยนรูป (ตาม Design ของคุณ)
                      Positioned(
                        bottom: -3,
                        right: 8,
                        child: GestureDetector(
                          onTap: controller
                              .pickProfileImage, // เรียกฟังก์ชันเปิดแกลเลอรี่
                          child: Container(
                            // padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD9D9D9,
                              ), // สีเทาอ่อนแบบในรูป
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ), // ขอบขาวหนา
                            ),
                            child: Image.asset(
                              'assets/images/upload.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // --- แก้ไขชื่อผู้ใช้ ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (controller.activeField.value == 'name')
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: controller.nameController,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF4489D7),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      )
                    else
                      Text(
                        controller.username.value,
                        style: const TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.activateField('name'),
                      child: Image.asset(
                        'assets/images/pen.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.edit,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // --- 1. เพศ ---
                _buildEditItem(
                  label: 'เพศ :',
                  fieldKey: 'gender',
                  iconPath: 'assets/images/pen.png',
                  content: Text(
                    controller.gender.value,
                    style: const TextStyle(
                      color: Color(0xFF4489D7),
                      fontSize: 18,
                    ),
                  ),
                ),
                if (controller.activeField.value == 'gender')
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildGenderChip('ชาย'),
                        _buildGenderChip('หญิง'),
                        _buildGenderChip('LGBTQ+'),
                      ],
                    ),
                  ),
                const SizedBox(height: 15),

                // --- 2. วันเกิด ---
                _buildEditItem(
                  label: 'วันเกิด :',
                  fieldKey: 'birth',
                  iconPath: 'assets/images/calendar.png',
                  onIconTap: () => controller.selectDate(context),
                  content: Text(
                    controller.birthday.value,
                    style: const TextStyle(
                      color: Color(0xFF4489D7),
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // --- 3. รหัสผ่าน ---
                _buildEditItem(
                  label: 'รหัส :',
                  fieldKey: 'password',
                  iconPath: 'assets/images/pen.png',
                  content: controller.activeField.value == 'password'
                      ? TextField(
                          controller: controller.passwordController,
                          autofocus: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]'),
                            ),
                          ],
                          style: const TextStyle(
                            color: Color(0xFF4489D7),
                            fontSize: 18,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : Text(
                          controller.formatPassword(
                            controller.passwordValue.value,
                          ),
                          style: const TextStyle(
                            color: Color(0xFF4489D7),
                            fontSize: 18,
                          ),
                        ),
                ),
                const SizedBox(height: 15),

                // --- 4. อีเมล ---
                _buildEditItem(
                  label: 'อีเมล :',
                  fieldKey: 'email',
                  iconPath: 'assets/images/pen.png',
                  content: controller.activeField.value == 'email'
                      ? TextField(
                          controller: controller.emailController,
                          autofocus: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-z0-9._]'),
                            ),
                          ],
                          style: const TextStyle(
                            color: Color(0xFF4489D7),
                            fontSize: 18,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            suffixText: '@gmail.com',
                            suffixStyle: TextStyle(
                              color: Color(0xFF6A99D3),
                              fontSize: 16,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : Text(
                          controller.formatEmail(controller.emailFull.value),
                          style: const TextStyle(
                            color: Color(0xFF4489D7),
                            fontSize: 18,
                          ),
                        ),
                ),
                const SizedBox(height: 15),

                // --- 5. เบอร์โทรศัพท์ ---
                _buildEditItem(
                  label: 'เบอร์โทรศัพท์ :',
                  fieldKey: 'phone',
                  iconPath: 'assets/images/pen.png',
                  content: controller.activeField.value == 'phone'
                      ? TextField(
                          controller: controller.phoneController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            color: Color(0xFF4489D7),
                            fontSize: 18,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : Text(
                          controller.formatPhone(controller.phoneValue.value),
                          style: const TextStyle(
                            color: Color(0xFF4489D7),
                            fontSize: 18,
                          ),
                        ),
                ),
                const SizedBox(height: 30),

                // --- ปุ่มบันทึก ---
                if (controller.activeField.value != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: controller.save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D4983),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'บันทึก',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget แม่แบบสำหรับกล่องข้อมูลแต่ละอัน ---
  Widget _buildEditItem({
    required String label,
    required String fieldKey,
    required String iconPath,
    required Widget content,
    VoidCallback? onIconTap,
  }) {
    return Container(
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFCEEFFE),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF4489D7),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: content),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onIconTap ?? () => controller.activateField(fieldKey),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Image.asset(
                iconPath,
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.edit, color: Colors.grey, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ปุ่มเลือกเพศ ---
  Widget _buildGenderChip(String label) {
    final isSelected = controller.gender.value == label;
    return GestureDetector(
      onTap: () => controller.gender.value = label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB5EFFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade400, width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6A99D3) : Colors.grey.shade600,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

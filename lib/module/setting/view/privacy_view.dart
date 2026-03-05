import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/module/setting/view/setting_view.dart';
import 'package:get/get.dart';

class PrivacyController extends GetxController {
  final RxnString activeField = RxnString();

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
    originalPassword = passwordValue.value;
    originalEmail = emailFull.value;
    originalPhone = phoneValue.value;

    passwordController = TextEditingController(text: passwordValue.value);
    emailController = TextEditingController(text: emailFull.value.split('@')[0]);
    phoneController = TextEditingController(text: phoneValue.value);
  }

  @override
  void onClose() {
    passwordController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }

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

  void activateField(String fieldKey) {
    activeField.value = fieldKey;
    if (fieldKey == 'email') {
      emailController.text = emailFull.value.split('@')[0];
    } else if (fieldKey == 'password') {
      passwordController.text = passwordValue.value;
    } else if (fieldKey == 'phone') {
      phoneController.text = phoneValue.value;
    }
  }

  void save() {
    if (activeField.value == 'password') {
      passwordValue.value =
          passwordController.text.isEmpty ? originalPassword : passwordController.text;
      originalPassword = passwordValue.value;
    } else if (activeField.value == 'email') {
      final prefix = emailController.text.trim();
      if (prefix.isNotEmpty) {
        emailFull.value = '$prefix@gmail.com';
        originalEmail = emailFull.value;
      }
    } else if (activeField.value == 'phone') {
      phoneValue.value =
          phoneController.text.isEmpty ? originalPhone : phoneController.text;
      originalPhone = phoneValue.value;
    }
    activeField.value = null;
  }
}

class PrivacyPage extends StatelessWidget {
  PrivacyPage({super.key});

  final PrivacyController controller = Get.isRegistered<PrivacyController>()
      ? Get.find<PrivacyController>()
      : Get.put(PrivacyController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: -8,
          leading: IconButton(
            icon: Image.asset(
              'assets/images/back.png',
              width: 25,
              height: 25,
              fit: BoxFit.contain,
            ),
            onPressed: () => Get.to(() => const SettingPage()),
          ),
          title: const Text(
            'ความเป็นส่วนตัว',
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
                const SizedBox(height: 40),
                _buildPrivacyItem(
                  label: 'รหัส :',
                  fieldKey: 'password',
                  content: controller.activeField.value == 'password'
                      ? TextField(
                          controller: controller.passwordController,
                          autofocus: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                          ],
                          style: const TextStyle(color: Color(0xFF4489D7), fontSize: 18),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        )
                      : Text(
                          controller.formatPassword(controller.passwordValue.value),
                          style: const TextStyle(color: Color(0xFF4489D7), fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),
                _buildPrivacyItem(
                  label: 'อีเมล :',
                  fieldKey: 'email',
                  content: controller.activeField.value == 'email'
                      ? TextField(
                          controller: controller.emailController,
                          autofocus: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._]')),
                          ],
                          style: const TextStyle(color: Color(0xFF4489D7), fontSize: 18),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            suffixText: '@gmail.com',
                            suffixStyle: TextStyle(color: Color(0xFF6A99D3), fontSize: 16),
                          ),
                        )
                      : Text(
                          controller.formatEmail(controller.emailFull.value),
                          style: const TextStyle(color: Color(0xFF4489D7), fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),
                _buildPrivacyItem(
                  label: 'เบอร์โทรศัพท์ :',
                  fieldKey: 'phone',
                  content: controller.activeField.value == 'phone'
                      ? TextField(
                          controller: controller.phoneController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(color: Color(0xFF4489D7), fontSize: 18),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        )
                      : Text(
                          controller.formatPhone(controller.phoneValue.value),
                          style: const TextStyle(color: Color(0xFF4489D7), fontSize: 18),
                        ),
                ),
                const SizedBox(height: 30),
                if (controller.activeField.value != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: controller.save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D4983),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text(
                        'บันทึก',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyItem({
    required String label,
    required String fieldKey,
    required Widget content,
  }) {
    return Container(
      height: 70,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFD9EFFA),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6A99D3),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(child: content),
          GestureDetector(
            onTap: () => controller.activateField(fieldKey),
            child: Image.asset(
              'assets/images/pen.png',
              width: 25,
              height: 25,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.edit, color: Color(0xFF9E9E9E), size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

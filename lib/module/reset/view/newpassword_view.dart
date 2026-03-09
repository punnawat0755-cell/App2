import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/login/view/login2_view.dart';
import 'package:get/get.dart';

class NewPasswordController extends GetxController {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final RxBool obscureNew = true.obs;
  final RxBool obscureConfirm = true.obs;

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleNewPasswordVisibility() {
    obscureNew.value = !obscureNew.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirm.value = !obscureConfirm.value;
  }

  void savePassword() {
    if (newPasswordController.text == confirmPasswordController.text &&
        newPasswordController.text.isNotEmpty) {
      Get.snackbar(
        'สำเร็จ',
        'เปลี่ยนรหัสผ่านเรียบร้อยแล้ว',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAll(() => LoginPagetwo());
      return;
    }

    Get.snackbar(
      'แจ้งเตือน',
      'รหัสผ่านไม่ตรงกัน',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
}

class NewPasswordPage extends StatelessWidget {
  NewPasswordPage({super.key});

  final NewPasswordController controller = Get.isRegistered<NewPasswordController>()
      ? Get.find<NewPasswordController>()
      : Get.put(NewPasswordController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 40,
          titleSpacing: 2,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/images/back.png',
                  width: 25,
                  height: 25,
                  color: const Color(0xFF757575),
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 290,
                    height: 290,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFB3E5FC).withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFB5EFFF).withValues(alpha: 0.4),
                        ),
                        child: Center(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF8BE2FB),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/lockkey.png',
                                width: 100,
                                height: 110,
                                color: const Color(0xFF4C91E2),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    'สร้างรหัสผ่านใหม่',
                    style: TextStyle(
                      color: Color(0xFF4489D7),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'กรุณากำหนดรหัสผ่านใหม่ของคุณเพื่อเข้าใช้งานอีกครั้ง',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6A99D3),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'รหัสผ่านใหม่',
                  style: TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: controller.newPasswordController,
                  hint: 'กรอกรหัสผ่านใหม่',
                  isObscure: controller.obscureNew.value,
                  onToggle: controller.toggleNewPasswordVisibility,
                ),
                const SizedBox(height: 20),
                const Text(
                  'ยืนยันรหัสผ่านใหม่',
                  style: TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: controller.confirmPasswordController,
                  hint: 'กรอกรหัสผ่านใหม่อีกครั้ง',
                  isObscure: controller.obscureConfirm.value,
                  onToggle: controller.toggleConfirmPasswordVisibility,
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: controller.savePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF20C2FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'บันทึก',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFAEAEAE), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFFAEAEAE),
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}

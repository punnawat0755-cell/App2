import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/module/reset/view/resetsent_view.dart';
import 'package:get/get.dart';

class ResetPasswordController extends GetxController {
  final TextEditingController emailController = TextEditingController();

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  void sendEmail() {
    final emailPrefix = emailController.text.trim();
    final finalEmail = '$emailPrefix@gmail.com';

    if (emailPrefix.isNotEmpty) {
      print('Sending to: $finalEmail');
      Get.to(() => ResetSentPage());
      return;
    }

    Get.snackbar(
      'แจ้งเตือน',
      'กรุณากรอกชื่ออีเมลของคุณก่อนกดส่ง',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orangeAccent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(15),
      duration: const Duration(seconds: 2),
    );
  }
}

class ResetPasswordPage extends StatelessWidget {
  ResetPasswordPage({super.key});

  final ResetPasswordController controller =
      Get.isRegistered<ResetPasswordController>()
          ? Get.find<ResetPasswordController>()
          : Get.put(ResetPasswordController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Image.asset('assets/images/back.png', width: 32, height: 32),
          ),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: const Text(
          'ลืมรหัสผ่าน',
          style: TextStyle(
            color: Color(0xFF4489D7),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 40),
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
                              'assets/images/lockk.png',
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
              const Text(
                'กรุณากรอกอีเมลของคุณเพื่อตั้งรหัสผ่านใหม่',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6A99D3),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller.emailController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    hintText: 'กรุณากรอกอีเมลของคุณ',
                    suffixText: '@gmail.com',
                    suffixStyle: const TextStyle(
                      color: Color(0xFF4489D7),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    hintStyle: const TextStyle(
                      color: Color(0xFFAEAEAE),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 15, right: 8),
                      child: Image.asset('assets/images/email.png', width: 35, height: 40),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  ),
                ),
              ),
              const SizedBox(height: 150),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.sendEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20C2FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ส่งอีเมล',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

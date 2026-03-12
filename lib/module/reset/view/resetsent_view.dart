import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/module/reset/view/newpassword_view.dart';
import 'package:get/get.dart';

class ResetSentController extends GetxController {
  final List<TextEditingController> controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void onClose() {
    for (final item in controllers) {
      item.dispose();
    }
    for (final item in focusNodes) {
      item.dispose();
    }
    super.onClose();
  }

  void onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
      return;
    }
    if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  void confirmOtp() {
    final otp = controllers.map((e) => e.text).join();
    print('OTP Entered: $otp');

    if (otp.length == 6) {
      Get.to(() => NewPasswordPage());
      Get.snackbar(
        'สำเร็จ',
        'รหัสถูกต้อง',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    Get.snackbar(
      'ข้อผิดพลาด',
      'กรุณากรอกรหัสให้ครบ 6 หลัก',
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }
}

class ResetSentPage extends StatelessWidget {
  ResetSentPage({super.key});

  final ResetSentController controller = Get.isRegistered<ResetSentController>()
      ? Get.find<ResetSentController>()
      : Get.put(ResetSentController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 290,
                  height: 290,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFEBEE).withValues(alpha: 0.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFCDD2).withValues(alpha: 0.6),
                      ),
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEF9A9A),
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
                              'assets/images/mailbox.png',
                              width: 100,
                              height: 110,
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
                'ยืนยันรหัสความปลอดภัย',
                style: TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'กรุณากรอกรหัส 6 หลัก ที่เราส่งไปยังอีเมลของคุณ\nรหัสจะหมดอายุภายในไม่กี่นาที',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6A99D3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _buildOTPField(index)),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'ส่งรหัสอีกครั้ง',
                  style: TextStyle(
                    color: Color(0xFF757575),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 80),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.confirmOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20C2FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ยืนยัน',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPField(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: controller.controllers[index],
        focusNode: controller.focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4489D7),
        ),
        decoration: const InputDecoration(
          counterText: '',
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4489D7), width: 2),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF20C2FF), width: 3),
          ),
        ),
        onChanged: (value) => controller.onOtpChanged(index, value),
      ),
    );
  }
}

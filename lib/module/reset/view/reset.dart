import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // เพิ่มตัวนี้เพื่อใช้งาน FilteringTextInputFormatter
import 'package:flutter_application_1/module/reset/view/resetsent.dart';
import 'package:get/get.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController emailController = TextEditingController();

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
            child: Image.asset("assets/images/back.png", width: 32, height: 32),
          ),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: const Text(
          "ลืมรหัสผ่าน",
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

              // --- 1. รูปกุญแจพร้อมวงกลมซ้อน ---
              Center(
                child: Container(
                  width: 290,
                  height: 290,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFB3E5FC).withOpacity(0.2),
                  ),
                  child: Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFB5EFFF).withOpacity(0.4),
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
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              "assets/images/lockk.png",
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

              // --- 2. ข้อความแนะนำ ---
              const Text(
                "กรุณากรอกอีเมลของคุณเพื่อตั้งรหัสผ่านใหม่",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6A99D3),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // --- 3. ช่องกรอกอีเมล (TextField) ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: emailController,
                  // จำกัดตัวอักษรที่พิมพ์ได้
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9@._-]'),
                    ),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    hintText: "กรุณากรอกอีเมลของคุณ",
                    // แสดง @gmail.com ต่อท้าย
                    suffixText: "@gmail.com",
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
                      child: Image.asset(
                        "assets/images/email.png",
                        width: 35,
                        height: 40,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 150),

              // --- 4. ปุ่มส่งอีเมล ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // 1. ดึงค่าจาก TextField
                    String emailPrefix = emailController.text.trim();
                    String finalEmail = "$emailPrefix@gmail.com";

                    // 2. ตรวจสอบว่าได้กรอกชื่ออีเมลหรือยัง
                    if (emailPrefix.isNotEmpty) {
                      print("Sending to: $finalEmail");

                      // 3. ใช้ GetX เพื่อเปลี่ยนหน้าไปที่ ResetSentPage
                      Get.to(() => const ResetSentPage());
                    } else {
                      // แจ้งเตือนจากด้านบน (ตามที่คุณต้องการ) ถ้ายังไม่ได้กรอกอีเมล
                      Get.snackbar(
                        "แจ้งเตือน",
                        "กรุณากรอกชื่ออีเมลของคุณก่อนกดส่ง",
                        snackPosition: SnackPosition.TOP, // เด้งจากข้างบน
                        backgroundColor: Colors.orangeAccent,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(15),
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20C2FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "ส่งอีเมล",
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

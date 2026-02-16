import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/module/setting/view/setting.dart';
import 'package:get/get.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  String? activeField;

  // ข้อมูลเริ่มต้น
  String passwordValue = "1234567890";
  String emailFull = "kanthaka@gmail.com";
  String phoneValue = "0987654321";

  late String originalPassword;
  late String originalEmail;
  late String originalPhone;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    originalPassword = passwordValue;
    originalEmail = emailFull;
    originalPhone = phoneValue;

    passwordController.text = passwordValue;
    emailController.text = emailFull.split('@')[0];
    phoneController.text = phoneValue;
  }

  @override
  void dispose() {
    passwordController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // ฟังก์ชันจัดรูปแบบรหัส (โชว์ 5 ตัวแรก)
  String formatPassword(String psw) {
    if (psw.length <= 5) return psw;
    return "${psw.substring(0, 5)}*****";
  }

  // ฟังก์ชันจัดรูปแบบอีเมล (โชว์ 3 ตัวแรก)
  String formatEmail(String email) {
    var parts = email.split('@');
    String prefix = parts[0];
    String domain = parts.length > 1 ? parts[1] : "gmail.com";
    if (prefix.length <= 3) return email;
    return "${prefix.substring(0, 3)}****@$domain";
  }

  // ฟังก์ชันจัดรูปแบบเบอร์โทร (ดอกจัน 4 ตัวท้าย)
  String formatPhone(String phone) {
    if (phone.length <= 4) return phone;
    return phone.replaceRange(phone.length - 4, phone.length, "****");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          "ความเป็นส่วนตัว",
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

              // --- 1. รหัสผ่าน ---
              _buildPrivacyItem(
                label: "รหัส :",
                fieldKey: "password",
                content: activeField == "password"
                    ? TextField(
                        controller: passwordController,
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
                        ),
                      )
                    : Text(
                        formatPassword(passwordValue),
                        style: const TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: 18,
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // --- 2. อีเมล ---
              _buildPrivacyItem(
                label: "อีเมล :",
                fieldKey: "email",
                content: activeField == "email"
                    ? TextField(
                        controller: emailController,
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
                          suffixText: "@gmail.com",
                          suffixStyle: TextStyle(
                            color: Color(0xFF6A99D3),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : Text(
                        formatEmail(emailFull),
                        style: const TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: 18,
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // --- 3. เบอร์โทรศัพท์ ---
              _buildPrivacyItem(
                label: "เบอร์โทรศัพท์ :",
                fieldKey: "phone",
                content: activeField == "phone"
                    ? TextField(
                        controller: phoneController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ], // ใส่ได้เฉพาะตัวเลข
                        style: const TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: 18,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      )
                    : Text(
                        formatPhone(phoneValue),
                        style: const TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: 18,
                        ),
                      ),
              ),

              const SizedBox(height: 30),

              // --- ปุ่มบันทึก ---
              if (activeField != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (activeField == "password") {
                          passwordValue = passwordController.text.isEmpty
                              ? originalPassword
                              : passwordController.text;
                          originalPassword = passwordValue;
                        } else if (activeField == "email") {
                          String prefix = emailController.text.trim();
                          if (prefix.isNotEmpty) {
                            emailFull = "$prefix@gmail.com";
                            originalEmail = emailFull;
                          }
                        } else if (activeField == "phone") {
                          phoneValue = phoneController.text.isEmpty
                              ? originalPhone
                              : phoneController.text;
                          originalPhone = phoneValue;
                        }
                        activeField = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D4983),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "บันทึก",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
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
            color: Colors.black.withOpacity(0.1),
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
            onTap: () {
              setState(() {
                activeField = fieldKey;
                if (fieldKey == "email") {
                  emailController.text = emailFull.split('@')[0];
                } else if (fieldKey == "password") {
                  passwordController.text = passwordValue;
                } else if (fieldKey == "phone") {
                  phoneController.text = phoneValue;
                }
              });
            },
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

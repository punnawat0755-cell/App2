import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/home/view/home_view.dart';
import 'package:flutter_application_1/module/login/view/singup_view.dart';
import 'package:get/get.dart';

class LoginPagetwo extends StatelessWidget {
  const LoginPagetwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Text(
                "เข้าสู่ระบบ",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A89D8),
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField(hintText: "ชื่อผู้ใช้", icon: Icons.person),
              const SizedBox(height: 20),
              _buildTextField(
                hintText: "รหัสผ่าน",
                icon: Icons.lock,
                isPassword: true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "ลืมรหัสผ่าน?",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Get.offAll(() => HomePage()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64BFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "เข้าสู่ระบบ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 150),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "ยังไม่มีบัญชีใช่ไหม? ",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () => Get.to(() => Signup()),
                    child: const Text(
                      "ลงทะเบียน",
                      style: TextStyle(
                        color: Color(0xFF64BFFF),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
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
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

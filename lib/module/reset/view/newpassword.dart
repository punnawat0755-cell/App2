import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool _obscureNew = true; // สำหรับช่องรหัสผ่านใหม่
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF757575)),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // ให้ Label ชิดซ้าย
            children: [
              // --- 1. รูปกุญแจพร้อมวงกลมซ้อน (ขนาดเท่าหน้าแรก) ---
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
                              "assets/images/lockkey.png", // เปลี่ยนเป็นรูปกุญแจที่มีลูกกุญแจด้านข้าง
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

              // --- 2. หัวข้อ ---
              const Center(
                child: Text(
                  "สร้างรหัสผ่านใหม่",
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
                  "กรุณากำหนดรหัสผ่านใหม่ของคุณเพื่อเข้าใช้งานอีกครั้ง",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6A99D3),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- 3. ช่องกรอกรหัสผ่านใหม่ ---
              const Text(
                "รหัสผ่านใหม่",
                style: TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: newPasswordController,
                hint: "กรอกรหัสผ่านใหม่",
                isObscure: _obscureNew, // ใช้ตัวแปรแยก
                onToggle: () => setState(
                  () => _obscureNew = !_obscureNew,
                ), // สลับเฉพาะค่านี้
              ),

              const SizedBox(height: 20),

              // --- 4. ช่องยืนยันรหัสผ่านใหม่ ---
              const Text(
                "ยืนยันรหัสผ่านใหม่",
                style: TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: confirmPasswordController,
                hint: "กรอกรหัสผ่านใหม่อีกครั้ง",
                isObscure: _obscureConfirm, // ใช้ตัวแปรแยก
                onToggle: () => setState(
                  () => _obscureConfirm = !_obscureConfirm,
                ), // สลับเฉพาะค่านี้
              ),

              const SizedBox(height: 50),

              // --- 5. ปุ่มบันทึก ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (newPasswordController.text ==
                            confirmPasswordController.text &&
                        newPasswordController.text.isNotEmpty) {
                      Get.snackbar(
                        "สำเร็จ",
                        "เปลี่ยนรหัสผ่านเรียบร้อยแล้ว",
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                      // กลับไปหน้า Login หรือหน้าเริ่มต้น
                      // Get.offAllNamed('/login');
                    } else {
                      Get.snackbar(
                        "แจ้งเตือน",
                        "รหัสผ่านไม่ตรงกัน",
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
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
                    "บันทึก",
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

  // Widget ช่วยสร้างช่องกรอกรหัสผ่าน
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isObscure, // รับค่าสถานะของช่องนั้นๆ
    required VoidCallback onToggle, // รับฟังก์ชันเมื่อกดปุ่มลูกตา
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure, // ใช้ค่าที่ส่งมาแยกกัน
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFAEAEAE), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFFAEAEAE),
            ),
            onPressed:
                onToggle, // เรียกฟังก์ชันที่ส่งมาเพื่อเปลี่ยนสถานะเฉพาะช่อง
          ),
        ),
      ),
    );
  }
}

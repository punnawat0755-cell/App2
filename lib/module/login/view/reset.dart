import 'package:flutter/material.dart';
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
      // พื้นหลังสีฟ้าอ่อนตามรูป
      backgroundColor: const Color(0xFFE3F4FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Image.asset(
              "assets/images/back.png", // ใช้รูป back ที่คุณมี
              width: 32,
              height: 32,
            ),
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

              // --- 1. รูปกุญแจพร้อมวงกลมซ้อน (Icon Section) ---
              Center(
                child: Container(
                  // 1. วงนอกสุด (ใหญ่สุด)
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFFB3E5FC,
                    ).withOpacity(0.2), // ปรับให้จางลงอีกนิดเพื่อให้ดูฟุ้ง
                  ),
                  child: Center(
                    child: Container(
                      // 2. วงกลาง
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFB3E5FC).withOpacity(0.4),
                      ),
                      child: Center(
                        child: Container(
                          // 3. วงในสุด (ที่ใส่ไอคอน)
                          width: 180,
                          height: 180,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFA1DFFB), // สีฟ้าทึบตามรูป
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 100, // ขยายขนาดไอคอนให้รับกับวงกลมที่ใหญ่ขึ้น
                            color: Color(0xFF4C91E2),
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
                  decoration: const InputDecoration(
                    hintText: "กรุณากรอกอีเมลของคุณ",
                    hintStyle: TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(
                        left: 15,
                        right: 8,
                      ), // ปรับ right ให้ลดลง ข้อความจะยิ่งชิดไอคอน
                      child: Icon(
                        Icons.email_outlined,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),

              const SizedBox(height: 150), // เว้นระยะให้ปุ่มอยู่ด้านล่าง
              // --- 4. ปุ่มส่งอีเมล ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: ฟังก์ชันส่งเมล
                    print("Email: ${emailController.text}");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B5F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "ส่งอีเมล",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/setting/view/edit.dart';
import 'package:get/get.dart';
// ลบ GoogleFonts ออกตามที่คุณต้องการใช้ font จาก main

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
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
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "การตั้งค่า",
          style: TextStyle(
            color: Color(0xFF4489D7),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "แมวน้ำ",
                style: TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // --- แยกการกดแต่ละปุ่มตรงนี้ ---
              _buildSettingItem(
                Image.asset("assets/images/person.png"),
                "แก้ไขข้อมูล",
                () => Get.to(
                  () => const EditProfilePage(),
                ), // เปลี่ยนจาก GetPage เป็น Get.to
              ),
              const SizedBox(height: 20),
              _buildSettingItem(
                Image.asset("assets/images/lock.png"),
                "ความเป็นส่วนตัว",
                () => Get.toNamed('/privacy'), // เปลี่ยนเป็นหน้าความเป็นส่วนตัว
              ),
              const SizedBox(height: 20),
              _buildSettingItem(
                Image.asset("assets/images/heart.png"),
                "รายการโปรด",
                () => Get.toNamed('/favorites'), // เปลี่ยนเป็นหน้ารายการโปรด
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ปรับฟังก์ชันให้รับ onTap เข้ามา เพื่อให้กดได้ทั้งปุ่ม ---
  Widget _buildSettingItem(Widget leading, String title, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCEEFFE).withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        onTap:
            onTap, // นำฟังก์ชันที่ส่งมามาใส่ตรงนี้ ทำให้กดได้ครอบคลุมทั้ง Container
        leading: SizedBox(width: 50, height: 50, child: leading),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4489D7),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Transform.flip(
          flipX: true,
          child: Image.asset(
            'assets/images/back.png',
            width: 20,
            height: 20,
            color: const Color(0xFF757575),
            fit: BoxFit.contain,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
}

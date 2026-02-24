import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // พื้นหลังสีฟ้าอ่อน
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: -8,
        leading: IconButton(
          icon: Image.asset(
            'assets/images/back.png', // ใส่ path รูปภาพของคุณตรงนี้
            width: 25, // กำหนดความกว้างตามความเหมาะสม
            height: 25, // กำหนดความสูงตามความเหมาะสม
            fit: BoxFit.contain,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "การตั้งค่า",
          style: GoogleFonts.mitr(
            textStyle: const TextStyle(
              color: Color(0xFF4489D7),
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // --- โปรไฟล์แมวน้ำ ---
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // border: Border.all(color: Colors.white, width: 4),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Seal",
                style: GoogleFonts.mitr(
                  textStyle: const TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // --- รายการเมนูพร้อมกรอบชัด ---
              _buildSettingItem(
                Image.asset("assets/images/person.png"), // ใส่รูปแทน Icon
                "แก้ไขข้อมูล",
              ),
              const SizedBox(height: 20),
              _buildSettingItem(
                Image.asset("assets/images/lock.png"), // ใส่รูปแทน Icon
                "ความเป็นส่วนตัว",
              ),
              const SizedBox(height: 20),
              _buildSettingItem(
                Image.asset("assets/images/heart.png"), // ใส่รูปแทน Icon
                "รายการโปรด",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget สำหรับสร้างปุ่มรายการเมนู (ปิดปีกกาครบถ้วน) ---// แก้บรรทัดนี้
  Widget _buildSettingItem(Widget leading, String title) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCEEFFE).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(25),
        // เพิ่มเส้นขอบสีเทาเข้มเพื่อให้กรอบชัดตามรูป
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: leading, // วาง Widget ที่ส่งมาจากด้านบนลงตรงนี้
        ),
        title: Text(
          title,
          style: GoogleFonts.mitr(
            textStyle: const TextStyle(
              color: Color(0xFF4489D7),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color(0xFF757575),
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () {
          // ใส่ Logic หน้าถัดไป
        },
      ),
    );
  } // ปิดฟังก์ชัน _buildSettingItem
} // ปิดคลาส SettingPage อย่างสมบูรณ์

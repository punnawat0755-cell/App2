import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/home/view/noti.dart';
import 'package:flutter_application_1/module/setting/view/edit_view.dart';
import 'package:flutter_application_1/module/setting/view/favorites_view.dart';
// import 'package:flutter_application_1/module/setting/view/privacy_view.dart';
import 'package:get/get.dart';

// 💡 Import HomeController เพื่อใช้เคลียร์จุดแดงที่หน้า Home ตอนกดเมนู
import 'package:flutter_application_1/module/home/view/home_view.dart';
// import 'package:flutter_application_1/module/setting/view/notification_view.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

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
                fit: BoxFit.contain,
              ),
            ),
          ),
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
      // 💡 เปลี่ยนจาก Center เป็น Column เพื่อแยกส่วนเลื่อนได้ กับส่วนปุ่มด้านล่าง
      body: Column(
        children: [
          // --- 💡 ส่วนที่ 1: เมนูทั้งหมด (เลื่อนได้) ---
          Expanded(
            child: SingleChildScrollView(
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

                    // --- ปุ่มเมนู ---
                    _buildSettingItem(
                      Image.asset("assets/images/bell.png"),
                      "แจ้งเตือน",
                      () {
                        if (Get.isRegistered<HomeController>()) {
                          Get.find<HomeController>().hasNewNotification.value =
                              false;
                        }
                        Get.to(() => NotiPage());
                      },
                    ),

                    const SizedBox(height: 20),

                    _buildSettingItem(
                      Image.asset("assets/images/person.png"),
                      "แก้ไขข้อมูล",
                      () => Get.to(() => EditProfilePage()),
                    ),

                    const SizedBox(height: 20),
                    _buildSettingItem(
                      Image.asset("assets/images/heart.png"),
                      "รายการโปรด",
                      () => Get.to(() => FavoritesPage()),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // --- 💡 ส่วนที่ 2: ปุ่มออกจากระบบ (อยู่ติดขอบล่างเสมอ) ---
          Padding(
            padding: const EdgeInsets.only(bottom: 200),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // ใส่ฟังก์ชันออกจากระบบตรงนี้ เช่น ล้างค่า Token แล้วเด้งไปหน้า Login
                // Get.offAll(() => LoginPage());
                print("ออกจากระบบ");
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "ออกจากระบบ",
                    style: TextStyle(
                      color: Color(0xFF8A8A8A), // สีเทาตามแบบ
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset("assets/images/exit.png", width: 24, height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ปรับฟังก์ชันให้กลับมาเป็นแบบปกติ ไม่มีจุดแดง ---
  Widget _buildSettingItem(Widget leading, String title, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCEEFFE),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
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

import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/coin/controller/coin_controller.dart';
import 'package:flutter_application_1/module/home/view/home_view.dart';
import 'package:get/get.dart';

class CoinRewardScreen extends StatelessWidget {
  const CoinRewardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CoinController coinController = Get.isRegistered<CoinController>()
        ? Get.find<CoinController>()
        : Get.put(CoinController(), permanent: true);

    return Scaffold(
      // สีพื้นหลังสีครีมเหลืองอ่อนตามแบบ
      backgroundColor: const Color(0xFFFDF0CD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // 1. ป้ายแสดงจำนวน Coin ที่ได้รับ
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD348), // สีเหลืองทอง
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "คุณได้รับ Coin จำนวน 30 Coin",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF634917), // สีตัวอักษรน้ำตาลเข้ม
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // 2. รูปภาพหีบสมบัติที่มีเหรียญ
              // 💡 (อย่าลืมแก้ Path รูปให้ตรงกับในโปรเจกต์ของคุณ)
              Image.asset(
                'assets/images/coinbox.png',
                height: 200,
                fit: BoxFit.contain,
              ),
              const Spacer(flex: 2),
              // 3. ปุ่ม "เก็บ Coin"
              GestureDetector(
                onTap: () {
                  coinController.addCoins(30);
                  print("เก็บเหรียญเรียบร้อย! ตอนนี้มี ${coinController.coins.value} coin");
                  Get.snackbar(
                    "รับ Coin สำเร็จ",
                    "ได้รับเพิ่ม 30 Coin",
                    backgroundColor: const Color(0xFFFFD348),
                    colorText: const Color(0xFF634917),
                  );
                  Get.offAll(() => HomePage());
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFAE00), // สีส้มทองของปุ่ม
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ไอคอนเหรียญ C ในปุ่ม
                      Image.asset(
                        'assets/images/coin.png',
                        height: 30,
                        // ถ้ายังไม่มีรูป จะสร้างวงกลมตัว C จำลองขึ้นมาให้ก่อน
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "เก็บ Coin",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF634917), // สีตัวอักษรน้ำตาลเข้ม
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

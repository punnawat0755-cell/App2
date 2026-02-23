import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ResetSentPage extends StatefulWidget {
  const ResetSentPage({super.key});

  @override
  State<ResetSentPage> createState() => _ResetSentPageState();
}

class _ResetSentPageState extends State<ResetSentPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

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
            children: [
              const SizedBox(height: 20),

              // --- 1. รูปกล่องจดหมายพร้อมวงกลมซ้อนสีชมพู ---
              Center(
                child: Container(
                  width: 290,
                  height: 290,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFEBEE).withOpacity(0.5),
                  ),
                  child: Center(
                    child: Container(
                      // วงกลางเท่ากับหน้าแรก (250)
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFCDD2).withOpacity(0.6),
                      ),
                      child: Center(
                        child: Container(
                          // วงในสุดเท่ากับหน้าแรก (180)
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFFEF9A9A,
                            ), // สีชมพูหลักสำหรับหน้านี้
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
                              "assets/images/mailbox.png",
                              width: 100, // ขนาดไอคอนสมดุลกับวง 180
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

              // --- 2. หัวข้อและคำอธิบาย ---
              const Text(
                "ยืนยันรหัสความปลอดภัย",
                style: TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "กรุณากรอกรหัส 6 หลัก ที่เราส่งไปยังอีเมลของคุณ\nรหัสจะหมดอายุภายในไม่กี่นาที",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6A99D3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 40),

              // --- 3. ช่องกรอกรหัส 6 หลัก (OTP Input) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _buildOTPField(index)),
              ),

              const SizedBox(height: 30),

              // --- 4. ปุ่มส่งรหัสอีกครั้ง ---
              GestureDetector(
                onTap: () {
                  // TODO: ฟังก์ชันส่งรหัสใหม่
                },
                child: const Text(
                  "ส่งรหัสอีกครั้ง",
                  style: TextStyle(
                    color: Color(0xFF757575),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 80),

              // --- 5. ปุ่มยืนยัน ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    String otp = _controllers.map((e) => e.text).join();
                    print("OTP Entered: $otp");
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
                    "ยืนยัน",
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

  // ฟังก์ชันสร้างช่องกรอก OTP ทีละช่อง
  Widget _buildOTPField(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4489D7),
        ),
        decoration: const InputDecoration(
          counterText: "", // ซ่อนตัวเลขบอกจำนวนด้านล่าง
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4489D7), width: 2),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF20C2FF), width: 3),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus(); // พิมพ์แล้วเลื่อนไปช่องถัดไป
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1]
                .requestFocus(); // ลบแล้วย้อนกลับไปช่องก่อนหน้า
          }
        },
      ),
    );
  }
}

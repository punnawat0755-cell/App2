import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  String selectedGender = "หญิง";

  @override
  Widget build(BuildContext context) {
    const Color mainBlue = Color(0xFF4A89D8);
    const Color lightBlue = Color(0xFF64BFFF);
    const Color fieldGrey = Color(0xFFF3F3F3);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                "สร้างบัญชีใหม่",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: mainBlue,
                  // ไม่ต้องระบุ fontFamily ตรงนี้แล้ว เพราะ Text จะดึงจาก main.dart มาเอง
                ),
              ),
              const SizedBox(height: 30),

              _buildInputLabel("ชื่อผู้ใช้งาน", isRequired: true),
              _buildTextField(hintText: "แมวน้ำ", fillColor: fieldGrey),

              _buildInputLabel("วันเกิด", isRequired: true),
              _buildTextField(
                hintText: "17/12/2004",
                fillColor: fieldGrey,
                suffixIcon: Icons.calendar_today_outlined,
              ),

              _buildInputLabel("เพศ", isRequired: true),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGenderButton("ชาย"),
                  _buildGenderButton("หญิง"),
                  _buildGenderButton("LGBTQ+"),
                ],
              ),
              const SizedBox(height: 15),

              _buildInputLabel("อีเมล"),
              _buildTextField(hintText: "", fillColor: fieldGrey),

              _buildInputLabel("เบอร์โทรศัพท์"),
              _buildTextField(hintText: "", fillColor: fieldGrey),

              _buildInputLabel("รหัสผ่าน", isRequired: true),
              _buildTextField(
                hintText: "",
                fillColor: fieldGrey,
                isPassword: true,
              ),

              _buildInputLabel("ประจำเดือนครั้งล่าสุด"),
              _buildTextField(
                hintText: "17/12/2026-23/12/2026",
                fillColor: fieldGrey,
                suffixIcon: Icons.calendar_today_outlined,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    print("ทำการลงทะเบียนเรียบร้อย");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "ลงทะเบียน",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "มีบัญชีอยู่แล้ว? ",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Text(
                      "เข้าสู่ระบบ",
                      style: TextStyle(
                        color: lightBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: lightBlue,
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

  // --- จุดที่แก้ไขหลัก ---

  Widget _buildInputLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text.rich(
          // แก้จาก RichText เป็น Text.rich เพื่อให้ยอมดึงฟอนต์จาก Theme
          TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required Color fillColor,
    IconData? suffixIcon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        obscureText: isPassword,
        keyboardType: TextInputType.text,
        inputFormatters: null,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black54),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: Colors.grey)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderButton(String gender) {
    bool isSelected = selectedGender == gender;
    return GestureDetector(
      onTap: () => setState(() => selectedGender = gender),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.25,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC7E9FF) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF64BFFF) : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            gender,
            style: TextStyle(
              color: isSelected ? const Color(0xFF4A89D8) : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

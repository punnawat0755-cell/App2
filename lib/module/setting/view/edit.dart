import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/setting/view/setting.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String? activeField;

  String username = "แมวน้ำ";
  String gender = "หญิง";
  String birthday = "17/12/2004";

  late String originalName;
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    originalName = username;
    nameController = TextEditingController(text: username);
  }

  Future<void> _selectDate(BuildContext context) async {
    print(
      "ฟังก์ชัน _selectDate ถูกเรียกแล้ว!",
    ); // ใส่เพื่อเช็คใน Debug Console ว่ากดติดไหม
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2004, 12, 17),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      // ลองคอมเมนต์บรรทัด locale ออกก่อนถ้ายังกดไม่ขึ้น
      // locale: const Locale('th', 'TH'),
    );

    if (picked != null) {
      setState(() {
        birthday = DateFormat('dd/MM/yyyy').format(picked);
        activeField = "birth";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: -8, // ปรับให้ข้อความชิดปุ่ม Back มากขึ้น
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
          "แก้ไขข้อมูล",
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
              // --- รูปโปรไฟล์พร้อมปุ่ม Refresh ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 75,
                        backgroundImage: NetworkImage(
                          'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 1,
                      right: 3,
                      child: GestureDetector(
                        onTap: () {
                          // ใส่ฟังก์ชันสำหรับเปลี่ยนรูปโปรไฟล์ที่นี่
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          radius: 18,
                          child: Image.asset(
                            'assets/images/refresh.png', // ตรวจสอบว่าชื่อไฟล์ Refresh.png ตรงกับในเครื่อง
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.refresh,
                                  color: Colors.grey,
                                  size: 20,
                                ), // ถ้าหาไฟล์รูปไม่เจอ ให้แสดงไอคอนสำรองแทน
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              // --- แสดงชื่อผู้ใช้ตรงกลางหน้าจอ ---
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Color(0xFF4489D7),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- 1. แถบชื่อผู้ใช้ ---
              _buildEditItem(
                label: "ชื่อผู้ใช้ :",
                fieldKey: "name",
                content: activeField == "name"
                    ? TextField(
                        controller: nameController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: 18,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) => setState(
                          () => username = val.isEmpty ? originalName : val,
                        ),
                      )
                    : Text(
                        username,
                        style: const TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: 18,
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // --- 2. แถบเพศ ---
              _buildEditItem(
                label: "เพศ :",
                fieldKey: "gender",
                content: Text(
                  gender,
                  style: const TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 18,
                  ),
                ),
              ),
              if (activeField == "gender")
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildGenderChip("ชาย"),
                      _buildGenderChip("หญิง"),
                      _buildGenderChip("LGBTQ+"),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // --- 3. แถบวันเกิด (แก้ไขให้กดได้ทั้งช่อง) ---
              _buildEditItem(
                label: "วันเกิด :",
                fieldKey: "birth",
                icon: Icons.calendar_month, // ใช้ไอคอนปฏิทินตามรูป
                onIconTap: () => _selectDate(context),
                content: GestureDetector(
                  onTap: () =>
                      _selectDate(context), // กดที่ตัวเลขวันที่เพื่อเปิดปฏิทิน
                  child: Text(
                    birthday,
                    style: const TextStyle(
                      color: Color(0xFF4489D7),
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- ปุ่มบันทึกข้อมูล ---
              if (activeField != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (nameController.text.trim().isEmpty) {
                            username = originalName;
                            nameController.text = originalName;
                          } else {
                            username = nameController.text;
                            originalName = username;
                          }
                          activeField = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D4983),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        "บันทึก",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildEditItem({
    required String label,
    required String fieldKey,
    required Widget content,
    IconData? icon, // ยังเก็บไว้เผื่อกรณีฉุกเฉิน
    VoidCallback? onIconTap,
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
            color: Colors.black.withOpacity(0.15),
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
              color: Color(0xFF4489D7),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(child: content),
          GestureDetector(
            onTap: onIconTap ?? () => setState(() => activeField = fieldKey),
            child: fieldKey == "birth"
                ? Image.asset(
                    'assets/images/calendar.png', // รูปปฏิทิน
                    width: 30,
                    height: 30,
                  )
                : Image.asset(
                    'assets/images/pen.png', // รูปดินสอ
                    width: 25,
                    height: 25,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String label) {
    bool isSelected = gender == label;
    return GestureDetector(
      onTap: () => setState(() => gender = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB5EFFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade400, width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6A99D3) : Colors.grey.shade600,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

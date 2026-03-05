import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/setting/view/setting.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EditProfileController extends GetxController {
  final RxnString activeField = RxnString();

  final RxString username = 'แมวน้ำ'.obs;
  final RxString gender = 'หญิง'.obs;
  final RxString birthday = '17/12/2004'.obs;

  late String originalName;
  late TextEditingController nameController;

  @override
  void onInit() {
    super.onInit();
    originalName = username.value;
    nameController = TextEditingController(text: username.value);
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2004, 12, 17),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      birthday.value = DateFormat('dd/MM/yyyy').format(picked);
      activeField.value = 'birth';
    }
  }

  void save() {
    if (nameController.text.trim().isEmpty) {
      username.value = originalName;
      nameController.text = originalName;
    } else {
      username.value = nameController.text;
      originalName = username.value;
    }
    activeField.value = null;
  }
}

class EditProfilePage extends StatelessWidget {
  EditProfilePage({super.key});

  final EditProfileController controller = Get.isRegistered<EditProfileController>()
      ? Get.find<EditProfileController>()
      : Get.put(EditProfileController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
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
            onPressed: () => Get.to(() => const SettingPage()),
          ),
          title: const Text(
            'แก้ไขข้อมูล',
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
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
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
                          onTap: () {},
                          child: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 18,
                            child: Image.asset(
                              'assets/images/refresh.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.refresh, color: Colors.grey, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Center(
                  child: Text(
                    controller.username.value,
                    style: const TextStyle(
                      color: Color(0xFF4489D7),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildEditItem(
                  context: context,
                  label: 'ชื่อผู้ใช้ :',
                  fieldKey: 'name',
                  content: controller.activeField.value == 'name'
                      ? TextField(
                          controller: controller.nameController,
                          autofocus: true,
                          style: const TextStyle(color: Color(0xFF4489D7), fontSize: 18),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) =>
                              controller.username.value = val.isEmpty ? controller.originalName : val,
                        )
                      : Text(
                          controller.username.value,
                          style: const TextStyle(color: Color(0xFF4489D7), fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),
                _buildEditItem(
                  context: context,
                  label: 'เพศ :',
                  fieldKey: 'gender',
                  content: Text(
                    controller.gender.value,
                    style: const TextStyle(color: Color(0xFF4489D7), fontSize: 18),
                  ),
                ),
                if (controller.activeField.value == 'gender')
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildGenderChip('ชาย'),
                        _buildGenderChip('หญิง'),
                        _buildGenderChip('LGBTQ+'),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                _buildEditItem(
                  context: context,
                  label: 'วันเกิด :',
                  fieldKey: 'birth',
                  onIconTap: () => controller.selectDate(context),
                  content: GestureDetector(
                    onTap: () => controller.selectDate(context),
                    child: Text(
                      controller.birthday.value,
                      style: const TextStyle(color: Color(0xFF4489D7), fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (controller.activeField.value != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: controller.save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D4983),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                        ),
                        child: const Text(
                          'บันทึก',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditItem({
    required BuildContext context,
    required String label,
    required String fieldKey,
    required Widget content,
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
            color: Colors.black.withValues(alpha: 0.15),
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
            onTap: onIconTap ?? () => controller.activeField.value = fieldKey,
            child: fieldKey == 'birth'
                ? Image.asset('assets/images/calendar.png', width: 30, height: 30)
                : Image.asset('assets/images/pen.png', width: 25, height: 25),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String label) {
    final isSelected = controller.gender.value == label;
    return GestureDetector(
      onTap: () => controller.gender.value = label,
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

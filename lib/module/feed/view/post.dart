import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/feed/view/feed_view.dart';
// 💡 Import HomeController เพื่อส่งข้อมูลคลิปสั้นกลับไป
import 'package:flutter_application_1/module/home/view/home_view.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostPageController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  var charCount = 0.obs;
  var hasImage = false.obs;
  var selectedImagePath = ''.obs;

  // 💡 เพิ่มตัวแปรเช็คว่าเป็นโหมดวิดีโอหรือไม่
  var isVideoMode = false.obs;

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    textController.addListener(() {
      charCount.value = textController.text.length;
    });
  }

  @override
  void onReady() {
    super.onReady();
    focusNode.requestFocus();
  }

  Future<void> pickImage() async {
    // 💡 ให้เลือกได้ทั้งรูปและวิดีโอ
    final XFile? media = await _picker.pickMedia();
    if (media != null) {
      selectedImagePath.value = media.path;
      hasImage.value = true;

      // เช็คว่าไฟล์ที่เลือกมาใหม่เป็นวิดีโอไหม
      final path = media.path.toLowerCase();
      isVideoMode.value =
          path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.avi');
    }
  }

  void removeImage() {
    selectedImagePath.value = '';
    hasImage.value = false;
    isVideoMode.value = false;
  }

  void createPost() {
    if (textController.text.trim().isEmpty && !hasImage.value) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาพิมพ์ข้อความหรือเลือกรูปภาพก่อนโพสต์",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // 💡 เงื่อนไขแยกทาง: ถ่ายวิดีโอไปคลิปสั้น(Home) / รูปภาพไป Feed
    if (isVideoMode.value) {
      // --- 🔴 กรณีโพสต์วิดีโอ (คลิปสั้น) ---
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().addNewClip(
          selectedImagePath.value,
          textController.text,
        );
      }
    } else {
      // --- 🔵 กรณีโพสต์รูปภาพ+ข้อความ (Feed) ---
      if (Get.isRegistered<FeedController>()) {
        Get.find<FeedController>().addNewPost(
          textController.text,
          hasImage.value ? selectedImagePath.value : null,
        );
      }
    }

    textController.clear();
    removeImage();
    Get.back();
  }
}

class PostPage extends StatelessWidget {
  // 💡 1. เพิ่มการรับค่าไฟล์และสถานะวิดีโอจากหน้า Home
  final XFile? mediaFile;
  final bool isVideo;

  PostPage({super.key, this.mediaFile, this.isVideo = false}) {
    // 💡 2. เอาค่าที่ส่งมาจากหน้า Home ไปยัดใส่ Controller ก่อนวาด UI
    final controller = Get.isRegistered<PostPageController>()
        ? Get.find<PostPageController>()
        : Get.put(PostPageController());

    if (mediaFile != null) {
      controller.selectedImagePath.value = mediaFile!.path;
      controller.hasImage.value = true;
      controller.isVideoMode.value = isVideo;
    } else {
      // รีเซ็ตค่าหากเปิดหน้า Post เปล่าๆ
      controller.selectedImagePath.value = '';
      controller.hasImage.value = false;
      controller.isVideoMode.value = false;
      controller.textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PostPageController>();

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 10),
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // --- ส่วนที่ 1: Header ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            controller.removeImage();
                            controller.textController.clear();
                            Get.back();
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Color(0xff8D8D8D),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        "NewPost",
                        style: TextStyle(
                          color: Color(0xff6C6C6C),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, thickness: 1, color: Colors.grey[200]),

                // --- ส่วนที่ 2: โปรไฟล์ User และ ไอคอนแนบรูป ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
                          'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "seal",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff6C6C6C),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: controller.pickImage,
                        child: Image.asset(
                          'assets/images/Picture.png',
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- ส่วนที่ 3: ช่องพิมพ์ข้อความ & รูปภาพ ---
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: TextField(
                            focusNode: controller.focusNode,
                            autofocus: true,
                            controller: controller.textController,
                            maxLines: null,
                            maxLength: 120,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: 'คุณกำลังคิดอะไรอยู่.....',
                              hintStyle: TextStyle(
                                color: Color(0xffCAC9C9),
                                fontWeight: FontWeight.bold,
                              ),
                              border: InputBorder.none,
                              counterText: "",
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        // --- ส่วนรูปภาพแนบ ---
                        Obx(() {
                          if (!controller.hasImage.value ||
                              controller.selectedImagePath.value.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    File(controller.selectedImagePath.value),
                                    width: 250,
                                    height: 300,
                                    fit: BoxFit.cover,
                                    // 💡 3. ถ้าดึงปกวิดีโอไม่ได้ ให้โชว์กล่องสีเทาแทน
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 250,
                                              height: 300,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.video_library,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                  ),
                                ),
                                // 💡 4. ถ้าเป็นวิดีโอ ให้แปะปุ่ม Play ทับไว้ตรงกลาง
                                if (controller.isVideoMode.value)
                                  const CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.black45,
                                    child: Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 35,
                                    ),
                                  ),
                                Positioned(
                                  top: -10,
                                  right: -10,
                                  child: GestureDetector(
                                    onTap: controller.removeImage,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // --- ส่วนที่ 4: Footer (ปุ่ม POST & ตัวนับ) ---
                Padding(
                  padding: const EdgeInsets.only(right: 15, top: 5, bottom: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Obx(
                            () => Text(
                              "${controller.charCount.value}/120", // อัปเดตให้ตรงกับ maxLength
                              style: const TextStyle(
                                color: Color(0xffC3C3C3),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: controller.createPost,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5CD9FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "POST",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostPageController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  var charCount = 0.obs;
  var hasImage = true.obs;

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

  void removeImage() {
    hasImage.value = false;
  }

  void createPost() {
    print("Posting... ${textController.text}");
    Get.back();
  }

  @override
  void onClose() {
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}

class PostPage extends StatelessWidget {
  PostPage({super.key});

  final PostPageController controller = Get.isRegistered<PostPageController>()
      ? Get.find<PostPageController>()
      : Get.put(PostPageController());

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      // heightFactor: 0.88,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Scaffold(
          // 💡 1. เปิดให้ Scaffold จัดการดัน UI หนีคีย์บอร์ดอัตโนมัติ
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ส่วนที่ 1: Header (Cancel & NewPost) ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Get.back(),
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
                      Image.asset(
                        'assets/images/Picture.png',
                        width: 50,
                        height: 50,
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

                            // 💡 2. ปิดแถบเดาคำศัพท์สีขาวของคีย์บอร์ด
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
                          if (!controller.hasImage.value) {
                            return const SizedBox.shrink();
                          }
                          return Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    'https://i.pinimg.com/736x/e5/30/78/e530785d780dd7486ef0593b147a1989.jpg',
                                    width: 250,
                                    height: 300,
                                    fit: BoxFit.cover,
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
                  // ใช้ระยะห่างปกติได้เลย
                  padding: const EdgeInsets.only(right: 15, top: 5, bottom: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // นับตัวอักษร 0/200
                          Obx(
                            () => Text(
                              "${controller.charCount.value}/200",
                              style: const TextStyle(
                                color: Color(0xffC3C3C3),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // ปุ่ม POST
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

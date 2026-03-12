import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/module/feed/view/post.dart';
import 'dart:io';

// ==========================================
// 💡 1. Model เก็บข้อมูลโพสต์ (Perfect แล้ว!)
// ==========================================
class PostModel {
  final String name;
  final String avatarUrl;
  final String content;
  final RxInt likes;
  final RxBool isLiked = false.obs;
  final bool showImage;
  final String? imagePath;
  final bool isLocalImage;

  PostModel({
    required this.name,
    required this.avatarUrl,
    required this.content,
    required int likes,
    this.showImage = false,
    this.imagePath,
    this.isLocalImage = false,
  }) : likes = likes.obs;
}

// ==========================================
// 💡 2. FeedController (จัดการลิสต์โพสต์)
// ==========================================
class FeedController extends GetxController {
  var posts = <PostModel>[
    PostModel(
      name: 'seal',
      avatarUrl: 'https://api.dicebear.com/9.x/adventurer/png?seed=Felix',
      content:
          "อนุญาตให้ตัวเอง 'ไม่โอเค' บ้างก็ได้ ไม่จำเป็นต้องแบกความเข้มแข็งไว้ตลอดเวลา...",
      likes: 15,
    ),
    PostModel(
      name: 'seal2',
      avatarUrl: 'https://api.dicebear.com/9.x/adventurer/png?seed=Felix',
      content:
          'คุณค่าของคุณไม่ได้ลดลงในวันที่คุณทำพลาด หรือในวันที่ใครมองไม่เห็น...',
      likes: 8,
    ),
    PostModel(
      name: 'puffer',
      avatarUrl: 'https://api.dicebear.com/9.x/adventurer/png?seed=Buddy',
      content: 'สุขใจเมื่อได้เจอ',
      likes: 138,
      showImage: true,
      imagePath:
          'https://i.pinimg.com/736x/b7/ac/ba/b7acba5c729ea828c9ed398f21248681.jpg',
      isLocalImage: false,
    ),
  ].obs;

  void addNewPost(String content, String? localImagePath) {
    posts.insert(
      0,
      PostModel(
        name: 'seal',
        avatarUrl:
            'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
        content: content,
        likes: 0,
        showImage: localImagePath != null && localImagePath.isNotEmpty,
        imagePath: localImagePath,
        isLocalImage: true,
      ),
    );
  }
}

// ==========================================
// 💡 3. FeedPage (หน้าหลัก)
// ==========================================
class FeedPage extends StatelessWidget {
  FeedPage({super.key});

  final FeedController feedController = Get.put(FeedController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Image.asset(
                    'assets/images/How 1.png',
                    width: 65,
                    height: 88,
                  ),
                ),
              ),
              Divider(thickness: 1, color: Colors.grey.shade200),
              GestureDetector(
                onTap: () =>
                    showPostSheet(mode: PostComposerMode.feedTextImageOnly),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          'คุณกำลังคิดอะไรอยู่.....',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/images/Picture.png',
                        width: 40,
                        height: 35,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              Divider(thickness: 1, color: Colors.grey.shade200),

              Obx(
                () => Column(
                  children: feedController.posts
                      .map(
                        (post) => Column(
                          children: [
                            PostItem(post: post), // ✅ ส่ง Model เข้าไปตรงๆ
                            Divider(thickness: 1, color: Colors.grey.shade200),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 💡 4. PostItem (แก้ไขให้รองรับข้อมูลทุกรูปแบบเพื่อกัน Error)
// ==========================================
class PostItem extends StatelessWidget {
  final PostModel? post; // รองรับแบบส่ง Model มา

  // 💡 เพิ่มตรงนี้เผื่อหน้า FeedProfilePage ยังส่งค่าแยกกันอยู่ แอปจะได้ไม่พังครับ
  final String? name;
  final String? avatarUrl;
  final String? content;
  final int? likes;
  final bool? showImage;

  const PostItem({
    super.key,
    this.post,
    this.name,
    this.avatarUrl,
    this.content,
    this.likes,
    this.showImage,
  });

  @override
  Widget build(BuildContext context) {
    // 💡 ถ้าไม่ได้ส่ง post มา ให้สร้าง Model จำลองจากค่าที่ส่งแยกมาครับ (กัน Error int vs RxInt)
    final PostModel displayPost =
        post ??
        PostModel(
          name: name ?? 'Unknown',
          avatarUrl: avatarUrl ?? '',
          content: content ?? '',
          likes: likes ?? 0,
          showImage: showImage ?? false,
        );

    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Get.to(
                    () => FeedProfilePage(
                      name: displayPost.name,
                      avatarUrl: displayPost.avatarUrl,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(displayPost.avatarUrl),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  displayPost.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              displayPost.content,
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 10),

            if (displayPost.showImage)
              Center(
                child: Container(
                  height: 300,
                  width: 250,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image:
                          (displayPost.isLocalImage &&
                              displayPost.imagePath != null)
                          ? FileImage(File(displayPost.imagePath!))
                                as ImageProvider
                          : NetworkImage(
                              displayPost.imagePath ??
                                  'https://i.pinimg.com/736x/b7/ac/ba/b7acba5c729ea828c9ed398f21248681.jpg',
                            ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

            GestureDetector(
              onTap: () {
                displayPost.isLiked.value = !displayPost.isLiked.value;
                if (displayPost.isLiked.value) {
                  displayPost.likes.value++;
                } else {
                  displayPost.likes.value--;
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    displayPost.isLiked.value
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: displayPost.isLiked.value
                        ? const Color(0xFF4489D7)
                        : Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(width: 6),
                  // 💡 สำคัญ: ต้องใช้ .value.toString() เสมอ!
                  Text(
                    displayPost.likes.value.toString(),
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: displayPost.isLiked.value
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 💡 5. FeedProfilePage (หน้าโปรไฟล์)
// ==========================================
class FeedProfilePage extends StatelessWidget {
  final String name;
  final String avatarUrl;

  const FeedProfilePage({
    super.key,
    required this.name,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(radius: 50, backgroundImage: NetworkImage(avatarUrl)),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            PostItem(
              name: name,
              avatarUrl: avatarUrl,
              content: "ตัวอย่างโพสต์ในหน้าโปรไฟล์...",
              likes: 10,
              showImage: false,
            ),
          ],
        ),
      ),
    );
  }
}

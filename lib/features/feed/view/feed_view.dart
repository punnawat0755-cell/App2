import 'package:flutter/material.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --- 1. ส่วนโลโก้ด้านบน ---
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

              // --- 2. ส่วนช่อง "คุณกำลังคิดอะไรอยู่" ---
              Padding(
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
                      'assets/images/Picture.png', // <-- ใส่ path รูปของคุณตรงนี้
                      width: 40, // กำหนดขนาด (ปกติ Icon จะประมาณ 24)
                      height: 35,
                      fit: BoxFit.contain, // จัดวางรูปให้พอดี
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              Divider(thickness: 1, color: Colors.grey.shade200),

              // --- 3. รายการโพสต์ ---
              const PostItem(
                name: "seal",
                avatarUrl:
                    "https://api.dicebear.com/9.x/adventurer/png?seed=Felix",
                content:
                    "อนุญาตให้ตัวเอง 'ไม่โอเค' บ้างก็ได้ ไม่จำเป็นต้องแบกความเข้มแข็งไว้ตลอดเวลา...",
                likes: 15,
                showImage: false,
              ),

              Divider(thickness: 1, color: Colors.grey.shade200),

              const PostItem(
                name: "seal2",
                avatarUrl:
                    "https://api.dicebear.com/9.x/adventurer/png?seed=Felix",
                content:
                    "คุณค่าของคุณไม่ได้ลดลงในวันที่คุณทำพลาด หรือในวันที่ใครมองไม่เห็น...",
                likes: 8,
                showImage: false,
              ),

              Divider(thickness: 1, color: Colors.grey.shade200),

              const PostItem(
                name: "puffer",
                avatarUrl:
                    "https://api.dicebear.com/9.x/adventurer/png?seed=Buddy",
                content: "สุขใจเมื่อได้เจอ",
                likes: 138,
                showImage: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
//  Widget: PostItem (เพิ่มระบบกดไลก์ +1)
// ---------------------------------------------------------
class PostItem extends StatefulWidget {
  final String name;
  final String content;
  final int likes;
  final bool showImage;
  final String avatarUrl;
  final bool showFollowButton;

  const PostItem({
    super.key,
    required this.name,
    required this.content,
    required this.likes,
    required this.showImage,
    required this.avatarUrl,
    this.showFollowButton = true,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  // สถานะติดตาม
  bool isFollowing = false;

  // สถานะไลก์ (เพิ่มใหม่)
  bool isLiked = false;
  late int likeCount; // ตัวแปรเก็บจำนวนไลก์ปัจจุบัน

  @override
  void initState() {
    super.initState();
    // เริ่มต้นให้จำนวนไลก์เท่ากับค่าที่ส่งเข้ามา (เช่น 15)
    likeCount = widget.likes;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // กดรูปแล้วไปหน้า Profile
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FeedProfilePage(
                        name: widget.name,
                        avatarUrl: widget.avatarUrl,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: NetworkImage(widget.avatarUrl),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                widget.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              if (widget.showFollowButton) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isFollowing = !isFollowing;
                    });
                  },
                  child: isFollowing
                      ? const Icon(Icons.verified, color: Colors.grey, size: 20)
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "ติดตาม",
                            style: TextStyle(
                              color: Color(0xFF8D8D8D),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          Text(
            widget.content,
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),

          const SizedBox(height: 10),

          if (widget.showImage)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://i.pinimg.com/736x/b7/ac/ba/b7acba5c729ea828c9ed398f21248681.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),

          // --- ส่วนปุ่ม Like (แก้ไขใหม่) ---
          GestureDetector(
            onTap: () {
              setState(() {
                isLiked = !isLiked; // สลับสถานะ กด/เลิกกด
                if (isLiked) {
                  likeCount++; // ถ้ากดไลก์ -> บวก 1
                } else {
                  likeCount--; // ถ้ากดซ้ำ (เลิกไลก์) -> ลบ 1
                }
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min, // ให้พื้นที่ปุ่มแค่พอดีคำ
              children: [
                Icon(
                  isLiked
                      ? Icons.favorite
                      : Icons.favorite_border, // เปลี่ยนรูปหัวใจ ทึบ/โปร่ง
                  color: isLiked
                      ? Color(0xFF4489D7)
                      : Colors.grey, // เปลี่ยนสี แดง/ฟ้า
                  size: 32,
                ),
                const SizedBox(width: 6),
                Text(
                  likeCount.toString(),
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
//  Widget: ProfilePage
// ---------------------------------------------------------
class FeedProfilePage extends StatefulWidget {
  final String name;
  final String avatarUrl;

  const FeedProfilePage({
    super.key,
    required this.name,
    required this.avatarUrl,
  });

  @override
  State<FeedProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<FeedProfilePage> {
  bool isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(widget.avatarUrl),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isFollowing = !isFollowing;
                          });
                        },
                        child: isFollowing
                            ? const Icon(
                                Icons.verified,
                                color: Colors.grey,
                                size: 28,
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.lightBlue.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "ติดตาม",
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(thickness: 1, color: Colors.grey.shade200),
            PostItem(
              name: widget.name,
              avatarUrl: widget.avatarUrl,
              content:
                  "อนุญาตให้ตัวเอง 'ไม่โอเค' บ้างก็ได้ ไม่จำเป็นต้องแบกความเข้มแข็งไว้ตลอดเวลา 24 ชม. หรอกนะ...",
              likes: 15,
              showImage: false,
              showFollowButton: false,
            ),
            Divider(thickness: 1, color: Colors.grey.shade200),
            PostItem(
              name: widget.name,
              avatarUrl: widget.avatarUrl,
              content:
                  "ไม่ต้องพยายามยืนในจุดที่ 'สูงที่สุด' แค่พาตัวเองไปอยู่ในจุดที่ 'ดีกว่าเดิม' ก็พอแล้ว✌️🌱",
              likes: 8,
              showImage: false,
              showFollowButton: false,
            ),
            Divider(thickness: 1, color: Colors.grey.shade200),
            PostItem(
              name: widget.name,
              avatarUrl: widget.avatarUrl,
              content:
                  "อนุญาตให้ตัวเองมีความสุข... โดยไม่ต้องรอให้ใครมาอนุมัติ โลกโหดร้ายกับเราพอแล้ว อย่าลืมใจดีกับตัวเองบ้างนะ🤍✨",
              likes: 10,
              showImage: false,
              showFollowButton: false,
            ),
            Divider(thickness: 1, color: Colors.grey.shade200),
            PostItem(
              name: widget.name,
              avatarUrl: widget.avatarUrl,
              content:
                  "ชีวิตไม่ได้ต้องการคนเก่งที่สุด แต่ต้องการคนที่ 'อดทน' เก่งที่สุดต่างหาก กาแฟแก้วที่สามของวันจงสถิตอยู่กับท่าน☕💪",
              likes: 2,
              showImage: false,
              showFollowButton: false,
            ),
          ],
        ),
      ),
    );
  }
}

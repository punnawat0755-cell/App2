import 'package:flutter/material.dart';

class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            // 1. ส่วน Logo ด้านบน
            _buildTopLogoSection(),

            const Divider(height: 1),

            // 2. ส่วนช่องกรอกข้อความ (Input)
            _buildInputSection(),

            const Divider(
              thickness: 8,
              color: Color(0xFFF5F5F5),
            ), // แถบกั้นหนาๆ
            // 3. Post ที่ 1 (User: seal)
            _buildPostItem(
              profileColor: Colors.grey[300]!,
              username: "seal",
              content:
                  "อนุญาตให้ตัวเอง 'ไม่โอเค' บ้างก็ได้ ไม่จำเป็นต้องแบกความเข้มแข็งไว้ตลอดเวลา 24 ชม. หรอกนะ การยอมรับความเปราะบางของตัวเอง คือก้าวแรกของการเยียวยาที่แท้จริง 🤍",
              likeCount: 15,
              isLiked: true,
            ),

            const Divider(height: 1),

            // 4. Post ที่ 2 (User: seal2)
            _buildPostItem(
              profileColor: Colors.grey[400]!,
              username: "seal2",
              content:
                  "คุณค่าของคุณไม่ได้ลดลงในวันที่คุณทำพลาด หรือในวันที่ใครมองไม่เห็น ดอกไม้ยงคงเป็นดอกไม้แม้ในวันที่ไม่มีใครชม คุณเองก็เช่นกัน 🌷",
              likeCount: 8,
              isLiked: false,
            ),

            const Divider(height: 1),

            // 5. Post ที่ 3 (User: puffer) - มีรูปภาพ/วิดีโอ
            _buildPostItem(
              profileColor: Colors.orange[100]!,
              username: "puffer",
              content: "สุขใจเมื่อได้เจอ",
              likeCount: 138,
              isLiked: false,
              hasMedia: true, // เปิดใช้งานส่วนแสดงรูป
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget: ส่วน Logo
  Widget _buildTopLogoSection() {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Image.asset("assets/images/How 1.png")],
      ),
    );
  }

  // Widget: ช่อง Input "คุณกำลังคิดอะไรอยู่"
  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            backgroundImage: NetworkImage(
              'https://via.placeholder.com/150',
            ), // รูป Avatar ของเรา
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "คุณกำลังคิดอะไรอยู่.....",
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ),
          Icon(Icons.photo_library_outlined, color: Colors.grey[400]),
        ],
      ),
    );
  }

  // Widget: สร้าง Post แต่ละอัน (Reusable Widget)
  Widget _buildPostItem({
    required Color profileColor,
    required String username,
    required String content,
    required int likeCount,
    required bool isLiked,
    bool hasMedia = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name + Follow Button
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: profileColor,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ), // Placeholder icon
              ),
              const SizedBox(width: 10),
              Text(
                username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.lightBlue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "ติดตาม",
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content Text
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.5,
            ),
          ),

          // Media (Image/Video) ถ้ามี
          if (hasMedia) ...[
            const SizedBox(height: 12),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[300],
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://via.placeholder.com/400x600/87CEEB/FFFFFF?text=Sky',
                  ), // รูปท้องฟ้าจำลอง
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.play_arrow, color: Colors.grey),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Footer: Like Icon + Count
          Row(
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.blue : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 6),
              Text("$likeCount", style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

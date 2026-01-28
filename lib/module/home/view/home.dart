import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/home/view/test.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentBannerIndex = 0;
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // ตั้งเวลาเลื่อนแบนเนอร์อัตโนมัติ
    _timer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
      if (_currentBannerIndex < 2) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const name = 'Seal';

    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/thai.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // รูปโปรไฟล์
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://i.pinimg.com/736x/ed/15/c6/ed15c639cc2c49b51d8e5b1c1743a37d.jpg',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'สวัสดี,$name',
                style: const TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 15),

              // --- Banner Section ---
              SizedBox(
                height: 160,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentBannerIndex = index;
                    });
                  },
                  children: [
                    _buildDailyMissionBanner(),
                    // _buildClownFishBanner(),
                    // _buildLoveJobBanner(),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // จุดไข่ปลา
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentBannerIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentBannerIndex == index
                          ? const Color(0xFF4489D7)
                          : Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 10),

              // --- Short Clips ---
              _buildSectionHeader('คลิปสั้น'),
              const SizedBox(height: 15),
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      onTap: () {
                        Get.to(() => VideoApp());
                      },
                      child: _buildClipCard(
                        title: 'Jellyfish',
                        subtitle: '2 week',
                        imagePath:
                            'https://i.pinimg.com/1200x/10/fd/6c/10fd6c2086373b9007700b8f997545f1.jpg',
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Get.to(() => PlayVideoFromNetwork());
                      },
                      child: _buildClipCard(
                        title: 'starfish',
                        subtitle: '1 week',
                        imagePath:
                            'https://i.pinimg.com/736x/e0/e4/4d/e0e44d1c32bf9b484430e4cb74bf2719.jpg',
                      ),
                    ),
                    _buildClipCard(
                      title: 'whale',
                      subtitle: '1 day',
                      imagePath:
                          'https://i.pinimg.com/1200x/2a/92/db/2a92db9b4048574f9b24f57108d3a2ef.jpg',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // --- Articles ---
              _buildSectionHeader('บทความจิตวิทยา'),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildArticleCard(
                      title: 'วาฬ 52Hz\nไม่ได้อยู่คนเดียว',
                      subtitle: '1 Month Ago',
                      imagePath: 'assets/images/s2.png',
                      // [เพิ่ม] ใส่ onTap เพื่อลิ้งค์ไปหน้าเนื้อหา
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ArticleDetailPage(
                              title: 'วาฬ 52Hz ไม่ได้อยู่คนเดียว',
                              imagePath: 'assets/images/s2.png',
                              content: """
เคยถูกใช้เป็นภาพสะท้อนความเหงาที่รุนแรงที่สุดของมนุษย์ เรามักฉายภาพความกลัวการถูกทอดทิ้งและความรู้สึกแปลกแยกของตัวเองลงไปที่มัน จนกลายเป็นสัญลักษณ์ของการ "มีเสียงที่ไม่มีใครได้ยิน"

แต่ในทางจิตวิทยา เมื่อวิทยาศาสตร์เริ่มค้นพบว่ามันอาจไม่ได้อยู่ลำพัง และอาจมีวาฬตัวอื่นที่ใช้คลื่นความถี่นี้เช่นกัน การตีความจึงเปลี่ยนไปอย่างสิ้นเชิง จากเดิมที่เป็นโศกนาฏกรรมของความโดดเดี่ยว กลายมาเป็นบทเรียนสำคัญเรื่อง "ความแตกต่างของการสื่อสาร" (Communication Differences)

การที่มันส่งเสียงในคลื่นความถี่ที่ไม่เหมือนใครไม่ได้หมายความว่ามันบกพร่อง หรือไร้ค่า แต่อาจเป็นเพียงการแสดงออกถึงตัวตนที่แท้จริงในรูปแบบเฉพาะทาง ซึ่งสะท้อนให้เห็นว่าในสังคมมนุษย์ การที่เราไม่ได้คิดหรือพูดเหมือนคนส่วนใหญ่ ไม่ได้แปลว่าเราผิดปกติแต่อาจเป็นเพียงความแตกต่างของคลื่นความถี่ที่เราเลือกใช้เท่านั้น

การเปลี่ยนมุมมองนี้ช่วยเยียวยาจิตใจได้ดีกว่าเดิม เพราะมันย้ำเตือนเราว่า "ความแตกต่าง" ไม่ได้เท่ากับ "ความเดียวดาย" เสมอไป ในทางจิตวิทยา การยอมรับและยืนหยัดในความเป็นตัวเอง (Authenticity) แม้จะดูแปลกแยกในตอนแรก คือก้าวสำคัญของสุขภาพจิตที่ดี

เราไม่จำเป็นต้องพยายามบิดเบือนคลื่นเสียงของตัวเองให้กลายเป็น 15-25Hz เหมือนวาฬส่วนใหญ่เพียงเพื่อให้ถูกนับรวมเข้าฝูง เพราะการฝืนทำในสิ่งที่ไม่ใช่ตัวเองจะนำไปสู่ความเหงาภายในที่ลึกซึ้งยิ่งกว่า

บทสรุปใหม่ของวาฬ 52Hz จึงให้ความหวังว่า การดำรงอยู่ด้วยความเป็นตัวเองอย่างแท้จริงนั้นมีคุณค่าเสมอ และที่ไหนสักแห่งในมหาสมุทรอันกว้างใหญ่นี้ ย่อมมีผู้ที่พร้อมจะรับฟังหรือเข้าใจคลื่นความถี่ที่เป็นเอกลักษณ์ของคุณอยู่จริง""",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildArticleCard(
                      title: 'อยู่คนเดียวก็มีความ\nสุขดีนะ',
                      subtitle: '3 Month Ago',
                      imagePath: 'assets/images/s1.png',
                      // [เพิ่ม] ใส่ onTap สำหรับการ์ดใบที่ 2
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ArticleDetailPage(
                              title: 'อยู่คนเดียวก็มีความสุขดีนะ',
                              imagePath: 'assets/images/s1.png',
                              content:
                                  """การอยู่คนเดียวไม่ได้หมายความว่าต้องเหงาเสมอไป การได้ใช้เวลากับตัวเองคือโอกาสที่ดีในการทำความเข้าใจความต้องการของตัวเอง พัฒนาทักษะใหม่ๆ และเติมพลังให้กับจิตใจ

ความสุขไม่ได้ขึ้นอยู่กับจำนวนคนรอบข้าง แต่อยู่ที่ความพึงพอใจในตัวเองและการมองเห็นคุณค่าในสิ่งเล็กๆ น้อยๆ รอบตัว ลองหาเวลาวันละนิดเพื่อทำสิ่งที่ชอบ หรือแค่นั่งจิบกาแฟเงียบๆ ก็อาจเป็นช่วงเวลาที่มีคุณภาพที่สุดของวันได้""",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGETS
  // --------------------------------------------------------------------------
  Widget _buildDailyMissionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFB5EFFF),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -9,
            bottom: 4,
            child: Image.asset('assets/images/whale.png', height: 130),
          ),
          Positioned(
            left: 10,
            top: 20,
            bottom: 20,
            child: Image.asset(
              'assets/images/list.png',
              fit: BoxFit.contain,
              height: 200,
              width: 90,
            ),
          ),
          Positioned(
            left: 105,
            top: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ภารกิจรายวัน :',
                  style: TextStyle(
                    color: Color(0xFF4489D7),
                    fontWeight: FontWeight.w200,
                    fontSize: 15,
                  ),
                ),
                const Text(
                  'ตอบคำถามเพื่อรับเพื่อนแก้เหงา',
                  style: TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 15,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Image.asset('assets/images/k1.png'),
                    const SizedBox(width: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'DAY',
                          style: TextStyle(
                            color: Color(0xFF4489D7),
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        Text(
                          '138',
                          style: TextStyle(
                            color: Color(0xFF4489D7),
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            height: 0.9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClownFishBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE6A8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            bottom: -15,
            right: 10,
            left: 10,
            child: Image.asset('assets/images/N1.png', fit: BoxFit.contain),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'ในวันที่โลกใจร้ายกับเรา\nอย่าลืมใจดีกับตัวเองให้มากๆ นะ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF8D6E63),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.4,
                  shadows: [
                    Shadow(
                      color: Colors.white.withOpacity(0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoveJobBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFB3E5FC),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -10,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/w1.png',
              height: 90,
              width: 150,
              fit: BoxFit.contain,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(height: 1),
                  Text(
                    'I love my job',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ถ้าวันนี้คุณเหนื่อยก็แค่กลับไปพัก',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4489D7),
          ),
        ),
        const SizedBox(width: 5),
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ],
    );
  }

  Widget _buildClipCard({
    required String title,
    required String subtitle,
    required String imagePath,
  }) {
    bool isNetworkImage = imagePath.startsWith('http');

    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: isNetworkImage
              ? NetworkImage(imagePath)
              : AssetImage(imagePath) as ImageProvider,
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            print("โหลดรูปไม่ได้: $imagePath");
          },
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
          ),
          const Center(
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.play_arrow,
                color: Color.fromARGB(255, 200, 200, 200),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    bool isNetworkImage = imagePath.startsWith('http');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: isNetworkImage
                    ? Image.network(
                        imagePath,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        imagePath,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF5A6B7C),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} // <--- ปิด Class _HomePageState ตรงนี้

// --- หน้าจอแสดงรายละเอียดบทความ (ย้ายออกมาข้างนอก) ---
class ArticleDetailPage extends StatelessWidget {
  final String title;
  final String imagePath;
  final String content;

  const ArticleDetailPage({
    super.key,
    required this.title,
    required this.imagePath,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    bool isNetworkImage = imagePath.startsWith('http');

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: isNetworkImage
                    ? Image.network(
                        imagePath,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        imagePath,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                content,
                style: const TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/view/widget/article/article_card.dart';
import 'package:flutter_application_1/features/home/view/widget/article/article_detail.dart';
import 'package:flutter_application_1/features/home/view/widget/home_widgets.dart';
import 'package:flutter_application_1/features/profile/controller/profile_avatar_controller.dart';
import 'package:flutter_application_1/supabase_client.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentBannerIndex = 0;
  late final PageController _pageController;
  Timer? _timer;

  bool _isNameLoading = true;
  String _displayName = 'ผู้ใช้';

  final List<_HomeClip> _clipList = const [
    _HomeClip(
      title: 'Jellyfish',
      subtitle: '2 week',
      imagePath:
          'https://i.pinimg.com/1200x/10/fd/6c/10fd6c2086373b9007700b8f997545f1.jpg',
    ),
    _HomeClip(
      title: 'starfish',
      subtitle: '1 week',
      imagePath:
          'https://i.pinimg.com/736x/e0/e4/4d/e0e44d1c32bf9b484430e4cb74bf2719.jpg',
    ),
    _HomeClip(
      title: 'whale',
      subtitle: '1 day',
      imagePath:
          'https://i.pinimg.com/1200x/2a/92/db/2a92db9b4048574f9b24f57108d3a2ef.jpg',
    ),
    _HomeClip(
      title: 'whale',
      subtitle: '1 day',
      imagePath:
          'https://i.pinimg.com/1200x/2a/92/db/2a92db9b4048574f9b24f57108d3a2ef.jpg',
    ),
    _HomeClip(
      title: 'whale',
      subtitle: '1 day',
      imagePath:
          'https://i.pinimg.com/1200x/2a/92/db/2a92db9b4048574f9b24f57108d3a2ef.jpg',
    ),
  ];

  final List<_HomeArticle> _articleList = const [
    _HomeArticle(
      title: 'วาฬ 52Hz\nไม่ได้อยู่คนเดียว',
      subtitle: '1 Month Ago',
      imagePath: 'assets/images/article1.png',
      detailImagePath: 'assets/images/article1.png',
      detailTitle: 'วาฬ 52Hz ไม่ได้อยู่คนเดียว',
      content: '''
เคยถูกใช้เป็นภาพสะท้อนความเหงาที่รุนแรงที่สุดของมนุษย์ เรามักฉายภาพความกลัวการถูกทอดทิ้งและความรู้สึกแปลกแยกของตัวเองลงไปที่มัน จนกลายเป็นสัญลักษณ์ของการ "มีเสียงที่ไม่มีใครได้ยิน"

แต่ในทางจิตวิทยา เมื่อวิทยาศาสตร์เริ่มค้นพบว่ามันอาจไม่ได้อยู่ลำพัง และอาจมีวาฬตัวอื่นที่ใช้คลื่นความถี่นี้เช่นกัน การตีความจึงเปลี่ยนไปอย่างสิ้นเชิง จากเดิมที่เป็นโศกนาฏกรรมของความโดดเดี่ยว กลายมาเป็นบทเรียนสำคัญเรื่อง "ความแตกต่างของการสื่อสาร" (Communication Differences)

การที่มันส่งเสียงในคลื่นความถี่ที่ไม่เหมือนใครไม่ได้หมายความว่ามันบกพร่อง หรือไร้ค่า แต่อาจเป็นเพียงการแสดงออกถึงตัวตนที่แท้จริงในรูปแบบเฉพาะทาง ซึ่งสะท้อนให้เห็นว่าในสังคมมนุษย์ การที่เราไม่ได้คิดหรือพูดเหมือนคนส่วนใหญ่ ไม่ได้แปลว่าเราผิดปกติแต่อาจเป็นเพียงความแตกต่างของคลื่นความถี่ที่เราเลือกใช้เท่านั้น

การเปลี่ยนมุมมองนี้ช่วยเยียวยาจิตใจได้ดีกว่าเดิม เพราะมันย้ำเตือนเราว่า "ความแตกต่าง" ไม่ได้เท่ากับ "ความเดียวดาย" เสมอไป ในทางจิตวิทยา การยอมรับและยืนหยัดในความเป็นตัวเอง (Authenticity) แม้จะดูแปลกแยกในตอนแรก คือก้าวสำคัญของสุขภาพจิตที่ดี

เราไม่จำเป็นต้องพยายามบิดเบือนคลื่นเสียงของตัวเองให้กลายเป็น 15-25Hz เหมือนวาฬส่วนใหญ่เพียงเพื่อให้ถูกนับรวมเข้าฝูง เพราะการฝืนทำในสิ่งที่ไม่ใช่ตัวเองจะนำไปสู่ความเหงาภายในที่ลึกซึ้งยิ่งกว่า

บทสรุปใหม่ของวาฬ 52Hz จึงให้ความหวังว่า การดำรงอยู่ด้วยความเป็นตัวเองอย่างแท้จริงนั้นมีคุณค่าเสมอ และที่ไหนสักแห่งในมหาสมุทรอันกว้างใหญ่นี้ ย่อมมีผู้ที่พร้อมจะรับฟังหรือเข้าใจคลื่นความถี่ที่เป็นเอกลักษณ์ของคุณอยู่จริง''',
    ),
    _HomeArticle(
      title: 'อยู่คนเดียวก็มีความ\nสุขดีนะ',
      subtitle: '3 Month Ago',
      imagePath: 'assets/images/article2.png',
      detailImagePath: 'assets/images/article2.png',
      detailTitle: 'อยู่คนเดียวก็มีความสุขดีนะ',
      content: '''
การอยู่คนเดียวไม่ได้หมายความว่าต้องเหงาเสมอไป การได้ใช้เวลากับตัวเองคือโอกาสที่ดีในการทำความเข้าใจความต้องการของตัวเอง พัฒนาทักษะใหม่ๆ และเติมพลังให้กับจิตใจ

ความสุขไม่ได้ขึ้นอยู่กับจำนวนคนรอบข้าง แต่อยู่ที่ความพึงพอใจในตัวเองและการมองเห็นคุณค่าในสิ่งเล็กๆ น้อยๆ รอบตัว ลองหาเวลาวันละนิดเพื่อทำสิ่งที่ชอบ หรือแค่นั่งจิบกาแฟเงียบๆ ก็อาจเป็นช่วงเวลาที่มีคุณภาพที่สุดของวันได้''',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadUsername();

    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
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

  Future<void> _loadUsername() async {
    setState(() => _isNameLoading = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _displayName = 'ผู้ใช้';
        _isNameLoading = false;
      });
      return;
    }

    const apiKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2YmFnZGhqbGtsbXlzamp1dmh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgzNzQ0MjcsImV4cCI6MjA4Mzk1MDQyN30.pqinIw8uza_02BRRheQrBLNnRK0InCBBXG00HmB0Bys';
    final apiUrl =
        'https://dvbagdhjlklmysjjuvht.supabase.co/rest/v1/profiles?select=username&id=eq.${user.id}';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          final username = data[0]['username']?.toString().trim();

          if (!mounted) return;
          setState(() {
            _displayName =
                (username != null && username.isNotEmpty) ? username : 'ผู้ใช้';
            _isNameLoading = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            _displayName = 'ผู้ใช้';
            _isNameLoading = false;
          });
        }
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      debugPrint('Error fetching user from API: $e');
      if (!mounted) return;
      setState(() {
        _displayName = 'ผู้ใช้';
        _isNameLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await supabase.auth.signOut();
    if (!mounted) return;

    setState(() {
      _displayName = 'ผู้ใช้';
      _isNameLoading = false;
    });
  }

  void _handleClipTap(_HomeClip clip) {
    debugPrint('ยังไม่มีหน้าปลายทางสำหรับ ${clip.title}');
  }

  @override
  Widget build(BuildContext context) {
    final avatarController = Get.isRegistered<ProfileAvatarController>()
        ? Get.find<ProfileAvatarController>()
        : Get.put(ProfileAvatarController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, color: Color(0xFF4489D7)),
                    tooltip: 'Log out',
                  ),
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Obx(
                      () => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: DecorationImage(
                            image: avatarController.avatarImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                _isNameLoading ? 'สวัสดี, ...' : 'สวัสดี,$_displayName',
                style: const TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 160,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentBannerIndex = index;
                    });
                  },
                  children: const [
                    DailyMissionBanner(),
                    ClownFishBanner(),
                    LoveJobBanner(),
                  ],
                ),
              ),
              const SizedBox(height: 15),
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
                          : Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              const HomeSectionHeader(title: 'คลิปสั้น'),
              const SizedBox(height: 15),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.zero,
                  itemCount: _clipList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 15),
                  itemBuilder: (context, index) {
                    final clip = _clipList[index];
                    return InkWell(
                      onTap: () => _handleClipTap(clip),
                      child: ClipCard(
                        title: clip.title,
                        subtitle: clip.subtitle,
                        imagePath: clip.imagePath,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),
              const HomeSectionHeader(title: 'บทความจิตวิทยา'),
              const SizedBox(height: 15),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.zero,
                  itemCount: _articleList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 15),
                  itemBuilder: (context, index) {
                    final article = _articleList[index];
                    return SizedBox(
                      width: 160,
                      child: ArticleCard(
                        title: article.title,
                        subtitle: article.subtitle,
                        imagePath: article.imagePath,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArticleDetailPage(
                                title: article.detailTitle,
                                imagePath: article.detailImagePath,
                                content: article.content,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeClip {
  const _HomeClip({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  final String title;
  final String subtitle;
  final String imagePath;
}

class _HomeArticle {
  const _HomeArticle({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.detailImagePath,
    required this.detailTitle,
    required this.content,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final String detailImagePath;
  final String detailTitle;
  final String content;
}

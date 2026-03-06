import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/home/view/test_view.dart';
import 'package:flutter_application_1/module/home/view/widget/home_widgets.dart';
import 'package:flutter_application_1/module/home/view/widget/article/article_card.dart';
import 'package:flutter_application_1/module/home/view/widget/article/article_detail.dart';
import 'package:flutter_application_1/module/setting/view/setting_view.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxInt currentBannerIndex = 0.obs;
  late final PageController pageController;
  Timer? timer;

  // ข้อมูลจำลอง (Mock Data)
  final List<Map<String, dynamic>> clipList = [
    {
      "title": "Jellyfish",
      "subtitle": "2 week",
      "imagePath":
          "https://i.pinimg.com/1200x/10/fd/6c/10fd6c2086373b9007700b8f997545f1.jpg",
      "page": () => VideoApp(), // เก็บฟังก์ชันการเปลี่ยนหน้าไว้ที่นี่
    },
    {
      "title": "starfish",
      "subtitle": "1 week",
      "imagePath":
          "https://i.pinimg.com/736x/e0/e4/4d/e0e44d1c32bf9b484430e4cb74bf2719.jpg",
      "page": () => PlayVideoFromNetwork(),
    },
    {
      "title": "whale",
      "subtitle": "1 day",
      "imagePath":
          "https://i.pinimg.com/1200x/2a/92/db/2a92db9b4048574f9b24f57108d3a2ef.jpg",
      "page": null, // อันนี้ยังไม่มีหน้าปลายทาง ใส่ null ไว้ก่อน
    },
    {
      "title": "whale",
      "subtitle": "1 day",
      "imagePath":
          "https://i.pinimg.com/1200x/2a/92/db/2a92db9b4048574f9b24f57108d3a2ef.jpg",
      "page": null, // อันนี้ยังไม่มีหน้าปลายทาง ใส่ null ไว้ก่อน
    },
    {
      "title": "whale",
      "subtitle": "1 day",
      "imagePath":
          "https://i.pinimg.com/1200x/2a/92/db/2a92db9b4048574f9b24f57108d3a2ef.jpg",
      "page": null, // อันนี้ยังไม่มีหน้าปลายทาง ใส่ null ไว้ก่อน
    },
  ];

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);

    // ตั้งเวลาเลื่อนแบนเนอร์อัตโนมัติ
    timer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
      if (currentBannerIndex.value < 2) {
        currentBannerIndex.value++;
      } else {
        currentBannerIndex.value = 0;
      }

      if (pageController.hasClients) {
        pageController.animateToPage(
          currentBannerIndex.value,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void onClose() {
    timer?.cancel();
    pageController.dispose();
    super.onClose();
  }
}

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController controller = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    const name = 'Seal';
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
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
                        const SizedBox(width: 8),
                        // รูปโปรไฟล์
                        GestureDetector(
                          onTap: () => Get.to(() => const SettingPage()),
                          child: Container(
                            width: 50,
                            height: 50,
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
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),

                // --- Banner Section ---
                SizedBox(
                  height: 160,
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: (index) {
                      controller.currentBannerIndex.value = index;
                    },
                    children: [
                      const DailyMissionBanner(),
                      const ClownFishBanner(),
                      const LoveJobBanner(),
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
                      width: controller.currentBannerIndex.value == index
                          ? 24
                          : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: controller.currentBannerIndex.value == index
                            ? const Color(0xFF4489D7)
                            : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 10),

                // --- Short Clips ---
                const HomeSectionHeader(title: 'คลิปสั้น'),
                const SizedBox(height: 15),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                    ), // เพิ่มระยะขอบซ้าย-ขวาของ List
                    itemCount: controller.clipList.length,
                    // ตัวคั่นระหว่าง item (เว้นระยะห่าง 15 px)
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 5),
                    // ตัวสร้าง Item
                    itemBuilder: (context, index) {
                      final item = controller.clipList[index];

                      return InkWell(
                        onTap: () {
                          // เช็คว่ามีหน้าปลายทางไหม ถ้ามีค่อยกดไป
                          if (item['page'] != null) {
                            Get.to(item['page']);
                          } else {
                            print("ยังไม่มีหน้าปลายทางสำหรับ ${item['title']}");
                          }
                        },
                        child: ClipCard(
                          title: item['title'],
                          subtitle: item['subtitle'],
                          imagePath: item['imagePath'],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 25),

                // --- Articles ---
                const HomeSectionHeader(title: 'บทความจิตวิทยา'),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: ArticleCard(
                        title: 'วาฬ 52Hz\nไม่ได้อยู่คนเดียว',
                        subtitle: '1 Month Ago',
                        imagePath: 'assets/images/52Hz.png',
                        // [เพิ่ม] ใส่ onTap เพื่อลิ้งค์ไปหน้าเนื้อหา
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ArticleDetailPage(
                                title: 'วาฬ 52Hz ไม่ได้อยู่คนเดียว',
                                imagePath: 'assets/images/article1.png',
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
                      child: ArticleCard(
                        title: 'อยู่คนเดียวก็มีความ\nสุขดีนะ',
                        subtitle: '3 Month Ago',
                        imagePath: 'assets/images/article2.png',
                        // [เพิ่ม] ใส่ onTap สำหรับการ์ดใบที่ 2
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ArticleDetailPage(
                                title: 'อยู่คนเดียวก็มีความสุขดีนะ',
                                imagePath: 'assets/images/alon.png',
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

// ---------------------------------------------------------
// 1. Controller (Logic)
// ---------------------------------------------------------
class ChatSelectionController extends GetxController {
  void goToStartChat() {
    Get.to(() => WaitingChatPage());
  }

  void goToCounseling() {
    // ฟังก์ชันสำหรับปุ่มขวา
  }
}

// ---------------------------------------------------------
// 2. Main Page (View) - หน้าเลือกโหมด
// ---------------------------------------------------------
class ChatSelectionPage extends StatelessWidget {
  const ChatSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatSelectionController());

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Stack(
          children: [
            const _ProfileHeader(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'มาแชทกันเถอะ มีคนรอคุณอยู่ในแชท',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4489D7),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: SizedBox(
                      height: 300,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HalfCircleButton(
                            title: 'เริ่มแชท',
                            imagePath: 'assets/images/sad.png',
                            backgroundColor: const Color(0xFFAEDEF4),
                            textColor: const Color(0xFF4489D7),
                            isLeft: true,
                            onTap: controller.goToStartChat,
                            imagePadding: const EdgeInsets.only(
                              top: 10,
                              bottom: 25,
                              left: 20,
                            ),
                            imageScale: 0.95,
                            textPadding: const EdgeInsets.only(left: 55),
                          ),
                          const SizedBox(width: 9),
                          HalfCircleButton(
                            title: 'ให้คำปรึกษา',
                            imagePath: 'assets/images/fine.png',
                            backgroundColor: const Color(0xFFFDE6A8),
                            textColor: const Color(0xFF8D6E63),
                            isLeft: false,
                            onTap: controller.goToCounseling,
                            imagePadding: const EdgeInsets.only(
                              bottom: 3,
                              right: 8,
                            ),
                            imageScale: 0.8,
                            textPadding: const EdgeInsets.only(right: 50),
                          ),
                        ],
                      ),
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

// ---------------------------------------------------------
// 3. Custom Widgets (Components)
// ---------------------------------------------------------
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 35,
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
    );
  }
}

class HalfCircleButton extends StatelessWidget {
  final String title;
  final String imagePath;
  final Color backgroundColor;
  final Color textColor;
  final bool isLeft;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? imagePadding;
  final double imageScale;
  final EdgeInsetsGeometry? textPadding;

  const HalfCircleButton({
    super.key,
    required this.title,
    required this.imagePath,
    required this.backgroundColor,
    required this.textColor,
    required this.isLeft,
    required this.onTap,
    this.imagePadding,
    this.imageScale = 1.0,
    this.textPadding,
  });

  @override
  Widget build(BuildContext context) {
    const double radius = 2000;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: isLeft
                ? const BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    bottomLeft: Radius.circular(radius),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(radius),
                    bottomRight: Radius.circular(radius),
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                bottom: 50,
                child: Padding(
                  padding: imagePadding ?? const EdgeInsets.all(15.0),
                  child: Transform.scale(
                    scale: imageScale,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        isLeft
                            ? Icons.sentiment_dissatisfied
                            : Icons.sentiment_satisfied_alt,
                        size: 80,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 35,
                left: 0,
                right: 0,
                child: Padding(
                  padding: textPadding ?? EdgeInsets.zero,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
}

// ---------------------------------------------------------
// 4. หน้าจอรอคู่สนทนา (WaitingChatPage) - [หยุดเวลาเมื่อมี Pop-up]
// ---------------------------------------------------------
class WaitingChatController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final AnimationController animationController;
  Timer? timer;

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 5), () {
      Get.off(() => ChatPage());
    });
  }

  void showExitDialog(BuildContext context) {
    timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFFC3F3FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 50),
            height: 220,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "คุณต้องการที่จะออกจากการจับคู่ใช่หรือไม่",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.back();
                        Get.back();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8AD4F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "ยืนยัน",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        Get.back();
                        startTimer();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8AD4F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "ยกเลิก",
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
        );
      },
    );
  }

  @override
  void onClose() {
    animationController.dispose();
    timer?.cancel();
    super.onClose();
  }
}

class WaitingChatPage extends StatelessWidget {
  WaitingChatPage({super.key});

  final WaitingChatController controller = Get.isRegistered<WaitingChatController>()
      ? Get.find<WaitingChatController>()
      : Get.put(WaitingChatController());

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        controller.showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F9FF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
            onPressed: () => controller.showExitDialog(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'รอคู่สนทนาสักครู่',
                style: TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 450,
                height: 450,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildOneWayRipple(0.0),
                    _buildOneWayRipple(0.33),
                    _buildOneWayRipple(0.66),
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFAEDEF4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Image.asset(
                            'assets/images/sad.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOneWayRipple(double startDelay) {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        final double t = (controller.animationController.value + startDelay) % 1.0;
        final double currentSize = 240 + (180 * t);
        final double opacity = 0.4 * (1.0 - t);
        return Container(
          width: currentSize,
          height: currentSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFAEDEF4).withValues(alpha: opacity),
            border: Border.all(
              color: Colors.white.withValues(alpha: opacity),
              width: 1,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// 5. หน้าแชท (ChatPage)
// ---------------------------------------------------------
class ChatPageController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[
    {'text': 'ฉันรู้สึกเสียใจที่ทำงานพลาด', 'isMe': true},
    {'text': 'ฉันจัดการความรู้สึกนี้ยังไงดี', 'isMe': true},
    {
      'text':
          'ความเสียใจจากการทำงานพลาดเป็นเรื่องปกติและไม่ได้หมายความว่าคุณไม่เก่งสิ่งสำคัญคือการยอมรับความรู้สึกโดยไม่โทษตัวเองแยกความผิดพลาดออกจากคุณค่าในตัวเอง แล้วนำบทเรียนไปปรับใช้พร้อมดูแลใจตัวเองเพื่อก้าวต่อไปอย่างเข้มแข็ง',
      'isMe': false,
    },
  ].obs;

  void sendMessage() {
    if (textController.text.trim().isEmpty) return;
    messages.insert(0, {'text': textController.text, 'isMe': true});
    textController.clear();
  }

  void endConversation() {
    Get.to(() => ConversationSummaryPage());
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}

class ChatPage extends StatelessWidget {
  ChatPage({super.key});

  final ChatPageController controller = Get.isRegistered<ChatPageController>()
      ? Get.find<ChatPageController>()
      : Get.put(ChatPageController());

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: const Color(0xFFD3ECF8),
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/images/back.png', width: 23, height: 23),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "แชท",
          style: TextStyle(
            color: darkBlue,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titleSpacing: -7,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: UnconstrainedBox(
              child: GestureDetector(
                onTap: controller.endConversation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE082),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    "จบการสนทนา",
                    style: TextStyle(
                      color: Color(0xFF6C6C6C),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Today",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = controller.messages[index];
                  final isMe = msg['isMe'];
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: isMe
                              ? const Radius.circular(20)
                              : Radius.circular(0),
                          bottomRight: isMe
                              ? Radius.circular(0)
                              : const Radius.circular(20),
                        ),
                      ),
                      child: Text(
                        msg['text'],
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 15, right: 10),
                    child: Icon(
                      Icons.sentiment_satisfied_alt,
                      color: Colors.grey,
                      size: 26,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller.textController,
                      decoration: const InputDecoration(
                        hintText: 'ส่งข้อความ.......',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(top: 4),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.sendMessage,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Icon(
                          Icons.send,
                          color: Colors.grey[700],
                          size: 28,
                        ),
                      ),
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
}

// ---------------------------------------------------------
// 6. หน้าสรุปการสนทนา (ConversationSummaryPage) - [เพิ่มระบบ Block]
// ---------------------------------------------------------
class ConversationSummaryController extends GetxController {
  final RxBool isFollowed = false.obs;
  final RxBool isBlocked = false.obs;
  final RxInt currentRating = 3.obs;

  void showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFFC3F3FF), // สีพื้นหลังฟ้าอ่อนแบบในรูป
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            height: 220, // กำหนดความสูงให้พอดี
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "คุณต้องการที่จะบล็อกใช่หรือไม่",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF537895), // สีน้ำเงินเข้มอมเทา
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ปุ่ม ยืนยัน
                    GestureDetector(
                      onTap: () {
                        Get.back();
                        isBlocked.value = true;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8AD4F5), // สีฟ้าเข้มขึ้น
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "ยืนยัน",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // ปุ่ม ยกเลิก
                    GestureDetector(
                      onTap: () {
                        Get.back(); // ปิด Pop-up เฉยๆ
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8AD4F5), // สีฟ้าเข้มขึ้น
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "ยกเลิก",
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
        );
      },
    );
  }
}

class ConversationSummaryPage extends StatelessWidget {
  ConversationSummaryPage({super.key});

  final ConversationSummaryController controller =
      Get.isRegistered<ConversationSummaryController>()
          ? Get.find<ConversationSummaryController>()
          : Get.put(ConversationSummaryController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 50),
            const Text(
              "Jellyfish",
              style: TextStyle(
                color: Color(0xFF4489D7),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // รูป Profile
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: Colors.white,
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1548681528-6a5c45b66b42?auto=format&fit=crop&w=600&q=80',
                  ),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // -----------------------------------------------------
            // ส่วนปุ่ม ติดตาม / บล็อก (จะแสดงก็ต่อเมื่อ ยังไม่บล็อก)
            // -----------------------------------------------------
            if (!controller.isBlocked.value) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // [1] ปุ่มติดตาม
                  GestureDetector(
                    onTap: () {
                      controller.isFollowed.value = !controller.isFollowed.value;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: controller.isFollowed.value
                            ? const Color(0xFFE0E0E0)
                            : const Color(0xFFD3ECF8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: controller.isFollowed.value
                            ? [
                                // [แก้ตรงนี้ 1] ใส่เงาสำหรับปุ่มสีเทา (ติดตามแล้ว)
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    0.4,
                                  ), // เงาสีดำจางๆ
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4489D7,
                                  ).withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Text(
                        controller.isFollowed.value ? "ติดตามแล้ว" : "ติดตาม",
                        style: TextStyle(
                          color: controller.isFollowed.value
                              ? Colors.grey[600]
                              : const Color(0xFF4489D7),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // [2] ปุ่มบล็อก (กดแล้วเด้ง Pop-up)
                  GestureDetector(
                    onTap: () => controller.showBlockDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        "บล็อก",
                        style: TextStyle(
                          color: Color(0xFF4489D7),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30), // ระยะห่างถ้าปุ่มยังอยู่
            ] else ...[
              // ถ้าบล็อกแล้ว อาจจะเว้นว่างไว้นิดนึง หรือใส่ข้อความบอกก็ได้
              const SizedBox(height: 50),
            ],

            // -----------------------------------------------------
            // ส่วนดาว (แสดงตลอด)
            // -----------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    controller.currentRating.value = index + 1;
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.star_rounded,
                      size: 55,
                      color: index < controller.currentRating.value
                          ? const Color(0xFFFFE082)
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                );
              }),
            ),

            const Spacer(),

            // ปุ่ม บันทึก (แสดงตลอด)
            GestureDetector(
              onTap: () {
                Get.offAll(() => const ChatSelectionPage());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE082),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  "บันทึก",
                  style: TextStyle(
                    color: Color(0xFF6C6C6C),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 300),
          ],
        ),
      ),
    ));
  }
}

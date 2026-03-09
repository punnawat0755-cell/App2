import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/setting/view/setting_view.dart';
import 'package:get/get.dart';

import 'halfcirclebutton.dart';
import 'pausechat.dart';

class ChatSelectionController extends GetxController {
  void goToStartChat() {
    Get.to(() => PauseChatPage());
  }

  void goToCounseling() {}
}

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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 35,
      child: GestureDetector(
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
    );
  }
}

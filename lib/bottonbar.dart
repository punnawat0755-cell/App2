import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/chat/view/chat_view.dart';
import 'package:flutter_application_1/module/chat/view/chatselectionpage.dart';
import 'package:flutter_application_1/module/encouragement/view/encouragement_view.dart';
import 'package:flutter_application_1/module/feed/view/feed_view.dart';
import 'package:flutter_application_1/module/home/view/home_view.dart';
import 'package:flutter_application_1/module/login/view/login2_view.dart';
import 'package:flutter_application_1/module/login/view/login_view.dart';
import 'package:flutter_application_1/module/login/view/logo_view.dart';
import 'package:flutter_application_1/module/login/view/singup_view.dart';
import 'package:flutter_application_1/module/pet/view/pet_view.dart';
import 'package:flutter_application_1/module/profile/view/profile_view.dart';
import 'package:flutter_application_1/module/reset/view/newpassword_view.dart';
import 'package:flutter_application_1/module/reset/view/reset_view.dart';
import 'package:flutter_application_1/module/reset/view/resetsent_view.dart';
import 'package:flutter_application_1/module/setting/view/edit_view.dart';
import 'package:flutter_application_1/module/setting/view/favorites_view.dart';
import 'package:flutter_application_1/module/setting/view/setting_view.dart';
import 'package:flutter_application_1/module/test/view/coin_view.dart';
import 'package:flutter_application_1/module/test/view/moodtest_view.dart';
import 'package:flutter_application_1/module/test/view/test_view.dart';
import 'package:get/get.dart';

class BottomNavController extends GetxController {
  final RxInt pageIndex = 0.obs;
  final GlobalKey<CurvedNavigationBarState> bottomNavigationKey = GlobalKey();

  final List<Widget> pages = [
    // EditProfilePage(),
    // SplashScreenpage(),
    // Signup(),
    // LoginPagetwo(),
    // QuizScreen(),
    // CoinRewardScreen(),
    // MoodTestScreen(),
    ResetPasswordPage(),
    ResetSentPage(),
    NewPasswordPage(),
    HomePage(),
    // Encouragement(),
    // FavoritesPage(),
    FeedPage(),
    ChatSelectionPage(),
    PetPage(),
    ProfilePage(),
    // SettingPage(),
  ];

  void changePage(int index) {
    pageIndex.value = index;
  }
}

class BottomNavBar extends StatelessWidget {
  BottomNavBar({super.key});

  final BottomNavController controller = Get.put(BottomNavController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Obx(() => controller.pages[controller.pageIndex.value]),
      bottomNavigationBar: CurvedNavigationBar(
        key: controller.bottomNavigationKey,
        index: 0,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Color.fromARGB(255, 244, 244, 244)),
          Icon(
            Icons.newspaper,
            size: 30,
            color: Color.fromARGB(255, 244, 244, 244),
          ),
          Icon(Icons.chat, size: 30, color: Color.fromARGB(255, 244, 244, 244)),
          Icon(Icons.pets, size: 30, color: Color.fromARGB(255, 244, 244, 244)),
          Icon(
            Icons.person,
            size: 30,
            color: Color.fromARGB(255, 244, 244, 244),
          ),
        ],
        color: const Color(0xFF5CD9FF),
        buttonBackgroundColor: const Color(0xFF5CD9FF),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: controller.changePage,
        letIndexChange: (index) => true,
      ),
    );
  }
}

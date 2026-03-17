import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/chat_user/bindings/chat_binding.dart';
import 'package:flutter_application_1/features/chat_user/models/pausechat.dart';
import 'package:flutter_application_1/features/chat_user/services/chat_user_service.dart';
import 'package:flutter_application_1/features/home/service/daily_mood_status_service.dart';
import 'package:flutter_application_1/module/chat/view/chat_view.dart';
import 'package:flutter_application_1/module/feed/view/feed_view.dart';
import 'package:flutter_application_1/module/home/view/home_view.dart';
import 'package:flutter_application_1/module/pet/view/pet_view.dart';
import 'package:flutter_application_1/module/profile/view/profile_view.dart';
import 'package:flutter_application_1/rolelogic/view/widget/rolelogic_view.dart';
import 'package:get/get.dart';

import 'features/home/view/daily_mood_page.dart';

class BottomNavController extends GetxController {
  final RxInt pageIndex = 0.obs;
  final GlobalKey<CurvedNavigationBarState> bottomNavigationKey = GlobalKey();

  final List<Widget> pages = const [
    HomePage(),
    FeedPage(),
    ChatSelectionPage(),
    PetPage(),
    ProfilePage(),
  ];

  void changePage(int index) {
    pageIndex.value = index;
  }
}

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with WidgetsBindingObserver {
  late final BottomNavController controller;

  bool _checkingPausedChat = false;
  bool _runningEntryFlow = false;
  bool _checkingRoleMode = false;
  bool _roleSelectionPageOpen = false;
  bool _checkingDailyMood = false;
  bool _dailyMoodPageOpen = false;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<BottomNavController>()
        ? Get.find<BottomNavController>()
        : Get.put(BottomNavController());

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openRequiredDailyFlowIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _openRequiredDailyFlowIfNeeded();
    }
  }

  Future<void> _openPausedChatIfNeeded() async {
    if (_checkingPausedChat) {
      return;
    }

    _checkingPausedChat = true;
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user == null) {
        return;
      }

      UserChatBinding().dependencies();
      final chatService = Get.find<ChatUserService>();
      final session = await chatService.getActiveRandomChatSession(user.uid);

      if (!mounted || session == null) {
        return;
      }

      await Get.to(
        () => PauseChatPage(
          currentUserId: user.uid,
          initialSession: session,
        ),
        binding: UserChatBinding(),
      );
    } finally {
      _checkingPausedChat = false;
    }
  }

  Future<void> _openDailyMoodIfNeeded() async {
    if (!mounted || _checkingDailyMood || _dailyMoodPageOpen) {
      return;
    }

    _checkingDailyMood = true;
    try {
      final answeredToday = await DailyMoodStatusService.hasAnsweredToday();
      if (!mounted || answeredToday) {
        return;
      }

      _dailyMoodPageOpen = true;
      final message = await Get.to<String>(() => const DailyMoodPage());
      _dailyMoodPageOpen = false;

      if (!mounted || message == null || message.isEmpty) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      _checkingDailyMood = false;
      _dailyMoodPageOpen = false;
    }
  }

  Future<void> _openRoleSelectionIfNeeded() async {
    if (!mounted || _checkingRoleMode || _roleSelectionPageOpen) {
      return;
    }

    _checkingRoleMode = true;
    try {
      _roleSelectionPageOpen = true;
      final message = await Get.to<String>(() => const RoleSelectionPage());
      _roleSelectionPageOpen = false;

      if (!mounted || message == null || message.isEmpty) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      _checkingRoleMode = false;
      _roleSelectionPageOpen = false;
    }
  }

  Future<void> _openRequiredDailyFlowIfNeeded() async {
    if (!mounted || _runningEntryFlow) {
      return;
    }

    final currentRoute = ModalRoute.of(context);
    if (currentRoute != null && !currentRoute.isCurrent) {
      return;
    }

    _runningEntryFlow = true;
    try {
      await _openRoleSelectionIfNeeded();
      if (!mounted) {
        return;
      }

      await _openDailyMoodIfNeeded();
    } finally {
      _runningEntryFlow = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Obx(() => controller.pages[controller.pageIndex.value]),
      bottomNavigationBar: CurvedNavigationBar(
        key: controller.bottomNavigationKey,
        index: controller.pageIndex.value,
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
        onTap: (index) async {
          controller.changePage(index);

          if (index == 2) {
            await _openPausedChatIfNeeded();
          }
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}

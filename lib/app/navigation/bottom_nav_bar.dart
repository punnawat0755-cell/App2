import 'dart:async';

import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/core/services/firebase_chat_identity_service.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/core/services/entry_flow_guard.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:flutter_application_1/features/feed/view/feed_view.dart';
import 'package:flutter_application_1/features/home/service/daily_mood_status_service.dart';
import 'package:flutter_application_1/features/home/service/user_mode_status_service.dart';
import 'package:flutter_application_1/features/home/view/home_page.dart';
import 'package:flutter_application_1/features/home/view/daily_mood_page.dart';
import 'package:flutter_application_1/features/home/view/encouragement_page.dart';
import 'package:flutter_application_1/features/chat/view/chat_view.dart';
import 'package:flutter_application_1/features/pet/view/pet_view.dart';
import 'package:flutter_application_1/features/login/view/login_page.dart';
import 'package:flutter_application_1/features/profile/controller/profile_avatar_controller.dart';
import 'package:flutter_application_1/features/profile/view/profile_view.dart';
import 'package:flutter_application_1/features/chat_user/bindings/chat_binding.dart';
import 'package:flutter_application_1/features/chat_user/services/chat_user_service.dart';
import 'package:flutter_application_1/features/chat_user/view/pause_chat_page.dart';
import 'package:flutter_application_1/features/role_logic/view/pages/role_selection_page.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with WidgetsBindingObserver {
  static const bool _enableRoleSelectionFlow = true;
  int _page = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  bool _checkingPausedChat = false;
  bool _runningEntryFlow = false;
  bool _checkingRoleMode = false;
  bool _roleSelectionPageOpen = false;
  bool _checkingDailyMood = false;
  bool _dailyMoodPageOpen = false;
  bool _allowHomePeriodPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _warmUpPageDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _openRequiredDailyFlowIfNeeded();
    });
  }

  void _warmUpPageDependencies() {
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }
    if (!Get.isRegistered<ProfileAvatarController>()) {
      Get.put(ProfileAvatarController());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !EntryFlowGuard.shouldIgnoreResume) {
      unawaited(_openRequiredDailyFlowIfNeeded());
    }
  }

  Future<bool> _ensureAuthenticatedOrRedirect() async {
    if (supabase.auth.currentUser != null) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    await Get.offAll<void>(() => const LoginPage());
    return false;
  }

  Future<void> _openPausedChatIfNeeded() async {
    final isAuthenticated = await _ensureAuthenticatedOrRedirect();
    if (!isAuthenticated || _checkingPausedChat) {
      return;
    }

    _checkingPausedChat = true;
    final user = await FirebaseChatIdentityService.ensureSignedIn();
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
      if (mounted) {
        _checkingPausedChat = false;
      }
    }
  }

  Future<bool> _openDailyMoodIfNeeded() async {
    final isAuthenticated = await _ensureAuthenticatedOrRedirect();
    if (!isAuthenticated ||
        !mounted ||
        _checkingDailyMood ||
        _dailyMoodPageOpen) {
      return false;
    }

    _checkingDailyMood = true;
    try {
      final answeredToday = await DailyMoodStatusService.hasAnsweredToday();
      if (!mounted || answeredToday) {
        return true;
      }

      _dailyMoodPageOpen = true;
      final message = await Get.to<String>(() => const DailyMoodPage());
      _dailyMoodPageOpen = false;

      if (!mounted) {
        return false;
      }

      if (message == DailyMoodPage.openEncouragementResult) {
        await Get.to<void>(() => const EncouragementPage());
        return false;
      }

      if (message == null || message.isEmpty) {
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return true;
    } finally {
      _checkingDailyMood = false;
      _dailyMoodPageOpen = false;
    }
  }

  Future<void> _openRoleSelectionIfNeeded() async {
    if (!_enableRoleSelectionFlow) {
      return;
    }

    final isAuthenticated = await _ensureAuthenticatedOrRedirect();
    if (!isAuthenticated ||
        !mounted ||
        _checkingRoleMode ||
        _roleSelectionPageOpen) {
      return;
    }

    _checkingRoleMode = true;
    try {
      final hasSelectedModeToday =
          await UserModeStatusService.hasSelectedModeToday();
      if (!mounted || hasSelectedModeToday) {
        return;
      }

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
    final isAuthenticated = await _ensureAuthenticatedOrRedirect();
    if (!isAuthenticated || !mounted || _runningEntryFlow) {
      return;
    }

    _runningEntryFlow = true;
    if (_allowHomePeriodPrompt && mounted) {
      setState(() => _allowHomePeriodPrompt = false);
    }
    try {
      final shouldContinueToRoleSelection = await _openDailyMoodIfNeeded();
      if (!mounted || !shouldContinueToRoleSelection) {
        return;
      }

      await _openRoleSelectionIfNeeded();
    } finally {
      _runningEntryFlow = false;
      if (mounted && !_allowHomePeriodPrompt) {
        setState(() => _allowHomePeriodPrompt = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _page,
        children: [
          HomePage(
            allowPeriodPrompt: _page == 0 && _allowHomePeriodPrompt,
          ),
          const FeedPage(),
          const ChatSelectionPage(),
          const PetPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _page,
        height: scale.rs(60, min: 54, max: 60),
        items: <Widget>[
          Icon(
            Icons.home,
            size: scale.rs(30, min: 26, max: 30),
            color: const Color.fromARGB(255, 244, 244, 244),
          ),
          Icon(
            Icons.newspaper,
            size: scale.rs(30, min: 26, max: 30),
            color: const Color.fromARGB(255, 244, 244, 244),
          ),
          Icon(
            Icons.chat,
            size: scale.rs(30, min: 26, max: 30),
            color: const Color.fromARGB(255, 244, 244, 244),
          ),
          Icon(
            Icons.pets,
            size: scale.rs(30, min: 26, max: 30),
            color: const Color.fromARGB(255, 244, 244, 244),
          ),
          Icon(
            Icons.person,
            size: scale.rs(30, min: 26, max: 30),
            color: const Color.fromARGB(255, 244, 244, 244),
          ),
        ],
        color: const Color(0xFF5CD9FF),
        buttonBackgroundColor: const Color(0xFF5CD9FF),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) async {
          setState(() {
            _page = index;
          });

          if (index == 2) {
            await _openPausedChatIfNeeded();
          }
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}

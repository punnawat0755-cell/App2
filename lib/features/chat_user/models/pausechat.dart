import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_application_1/bottom_bar.dart';
import 'package:flutter_application_1/features/chat/view/chat_view.dart';
import 'package:flutter_application_1/features/chat_user/bindings/chat_binding.dart';
import 'package:flutter_application_1/features/chat_user/services/chat_user_service.dart';
import 'package:flutter_application_1/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class PauseChatPage extends StatefulWidget {
  const PauseChatPage({
    super.key,
    required this.currentUserId,
    this.initialSession,
  });

  final String currentUserId;
  final ActiveRandomChatSession? initialSession;

  @override
  State<PauseChatPage> createState() => _PauseChatPageState();
}

class _PauseChatPageState extends State<PauseChatPage>
    with SingleTickerProviderStateMixin {
  static const Color _primaryBlue = Color(0xFF4A89D8);
  static const Color _innerPink = Color(0xFFF3BDBD);

  late final AnimationController _animationController;
  late final ChatUserService _chatService;

  bool _hasNavigated = false;
  bool _isNameLoading = true;
  String _displayName = 'ผู้ใช้';

  void _goHome() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    Get.offAll(() => const BottomNavBar());
  }

  @override
  void initState() {
    super.initState();
    _chatService = Get.isRegistered<ChatUserService>()
        ? Get.find<ChatUserService>()
        : Get.put(ChatUserService());
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _loadDisplayName();
    _restoreChatSession();
  }

  Future<void> _loadDisplayName() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _displayName = 'ผู้ใช้';
        _isNameLoading = false;
      });
      return;
    }

    try {
      final row = await supabase
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();

      final username = row?['username']?.toString().trim();
      if (!mounted) return;
      setState(() {
        _displayName =
            username?.isNotEmpty == true ? username! : _readNameFromAuth(user);
        _isNameLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load display name for pause chat: $e');
      if (!mounted) return;
      setState(() {
        _displayName = _readNameFromAuth(user);
        _isNameLoading = false;
      });
    }
  }

  String _readNameFromAuth(sb.User user) {
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final candidates = [
      metadata['username'],
      metadata['name'],
      metadata['full_name'],
      user.email?.split('@').first,
    ];

    for (final value in candidates) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    return 'ผู้ใช้';
  }

  Future<void> _restoreChatSession() async {
    try {
      final session = widget.initialSession ??
          await _chatService.getActiveRandomChatSession(widget.currentUserId);

      if (session == null) {
        if (!mounted) return;
        Get.snackbar(
          'ไม่พบบทสนทนา',
          'บทสนทนานี้อาจถูกจบไปแล้ว',
          snackPosition: SnackPosition.TOP,
        );
        _goHome();
        return;
      }

      await Future.wait([
        _chatService.preloadChatHistory(session.chatId),
        Future<void>.delayed(const Duration(seconds: 3)),
      ]);

      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;

      Get.off(
        () => ChatPage(
          chatId: session.chatId,
          currentUserId: widget.currentUserId,
          role: session.role,
        ),
        binding: UserChatBinding(),
      );
    } catch (e) {
      debugPrint('Failed to restore chat session: $e');
      if (!mounted) return;
      Get.snackbar(
        'โหลดไม่สำเร็จ',
        'ไม่สามารถโหลดบทสนทนาเดิมได้',
        snackPosition: SnackPosition.TOP,
      );
      _goHome();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goHome();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Image.asset(
                                'assets/images/back.png',
                                width: 25,
                                height: 25,
                              ),
                              onPressed: _goHome,
                            ),
                            const Expanded(
                              child: Text(
                                'มีคนกำลังรอแชทกับคุณ',
                                style: TextStyle(
                                  color: Color(0xFF4489D7),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        _isNameLoading ? '...' : _displayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: SizedBox(
                          width: 350,
                          height: 350,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _buildOneWayRipple(0.0),
                              _buildOneWayRipple(0.33),
                              _buildOneWayRipple(0.66),
                              Container(
                                width: 210,
                                height: 210,
                                decoration: BoxDecoration(
                                  color: _innerPink,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 170,
                                    height: 170,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFFFF5F5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.08),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/person.png',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.forum_rounded,
                                          size: 82,
                                          color: _primaryBlue,
                                        ),
                                      ),
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOneWayRipple(double startDelay) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final rawT = (_animationController.value + startDelay) % 1.0;
        final t = Curves.easeOut.transform(rawT);
        final currentSize = 210 + (140 * t);
        final opacity = 0.5 * (1.0 - rawT);

        return Container(
          width: currentSize,
          height: currentSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF3BDBD).withValues(alpha: opacity),
            border: Border.all(
              color: Colors.white.withValues(alpha: opacity * 0.8),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }
}

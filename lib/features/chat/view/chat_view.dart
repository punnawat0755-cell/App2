import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/profile/controller/profile_avatar_controller.dart';
import 'package:get/get.dart';

import 'package:flutter_application_1/bottom_bar.dart';
import 'package:flutter_application_1/features/chat/view/chat_confirm_dialog.dart';
import 'package:flutter_application_1/features/chat_user/bindings/chat_binding.dart';
import 'package:flutter_application_1/features/chat/view/conversation_summary_screen.dart';
import 'package:flutter_application_1/features/chat_user/models/pausechat.dart';
import 'package:flutter_application_1/features/chat_user/services/chat_user_service.dart';
import 'package:flutter_application_1/features/login/view/login.dart';

Color withAlpha(Color color, double opacity) {
  final alpha = (opacity.clamp(0.0, 1.0) * 255).round();
  return color.withAlpha(alpha);
}

class ChatSelectionController extends GetxController {
  void goToStartChat() {
    unawaited(_openChatEntry(MatchRole.seeker));
  }

  void goToCounseling() {
    unawaited(_openChatEntry(MatchRole.listener));
  }

  Future<void> _openChatEntry(MatchRole role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAll(() => const LoginPage());
      return;
    }

    UserChatBinding().dependencies();
    final chatService = Get.find<ChatUserService>();
    final activeSession =
        await chatService.getActiveRandomChatSession(user.uid);

    if (activeSession != null) {
      Get.to(
        () => PauseChatPage(
          currentUserId: user.uid,
          initialSession: activeSession,
        ),
        binding: UserChatBinding(),
      );
      return;
    }

    Get.to(
      () => WaitingChatPage(
        currentUserId: user.uid,
        role: role,
      ),
      binding: UserChatBinding(),
    );
  }
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
    final ProfileAvatarController avatarController =
        Get.isRegistered<ProfileAvatarController>()
            ? Get.find<ProfileAvatarController>()
            : Get.put(ProfileAvatarController());

    return Positioned(
      top: 20,
      right: 35,
      child: Obx(
        () => Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            image: DecorationImage(
              image: avatarController.avatarImageProvider,
              fit: BoxFit.cover,
            ),
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
                color: withAlpha(Colors.black, 0.05),
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
                        color: withAlpha(Colors.white, 0.5),
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

class WaitingChatPage extends StatefulWidget {
  final String currentUserId;
  final MatchRole role;

  const WaitingChatPage({
    super.key,
    required this.currentUserId,
    required this.role,
  });

  @override
  State<WaitingChatPage> createState() => _WaitingChatPageState();
}

class _WaitingChatPageState extends State<WaitingChatPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final ChatUserService _chatService;
  StreamSubscription<String?>? _matchSub;
  Timer? _retryTimer;
  bool _isMatching = false;
  bool _isLeavingQueue = false;

  bool _navigatingToChat = false;
  String _statusText = 'กำลังสุ่มคู่สนทนาอย่างต่อเนื่อง...';

  bool get _isListenerMode => widget.role == MatchRole.listener;

  Color get _waitingAccent =>
      _isListenerMode ? const Color(0xFFFDE6A8) : const Color(0xFFAEDEF4);

  Color get _waitingTextColor =>
      _isListenerMode ? const Color(0xFF8D6E63) : const Color(0xFF4489D7);

  String get _waitingImagePath =>
      _isListenerMode ? 'assets/images/fine.png' : 'assets/images/sad.png';

  String get _waitingHeadline =>
      _isListenerMode ? 'รอผู้ต้องการพูดคุยสักครู่' : 'รอคู่สนทนาสักครู่';

  String get _waitingSubheadline => _isListenerMode
      ? 'ระบบกำลังจับคู่คนที่ต้องการคำปรึกษาให้คุณ'
      : _statusText;

  @override
  void initState() {
    super.initState();
    _chatService = Get.find<ChatUserService>();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _startMatching();
  }

  Future<void> _startMatching() async {
    await _chatService.enterRandomQueue(
      widget.currentUserId,
      role: widget.role,
    );

    _matchSub = _chatService.watchMatchedChatId(widget.currentUserId).listen(
      (chatId) {
        if (chatId == null || _navigatingToChat || !mounted) {
          return;
        }

        _navigatingToChat = true;
        Get.off(
          () => ChatPage(
            chatId: chatId,
            currentUserId: widget.currentUserId,
            role: widget
                .role, // 🟢 [อัปเดต] 2. ส่ง Role ของเราไปให้หน้าแชทรับทราบด้วย
          ),
          binding: UserChatBinding(),
        );
      },
      onError: (e) {
        debugPrint('watchMatchedChatId error: $e');
        if (mounted) {
          setState(() {
            _statusText = 'ไม่สามารถเข้าถึงข้อมูลแชทได้';
          });
        }
      },
    );

    await _attemptMatchCycle();
    _retryTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _attemptMatchCycle();
    });
  }

  Future<void> _attemptMatchCycle() async {
    if (_navigatingToChat || _isMatching) {
      return;
    }

    _isMatching = true;
    try {
      await _chatService.tryMatchWithWaitingUser(
        widget.currentUserId,
        role: widget.role,
      );
      if (mounted && _statusText != 'กำลังสุ่มคู่สนทนาอย่างต่อเนื่อง...') {
        setState(() {
          _statusText = 'กำลังสุ่มคู่สนทนาอย่างต่อเนื่อง...';
        });
      }
    } catch (e) {
      debugPrint('Random match failed: $e');
      if (mounted && _statusText != 'กำลังพยายามเชื่อมต่อใหม่...') {
        setState(() {
          _statusText = 'กำลังพยายามเชื่อมต่อใหม่...';
        });
      }
    } finally {
      _isMatching = false;
    }
  }

  Future<void> _leaveQueueAndBack() async {
    if (_isLeavingQueue) return;
    _isLeavingQueue = true;

    // หยุดวงจรสุ่มทันทีเพื่อกันเด้งกลับเข้าคิวระหว่างกำลังออก
    _retryTimer?.cancel();
    _matchSub?.cancel();
    _navigatingToChat = true;

    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (mounted) {
      Get.back();
    }

    unawaited(
      _chatService.leaveRandomQueue(widget.currentUserId).then((_) {
        debugPrint('Left queue successfully');
      }).catchError((e) {
        debugPrint('Error leaving queue: $e');
      }),
    );
  }

  void _showExitDialog() {
    showChatConfirmDialog(
      title: 'คุณต้องการที่จะออกจากการจับคู่\nใช่หรือไม่',
      barrierDismissible: false,
      onConfirm: _leaveQueueAndBack,
      onCancel: Get.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _matchSub?.cancel();
    _retryTimer?.cancel();

    if (!_navigatingToChat) {
      unawaited(_chatService.leaveRandomQueue(widget.currentUserId));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 2,
          leading: GestureDetector(
            onTap: _showExitDialog,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Image.asset(
                'assets/images/back.png',
                width: 25,
                height: 25,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _waitingHeadline,
                style: TextStyle(
                  color: _waitingTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _waitingSubheadline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _waitingTextColor.withValues(alpha: 0.78),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
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
                        color: _waitingAccent,
                        boxShadow: [
                          BoxShadow(
                            color: withAlpha(Colors.black, 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: _isListenerMode ? 10 : 30,
                            left: _isListenerMode ? 8 : 0,
                            right: _isListenerMode ? 8 : 0,
                            bottom: _isListenerMode ? 10 : 0,
                          ),
                          child: Image.asset(
                            _waitingImagePath,
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
      animation: _controller,
      builder: (context, child) {
        final t = (_controller.value + startDelay) % 1.0;
        final currentSize = 240 + (180 * t);
        final opacity = 0.4 * (1.0 - t);
        return Container(
          width: currentSize,
          height: currentSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: withAlpha(_waitingAccent, opacity),
            border: Border.all(
              color: withAlpha(Colors.white, opacity),
              width: 1,
            ),
          ),
        );
      },
    );
  }
}

class ChatPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final MatchRole role; // 🟢 [อัปเดต] 3. รับค่า role

  const ChatPage({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.role, // 🟢 [อัปเดต]
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();

  late final ChatUserService _chatService;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _chatDocSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _queueSub;

  String _recipientUserId = '';
  bool _endingConversation = false;
  bool _exitingByRemoteEnd = false;
  bool _sendingMessage = false;
  bool _isRecipientInChat = true;

  // feedback
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatService = Get.find<ChatUserService>();
    _resolveRecipientUserId();
    _watchChatEndedByPeer();
    unawaited(_setMyChatPresence(true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_setMyChatPresence(true));
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_setMyChatPresence(false));
    }
  }

  Future<void> _setMyChatPresence(bool isInChat) async {
    try {
      await FirebaseFirestore.instance
          .collection('Chats')
          .doc(widget.chatId)
          .set({
        'chatPresence': {
          widget.currentUserId: {
            'inChat': isInChat,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('chat presence update failed: $e');
    }
  }

  void _syncRecipientPresence(Map<String, dynamic>? data) {
    final users =
        (data?['users'] as List<dynamic>? ?? []).whereType<String>().toList();
    final recipient = _recipientUserId.isNotEmpty
        ? _recipientUserId
        : users.firstWhere(
            (id) => id != widget.currentUserId,
            orElse: () => '',
          );

    final rawPresence = data?['chatPresence'];
    final presence = rawPresence is Map
        ? Map<String, dynamic>.from(rawPresence)
        : const <String, dynamic>{};
    final rawRecipientPresence = recipient.isEmpty ? null : presence[recipient];
    final recipientPresence = rawRecipientPresence is Map
        ? Map<String, dynamic>.from(rawRecipientPresence)
        : const <String, dynamic>{};
    final isRecipientInChat =
        recipient.isEmpty ? true : recipientPresence['inChat'] == true;

    if (!mounted) return;
    if (recipient != _recipientUserId ||
        isRecipientInChat != _isRecipientInChat) {
      setState(() {
        if (recipient.isNotEmpty) {
          _recipientUserId = recipient;
        }
        _isRecipientInChat = isRecipientInChat;
      });
    }
  }

  void _watchChatEndedByPeer() {
    _chatDocSub = FirebaseFirestore.instance
        .collection('Chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((snap) {
      if (!mounted || _endingConversation || _exitingByRemoteEnd) return;

      final data = snap.data();
      _syncRecipientPresence(data);
      final randomState = (data?['randomState'] ?? '') as String;
      if (!snap.exists || randomState == 'ended') {
        _exitByPeerEnd();
      }
    });

    _queueSub = FirebaseFirestore.instance
        .collection('RandomQueue')
        .doc(widget.currentUserId)
        .snapshots()
        .listen((snap) {
      if (!mounted || _endingConversation || _exitingByRemoteEnd) return;

      final data = snap.data();
      final status = (data?['status'] ?? '') as String;
      final chatId = data?['chatId'];
      final hasChatId = chatId is String && chatId.isNotEmpty;

      if (status == 'idle' && !hasChatId) {
        _exitByPeerEnd();
      }
    });
  }

  void _exitByPeerEnd() {
    if (!mounted || _exitingByRemoteEnd) return;
    unawaited(_setMyChatPresence(false));
    _chatDocSub?.cancel();
    _queueSub?.cancel();

    _exitingByRemoteEnd = true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('คู่สนทนาได้จบบทสนทนาแล้ว')),
    );

    if (mounted) {
      setState(() {
        _showFeedback = true;
      });
    }
  }

  Future<void> _resolveRecipientUserId() async {
    final chatDoc = await FirebaseFirestore.instance
        .collection('Chats')
        .doc(widget.chatId)
        .get();

    final users = (chatDoc.data()?['users'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();

    final recipient = users.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => '',
    );

    if (!mounted) return;

    setState(() {
      _recipientUserId = recipient;
    });
  }

  Future<void> _sendMessage() async {
    if (_sendingMessage || _textController.text.trim().isEmpty) return;

    setState(() => _sendingMessage = true);

    try {
      final result = await _chatService.sendMessage(
        widget.chatId,
        widget.currentUserId,
        _textController.text,
        _textController,
        _recipientUserId,
      );

      if (!mounted) return;

      if (result.status == SendMessageStatus.blocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ข้อความไม่สุภาพ ระบบบล็อกการส่งข้อความ')),
        );
      }

      setState(() {});
    } finally {
      if (mounted) {
        setState(() => _sendingMessage = false);
      }
    }
  }

  Future<void> _endConversation() async {
    if (_endingConversation) return;

    setState(() => _endingConversation = true);

    try {
      await _setMyChatPresence(false);
      await _chatService.endRandomChat(
        chatId: widget.chatId,
        endedByUserId: widget.currentUserId,
      );

      _chatDocSub?.cancel();
      _queueSub?.cancel();

      if (mounted) {
        setState(() {
          _showFeedback = true;
        });
      }
    } catch (e) {
      debugPrint('endRandomChat failed: $e');
      if (mounted) setState(() => _endingConversation = false);
    }
  }

  void _showEndConversationDialog() {
    if (_endingConversation) {
      return;
    }

    showChatConfirmDialog(
      title: 'คุณต้องการที่จะออกจากบทสนทนา\nใช่หรือไม่',
      onConfirm: () {
        Get.back();
        unawaited(_endConversation());
      },
    );
  }

  void _exitToPreMatchScreen() {
    unawaited(_setMyChatPresence(false));
    _chatDocSub?.cancel();
    _queueSub?.cancel();

    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Get.offAll(() => const ChatSelectionPage());
  }

  void _goHomeWithoutEndingConversation() {
    unawaited(_setMyChatPresence(false));
    _chatDocSub?.cancel();
    _queueSub?.cancel();
    Get.offAll(() => const BottomNavBar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_setMyChatPresence(false));
    _textController.dispose();
    _chatDocSub?.cancel();
    _queueSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showFeedback) {
      return ConversationSummaryScreen(
        chatId: widget.chatId,
        currentUserId: widget.currentUserId,
        recipientUserId: _recipientUserId,
        role: widget.role,
        onExit: _exitToPreMatchScreen,
      );
    }

    const Color darkBlue = Color(0xFF1565C0);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goHomeWithoutEndingConversation();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 80,
          backgroundColor: const Color(0xFFD3ECF8),
          elevation: 0,
          leading: IconButton(
            icon: Image.asset('assets/images/back.png', width: 23, height: 23),
            onPressed: _goHomeWithoutEndingConversation,
          ),
          title: const Text(
            'แชท',
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
                  onTap: _showEndConversationDialog,
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
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _endingConversation ? 'กำลังจบ...' : 'จบการสนทนา',
                      style: const TextStyle(
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
                'Today',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = [...(snapshot.data?.docs ?? const [])]
                    ..sort((a, b) {
                      final ad = a.data() as Map<String, dynamic>;
                      final bd = b.data() as Map<String, dynamic>;
                      final at = (ad['localTimestamp'] ?? ad['timestamp']);
                      final bt = (bd['localTimestamp'] ?? bd['timestamp']);
                      final aMs =
                          at is Timestamp ? at.millisecondsSinceEpoch : 0;
                      final bMs =
                          bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
                      return aMs.compareTo(bMs);
                    });
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'จับคู่สำเร็จแล้ว เริ่มพิมพ์ได้เลย',
                        style: TextStyle(color: Color(0xFF6D6D6D)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final text = (data['text'] ?? '') as String;
                      final senderId = (data['senderId'] ?? '') as String;
                      final isMe = senderId == widget.currentUserId;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                                  : Radius.zero,
                              bottomRight: isMe
                                  ? Radius.zero
                                  : const Radius.circular(20),
                            ),
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _recipientUserId.isNotEmpty && !_isRecipientInChat
                  ? const Padding(
                      key: ValueKey('recipient-paused'),
                      padding: EdgeInsets.fromLTRB(24, 4, 24, 10),
                      child: Text(
                        'คู่สนทนาพักการแชทสักครู่......',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('recipient-active'),
                      height: 10,
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
                        controller: _textController,
                        enabled: !_sendingMessage,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'ส่งข้อความ.......',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(top: 4),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _sendingMessage ? null : _sendMessage,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Icon(
                            Icons.send,
                            color: _sendingMessage
                                ? const Color(0xFF9E9E9E)
                                : Colors.grey[700],
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
      ),
    );
  }
}

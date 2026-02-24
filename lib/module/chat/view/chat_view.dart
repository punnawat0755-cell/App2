import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_application_1/chat/userchat/bindings/chat_binding.dart';
import 'package:flutter_application_1/chat/userchat/services/chat_user_service.dart';
import 'package:flutter_application_1/module/login/view/login.dart';

Color withAlpha(Color color, double opacity) {
  final alpha = (opacity.clamp(0.0, 1.0) * 255).round();
  return color.withAlpha(alpha);
}

class ChatSelectionController extends GetxController {
  void goToStartChat() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAll(() => const LoginPage());
      return;
    }
    Get.to(
      () => WaitingChatPage(
        currentUserId: user.uid,
        role: MatchRole.seeker,
      ),
      binding: UserChatBinding(),
    );
  }

  void goToCounseling() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAll(() => const LoginPage());
      return;
    }
    Get.to(
      () => WaitingChatPage(
        currentUserId: user.uid,
        role: MatchRole.listener,
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

    _matchSub =
        _chatService.watchMatchedChatId(widget.currentUserId).listen(
      (chatId) {
        if (chatId == null || _navigatingToChat || !mounted) {
          return;
        }

        _navigatingToChat = true;
        Get.off(
          () => ChatPage(
            chatId: chatId,
            currentUserId: widget.currentUserId,
            role: widget.role, // 🟢 [อัปเดต] 2. ส่ง Role ของเราไปให้หน้าแชทรับทราบด้วย
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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFC3F3FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'คุณต้องการออกจากการสุ่มคู่ใช่หรือไม่',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4489D7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _leaveQueueAndBack,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8AD4F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'ยืนยัน',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: Get.back,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8AD4F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
        backgroundColor: const Color(0xFFF0F9FF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
            onPressed: _showExitDialog,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.role == MatchRole.listener
                    ? 'กำลังรอผู้ต้องการพูดคุย...'
                    : _statusText,
                style: const TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 420,
                height: 420,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildOneWayRipple(0.0),
                    _buildOneWayRipple(0.33),
                    _buildOneWayRipple(0.66),
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFAEDEF4),
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
                          padding: const EdgeInsets.only(top: 28),
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
        final currentSize = 220 + (180 * t);
        final opacity = 0.38 * (1.0 - t);
        return Container(
          width: currentSize,
          height: currentSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: withAlpha(const Color(0xFFAEDEF4), opacity),
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

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _comentController = TextEditingController();

  late final ChatUserService _chatService;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _chatDocSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _queueSub;

  String _recipientUserId = '';
  bool _endingConversation = false;
  bool _exitingByRemoteEnd = false;

  // feedback
  bool _showFeedback = false;
  bool _sendingFeedback = false;
  int _ratng = 5;
  bool _isStared = false;
  int _sessionWordCount = 0;

  @override
  void initState() {
    super.initState();
    _chatService = Get.find<ChatUserService>();
    _resolveRecipientUserId();
    _watchChatEndedByPeer();
  }

  void _watchChatEndedByPeer() {
    _chatDocSub = FirebaseFirestore.instance
        .collection('Chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((snap) {
      if (!mounted || _endingConversation || _exitingByRemoteEnd) return;

      final data = snap.data();
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
    if (_textController.text.trim().isEmpty) return;

    await _chatService.sendMessage(
      widget.chatId,
      widget.currentUserId,
      _textController.text,
      _textController,
      _recipientUserId,
    );

    if (mounted) setState(() {});
  }

  int _calculateWordCount(List<DocumentSnapshot> docs) {
    int count = 0;
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final text = (data['text'] ?? '').toString();
      if (text.trim().isNotEmpty) {
        count += text.trim().split(RegExp(r'\s+')).length;
      }
    }
    return count;
  }

  Future<void> _endConversation() async {
    if (_endingConversation) return;

    setState(() => _endingConversation = true);

    try {
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

  Future<void> _submitFeedback() async {
    if (_sendingFeedback) return;

    setState(() => _sendingFeedback = true);

    try {
      // นับคำ
      final messagesSnap = await FirebaseFirestore.instance
          .collection('Chats')
          .doc(widget.chatId)
          .collection('messages')
          .get();

      _sessionWordCount = _calculateWordCount(messagesSnap.docs);

      // ดึง session id
      final chatMeta = await FirebaseFirestore.instance
          .collection('Chats')
          .doc(widget.chatId)
          .get();
      final sessionId =
          (chatMeta.data()?['sessionId'] as String?)?.trim().isNotEmpty == true
              ? (chatMeta.data()?['sessionId'] as String)
              : widget.chatId;

      String myRoleStr = widget.role == MatchRole.seeker ? 'seeker' : 'listener';
      String peerRoleStr = widget.role == MatchRole.seeker ? 'listener' : 'seeker';

      await _chatService.submitFeedback(
        sessionId: sessionId,
        chatId: widget.chatId,
        fromUserId: widget.currentUserId,
        toUserId: _recipientUserId,
        fromRole: myRoleStr,
        toRole: peerRoleStr,
        rating: _ratng,
        comment: _comentController.text.trim(),
        starred: _isStared,
        wordCount: _sessionWordCount,
      );

      if (!mounted) return;
      debugPrint('ส่งฟีดแบ็คสำเร็จผ่าน Firestore!');
      _exitToPreMatchScreen();
    } catch (e) {
      debugPrint("Failed to submit feedback: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingFeedback = false);
    }
  }

  void _exitToPreMatchScreen() {
    _chatDocSub?.cancel();
    _queueSub?.cancel();

    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Get.offAll(() => const ChatSelectionPage());
  }

  @override
  void dispose() {
    _textController.dispose();
    _comentController.dispose();
    _chatDocSub?.cancel();
    _queueSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showFeedback) {
      return _buildFeedbackScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFD3ECF8),
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: const Color(0xFFD3ECF8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF6D6D6D)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'แชท',
          style: TextStyle(
            color: Color(0xFF1D4F86),
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: UnconstrainedBox(
              child: GestureDetector(
                onTap: _endingConversation ? null : _endConversation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDE70),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 5,
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
                          horizontal: 16,
                          vertical: 12,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2DFE0),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft:
                                isMe ? const Radius.circular(20) : Radius.zero,
                            bottomRight:
                                isMe ? Radius.zero : const Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.black.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 15, right: 10),
                    child: Icon(
                      Icons.sentiment_satisfied_alt,
                      color: Color(0xFF6F6F6F),
                      size: 27,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'ส่งข้อความ.......',
                        hintStyle: TextStyle(color: Color(0xFF6F6F6F)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(top: 4),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: Transform.rotate(
                        angle: -0.5,
                        child: const Icon(
                          Icons.send,
                          color: Color(0xFF6F6F6F),
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

  Widget _buildFeedbackScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ให้คะแนนการสนทนา'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ขอบคุณสำหรับที่แชทกับเรา',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4489D7),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "โปรดให้คะแนนการสนทนา",
                style: TextStyle(fontSize: 18, color: Color(0xFF4489D7)),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < _ratng ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: () => setState(() => _ratng = index + 1),
                  ),
                ),
              ),
          
              TextButton(
                onPressed: _sendingFeedback ? null : _exitToPreMatchScreen,
                child: const Text('ข้าม'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _comentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'พิมพ์ความคิดเห็น (ถ้ามี)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _isStared,
                    onChanged: (v) => setState(() => _isStared = v ?? false),
                  ),
                  const Text('ปักหมุดบทสนทนานี้'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendingFeedback ? null : _submitFeedback,
                  child: Text(_sendingFeedback ? 'กำลังส่ง...' : 'ส่งฟีดแบ็ค'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/features/chat/data/mock/conversation_partner_mock.dart';
import 'package:get/get.dart';

import 'package:flutter_application_1/features/chat/view/chat_confirm_dialog.dart';
import 'package:flutter_application_1/features/chat_user/services/chat_user_service.dart';

class ConversationSummaryScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String recipientUserId;
  final MatchRole role;
  final VoidCallback onExit;

  const ConversationSummaryScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.recipientUserId,
    required this.role,
    required this.onExit,
  });

  @override
  State<ConversationSummaryScreen> createState() =>
      _ConversationSummaryScreenState();
}

class _ConversationSummaryScreenState extends State<ConversationSummaryScreen> {
  late final ChatUserService _chatService;

  bool _isFollowed = false;
  bool _isBlocked = false;
  int _rating = 3;
  bool _sendingFeedback = false;

  @override
  void initState() {
    super.initState();
    _chatService = Get.find<ChatUserService>();
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

  Future<void> _submitFeedback() async {
    if (_sendingFeedback) return;

    setState(() => _sendingFeedback = true);

    try {
      final messagesSnap = await FirebaseFirestore.instance
          .collection('Chats')
          .doc(widget.chatId)
          .collection('messages')
          .get();
      final sessionWordCount = _calculateWordCount(messagesSnap.docs);

      final chatMeta = await FirebaseFirestore.instance
          .collection('Chats')
          .doc(widget.chatId)
          .get();
      final sessionId =
          (chatMeta.data()?['sessionId'] as String?)?.trim().isNotEmpty == true
              ? (chatMeta.data()?['sessionId'] as String)
              : widget.chatId;

      final myRoleStr = widget.role == MatchRole.seeker ? 'seeker' : 'listener';
      final peerRoleStr =
          widget.role == MatchRole.seeker ? 'listener' : 'seeker';

      await _chatService.submitFeedback(
        sessionId: sessionId,
        chatId: widget.chatId,
        fromUserId: widget.currentUserId,
        toUserId: widget.recipientUserId,
        fromRole: myRoleStr,
        toRole: peerRoleStr,
        rating: _rating,
        comment: '',
        starred: _isFollowed,
        wordCount: sessionWordCount,
      );

      if (!mounted) return;
      widget.onExit();
    } catch (e) {
      debugPrint('Failed to submit feedback: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _sendingFeedback = false);
    }
  }

  void _showBlockDialog() {
    showChatConfirmDialog(
      title: 'คุณต้องการที่จะบล็อกใช่หรือไม่',
      onConfirm: () {
        Get.back();
        if (!mounted) return;
        setState(() {
          _isBlocked = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    final starSize = scale.rs(55, min: 44, max: 56);
    final avatarSize = scale.rs(150, min: 126, max: 154);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360 ? 14.0 : 24.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        conversationPartnerNameMock,
                        style: TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: scale.rf(28, min: 24, max: 28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: scale.rs(4, min: 3, max: 4),
                          ),
                          color: Colors.white,
                          image: const DecorationImage(
                            image: NetworkImage(
                              conversationPartnerAvatarUrlMock,
                            ),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (!_isBlocked) ...[
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 15,
                          runSpacing: 12,
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isFollowed = !_isFollowed),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 25,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _isFollowed
                                      ? const Color(0xFFE0E0E0)
                                      : const Color(0xFFD3ECF8),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: _isFollowed
                                      ? [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: const Color(0xFF4489D7)
                                                .withValues(alpha: 0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                ),
                                child: Text(
                                  _isFollowed ? 'ติดตามแล้ว' : 'ติดตาม',
                                  style: TextStyle(
                                    color: _isFollowed
                                        ? Colors.grey[600]
                                        : const Color(0xFF4489D7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: scale.rf(16, min: 14, max: 16.5),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _showBlockDialog,
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
                                      color:
                                          Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'บล็อก',
                                  style: TextStyle(
                                    color: Color(0xFF4489D7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ] else ...[
                        const SizedBox(height: 50),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () => setState(() => _rating = index + 1),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(
                                Icons.star_rounded,
                                size: starSize,
                                color: index < _rating
                                    ? const Color(0xFFFFE082)
                                    : const Color(0xFFE0E0E0),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _sendingFeedback ? null : _submitFeedback,
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
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            _sendingFeedback ? 'กำลังส่ง...' : 'บันทึก',
                            style: TextStyle(
                              color: Color(0xFF6C6C6C),
                              fontWeight: FontWeight.bold,
                              fontSize: scale.rf(16, min: 14, max: 16.5),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

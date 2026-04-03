import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BotChatController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[
    {
      'text': 'สวัสดีเราคือแชทบอทมีอะไรให้ช่วย\nหรืออยากระบายกับเราไหม',
      'isMe': false,
    },
  ].obs;

  void sendMessage() {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    messages.add({'text': text, 'isMe': true});
    textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void onReady() {
    super.onReady();
    _scrollToBottom();
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}

class BotChatPage extends StatelessWidget {
  const BotChatPage({super.key});

  final String controllerTag = 'bot-chat-page';

  void _closeChat() {
    if (Get.isRegistered<BotChatController>(tag: controllerTag)) {
      Get.delete<BotChatController>(tag: controllerTag);
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final BotChatController controller =
        Get.isRegistered<BotChatController>(tag: controllerTag)
        ? Get.find<BotChatController>(tag: controllerTag)
        : Get.put(BotChatController(), tag: controllerTag);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && Get.isRegistered<BotChatController>(tag: controllerTag)) {
          Get.delete<BotChatController>(tag: controllerTag);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 88,
          backgroundColor: const Color(0xFFD3ECF8),
          elevation: 0,
          leadingWidth: 39,
          leading: GestureDetector(
            onTap: _closeChat,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/images/back.png',
                  width: 26,
                  height: 26,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF6C6C6C),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          title: const Text(
            'Bot For You',
            style: TextStyle(
              color: Color(0xFF1C4D8D),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          titleSpacing: 4,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: _closeChat,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD972),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'จบการสนทนา',
                      style: TextStyle(
                        color: Color(0xFF8A6A1F),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final horizontalPadding = screenWidth < 360 ? 12.0 : 20.0;
              final inputHeight = screenWidth < 360 ? 48.0 : 56.0;

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        color: Color(0xFF7D7D7D),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Obx(
                      () => ListView.builder(
                        controller: controller.scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 4,
                        ),
                        itemCount: controller.messages.length,
                        itemBuilder: (context, index) {
                          final msg = controller.messages[index];
                          final isMe = msg['isMe'] as bool? ?? false;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    screenWidth *
                                    (screenWidth < 600 ? 0.7 : 0.5),
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFFCDEAF6)
                                    : const Color(0xFFE6E2E2),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 20),
                                ),
                              ),
                              child: Text(
                                msg['text'] as String? ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 16,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      10,
                      horizontalPadding,
                      24,
                    ),
                    child: Container(
                      height: inputHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDF2FB),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.black, width: 1.4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sentiment_satisfied_alt_rounded,
                            color: Colors.grey[600],
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: controller.textController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => controller.sendMessage(),
                              decoration: const InputDecoration(
                                hintText: 'ส่งข้อความ.......',
                                hintStyle: TextStyle(
                                  color: Color(0xFF7A7A7A),
                                  fontWeight: FontWeight.w600,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: controller.sendMessage,
                            child: Transform.rotate(
                              angle: -0.6,
                              child: Icon(
                                Icons.send_rounded,
                                color: Colors.grey[700],
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/module/chat/view/chatconfirmdialog.dart';
import 'package:flutter_application_1/module/chat/view/feedback_page.dart';

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

  // 💡 แก้ไขฟังก์ชันนี้: ให้ปิด Popup ก่อน แล้วค่อยเปลี่ยนหน้า
  void confirmEndConversation() {
    Get.back(); // ปิดหน้าต่าง Popup
    Get.to(() => FeedbackPage());
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        backgroundColor: const Color(0xFFD3ECF8),
        elevation: 0,
        leadingWidth: 40,
        leading: GestureDetector(
          // onTap: () => Get.off(() => const ChatSelectionPage()),
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/back.png',
                width: 25,
                height: 25,
              ),
            ),
          ),
        ),
        title: const Text(
          "แชท",
          style: TextStyle(
            color: Color(0xff1C4D8D),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titleSpacing: 5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: UnconstrainedBox(
              child: GestureDetector(
                onTap: () => _showEndConversationDialog(context),
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
                              : const Radius.circular(0),
                          bottomRight: isMe
                              ? const Radius.circular(0)
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

  // ==============================================================
  // 💡 เพิ่มฟังก์ชันสำหรับโชว์ Popup ยืนยัน (ออกแบบตามรูปเป๊ะๆ)
  // ==============================================================
  void _showEndConversationDialog(BuildContext context) {
    showChatConfirmDialog(
      title: "คุณต้องการที่จะออกจากบทสนทนา\nใช่หรือไม่",
      onConfirm: controller.confirmEndConversation,
    );
  }
}

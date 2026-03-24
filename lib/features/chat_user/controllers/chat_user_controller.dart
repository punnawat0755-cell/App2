import 'package:get/get.dart';
import 'package:flutter_application_1/features/chat_user/models/user_message.dart';
import 'package:flutter_application_1/features/chat_user/services/chat_user_service.dart';

class ChatUserController extends GetxController {
  ChatUserController({ChatUserService? chatUserService})
      : userChatService = chatUserService ?? Get.find<ChatUserService>();

  final ChatUserService userChatService;

  Stream<UserMessage?> getLatestMessageStream(String chatId) =>
      userChatService.getLatestMessageStream(chatId);

  Future<String> createChatRoom(
    String currentUserId,
    String recipientUserId,
  ) =>
      userChatService.createChatRoom(currentUserId, recipientUserId);
}

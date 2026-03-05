import 'package:get/get.dart';
import 'package:flutter_application_1/features/chat_user/controllers/chat_user_controller.dart';
import 'package:flutter_application_1/features/chat_user/services/chat_user_service.dart';

class UserChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatUserService>(() => ChatUserService());
    Get.lazyPut<ChatUserController>(() => ChatUserController());
  }
}

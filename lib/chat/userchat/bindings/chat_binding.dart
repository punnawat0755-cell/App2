import 'package:get/get.dart';
import 'package:flutter_application_1/chat/userchat/controllers/ChatUserController.dart';
import 'package:flutter_application_1/chat/userchat/services/ChatUserService.dart';

class UserChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatUserService>(() => ChatUserService());
    Get.lazyPut<ChatUserController>(() => ChatUserController());
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseChatIdentityService {
  FirebaseChatIdentityService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<User?> ensureSignedIn() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return currentUser;
    }

    try {
      final credential = await _auth.signInAnonymously();
      return credential.user;
    } catch (error) {
      debugPrint('Firebase chat auth error: $error');
      return null;
    }
  }
}

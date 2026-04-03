import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';

class FirebaseChatIdentityService {
  FirebaseChatIdentityService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'Users';
  static const String _usersBySupabaseCollection = 'UsersBySupabase';

  static Future<User?> ensureSignedIn() async {
    final supabaseUser = supabase.auth.currentUser;
    if (supabaseUser == null) {
      debugPrint('Firebase chat auth warning: no active Supabase user');
    }

    final currentUser = _auth.currentUser;
    final signedInUser = currentUser ?? (await _auth.signInAnonymously()).user;
    if (signedInUser == null) return null;

    try {
      if (supabaseUser != null) {
        await _upsertIdentityLink(
          firebaseUid: signedInUser.uid,
          supabaseUserId: supabaseUser.id,
          metadata: supabaseUser.userMetadata ?? const <String, dynamic>{},
          email: supabaseUser.email,
        );
      }
      return signedInUser;
    } catch (error) {
      debugPrint('Firebase chat auth mapping warning: $error');
      return signedInUser;
    }
  }

  static Future<void> _upsertIdentityLink({
    required String firebaseUid,
    required String supabaseUserId,
    required Map<String, dynamic> metadata,
    required String? email,
  }) async {
    final username = _firstNonEmpty([
      metadata['username'],
      metadata['name'],
      metadata['display_name'],
      email?.split('@').first,
    ]);

    final firebasePayload = <String, dynamic>{
      'supabaseUserId': supabaseUserId,
      'supabase_user_id': supabaseUserId,
      'identityUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (username != null) {
      firebasePayload['username'] = username;
    }
    if (email != null && email.isNotEmpty) {
      firebasePayload['email'] = email;
    }

    await _firestore
        .collection(_usersCollection)
        .doc(firebaseUid)
        .set(firebasePayload, SetOptions(merge: true));

    final canonicalPayload = <String, dynamic>{
      'supabaseUserId': supabaseUserId,
      'supabase_user_id': supabaseUserId,
      'lastFirebaseUid': firebaseUid,
      'firebaseUids': FieldValue.arrayUnion([firebaseUid]),
      'identityUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (username != null) {
      canonicalPayload['username'] = username;
    }
    if (email != null && email.isNotEmpty) {
      canonicalPayload['email'] = email;
    }

    await _firestore
        .collection(_usersBySupabaseCollection)
        .doc(supabaseUserId)
        .set(canonicalPayload, SetOptions(merge: true));

    await _cleanupDuplicateUsersDocs(
      currentFirebaseUid: firebaseUid,
      supabaseUserId: supabaseUserId,
    );
  }

  static Future<void> _cleanupDuplicateUsersDocs({
    required String currentFirebaseUid,
    required String supabaseUserId,
  }) async {
    if (supabaseUserId.trim().isEmpty) return;

    final duplicateIds = <String>{};

    final byCamel = await _firestore
        .collection(_usersCollection)
        .where('supabaseUserId', isEqualTo: supabaseUserId)
        .limit(200)
        .get();
    for (final doc in byCamel.docs) {
      if (doc.id != currentFirebaseUid) {
        duplicateIds.add(doc.id);
      }
    }

    final bySnake = await _firestore
        .collection(_usersCollection)
        .where('supabase_user_id', isEqualTo: supabaseUserId)
        .limit(200)
        .get();
    for (final doc in bySnake.docs) {
      if (doc.id != currentFirebaseUid) {
        duplicateIds.add(doc.id);
      }
    }

    if (duplicateIds.isEmpty) return;

    final batch = _firestore.batch();
    for (final docId in duplicateIds) {
      batch.delete(_firestore.collection(_usersCollection).doc(docId));
    }
    await batch.commit();
  }

  static String? _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }
}

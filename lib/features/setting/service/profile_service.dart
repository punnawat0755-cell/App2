import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  ProfileService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  User? get currentUser => _supabase.auth.currentUser;

  Future<Map<String, dynamic>> fetchProfile() async {
    final user = currentUser;
    if (user == null) {
      return {
        'displayName': 'Seal',
        'email': '',
      };
    }

    final profile = await _supabase
        .from('profiles')
        .select('username, display_name, bio')
        .eq('id', user.id)
        .maybeSingle();

    final metadata = Map<String, dynamic>.from(
      user.userMetadata ?? const <String, dynamic>{},
    );

    return {
      'displayName': _readFirstText(
            <dynamic>[
              profile?['display_name'],
              profile?['username'],
              metadata['display_name'],
              metadata['username'],
              metadata['name'],
              user.email?.split('@').first,
            ],
          ) ??
          'Seal',
      'email': user.email ?? '',
      'bio': _readFirstText(<dynamic>[
            profile?['bio'],
            metadata['bio'],
          ]) ??
          '',
    };
  }

  Future<void> updateProfile({
    required String displayName,
    required String bio,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No active user');
    }

    final trimmedName = displayName.trim();
    final trimmedBio = bio.trim();

    await _supabase.from('profiles').upsert({
      'id': user.id,
      'username': trimmedName,
      'display_name': trimmedName,
      'bio': trimmedBio,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  String? _readFirstText(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }
}

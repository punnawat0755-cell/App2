import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  ProfileService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  static const _profilesTable = 'profiles';
  static const List<String> _profileSelectCandidates = <String>[
    'username, display_name, bio',
    'username, displayName, bio',
    'username, displayname, bio',
    'display_name, bio',
    'displayName, bio',
    'displayname, bio',
    'username, bio',
    'username, display_name',
    'username, displayName',
    'username, displayname',
    'username',
    'bio',
  ];

  User? get currentUser => _supabase.auth.currentUser;

  Future<Map<String, dynamic>> fetchProfile() async {
    final user = currentUser;
    if (user == null) {
      return {
        'displayName': 'Seal',
        'email': '',
      };
    }

    final profile = await _fetchProfileRow(user.id);

    final metadata = Map<String, dynamic>.from(
      user.userMetadata ?? const <String, dynamic>{},
    );

    return {
      'displayName': _readFirstText(
            <dynamic>[
              profile['display_name'],
              profile['displayName'],
              profile['displayname'],
              profile['username'],
              metadata['display_name'],
              metadata['displayName'],
              metadata['displayname'],
              metadata['username'],
              metadata['preferred_username'],
              metadata['full_name'],
              metadata['name'],
              user.email?.split('@').first,
            ],
          ) ??
          'Seal',
      'email': user.email ?? '',
      'bio': _readFirstText(<dynamic>[
            profile['bio'],
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
    final saveResult = await _saveProfileRow(
      userId: user.id,
      displayName: trimmedName,
      bio: trimmedBio,
    );
    final metadataSynced = await _syncAuthMetadata(
      displayName: trimmedName,
      bio: trimmedBio,
    );

    if (!saveResult.savedBio && !metadataSynced) {
      throw Exception('Profile name was saved, but bio could not be updated.');
    }
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

  Future<Map<String, dynamic>> _fetchProfileRow(String userId) async {
    PostgrestException? lastSchemaError;

    for (final selectClause in _profileSelectCandidates) {
      try {
        final row = await _supabase
            .from(_profilesTable)
            .select(selectClause)
            .eq('id', userId)
            .maybeSingle();

        if (row == null ) {
          return <String, dynamic>{};
        }
        if (row is Map) {
          return Map<String, dynamic>.from(row);
        }
        return <String, dynamic>{};
      } on PostgrestException catch (error) {
        if (_isMissingColumnError(error)) {
          lastSchemaError = error;
          continue;
        }
        rethrow;
      }
    }

    if (lastSchemaError != null) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  Future<_ProfileSaveResult> _saveProfileRow({
    required String userId,
    required String displayName,
    required String bio,
  }) async {
    PostgrestException? lastSchemaError;

    for (final payload in _buildProfilePayloads(
      userId: userId,
      displayName: displayName,
      bio: bio,
    )) {
      try {
        await _supabase.from(_profilesTable).upsert(payload, onConflict: 'id');
        return _ProfileSaveResult(
          savedBio: payload.containsKey('bio'),
        );
      } on PostgrestException catch (error) {
        if (_isMissingColumnError(error)) {
          lastSchemaError = error;
          continue;
        }
        rethrow;
      }
    }

    if (lastSchemaError != null) {
      throw Exception(
        'Unable to save profile because the profiles table schema does not match the app.',
      );
    }

    throw Exception('Unable to save profile.');
  }

  Future<bool> _syncAuthMetadata({
    required String displayName,
    required String bio,
  }) async {
    final user = currentUser;
    if (user == null) {
      return false;
    }

    final nextMetadata = <String, dynamic>{
      ...Map<String, dynamic>.from(user.userMetadata ?? const <String, dynamic>{}),
      'username': displayName,
      'preferred_username': displayName,
      'display_name': displayName,
      'displayName': displayName,
      'displayname': displayName,
      'name': displayName,
      'bio': bio,
    };

    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: nextMetadata),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  List<Map<String, dynamic>> _buildProfilePayloads({
    required String userId,
    required String displayName,
    required String bio,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final payloads = <Map<String, dynamic>>[];
    final seen = <String>{};

    final nameVariants = <Map<String, dynamic>>[
      <String, dynamic>{
        'username': displayName,
        'display_name': displayName,
      },
      <String, dynamic>{
        'username': displayName,
        'displayName': displayName,
      },
      <String, dynamic>{
        'username': displayName,
        'displayname': displayName,
      },
      <String, dynamic>{
        'username': displayName,
      },
      <String, dynamic>{
        'display_name': displayName,
      },
      <String, dynamic>{
        'displayName': displayName,
      },
      <String, dynamic>{
        'displayname': displayName,
      },
    ];

    final bioVariants = <Map<String, dynamic>>[
      <String, dynamic>{'bio': bio},
      <String, dynamic>{},
    ];

    final auditVariants = <Map<String, dynamic>>[
      <String, dynamic>{'updated_at': timestamp},
      <String, dynamic>{},
    ];

    for (final nameVariant in nameVariants) {
      for (final bioVariant in bioVariants) {
        for (final auditVariant in auditVariants) {
          final payload = <String, dynamic>{
            'id': userId,
            ...nameVariant,
            ...bioVariant,
            ...auditVariant,
          };
          final signature = payload.keys.toList()..sort();
          if (seen.add(signature.join('|'))) {
            payloads.add(payload);
          }
        }
      }
    }

    return payloads;
  }

  bool _isMissingColumnError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == '42703' ||
        error.code == 'PGRST204' ||
        message.contains('column') && message.contains('does not exist') ||
        message.contains('could not find the') && message.contains('column');
  }
}

class _ProfileSaveResult {
  const _ProfileSaveResult({
    required this.savedBio,
  });

  final bool savedBio;
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ContentModerationService {
  ContentModerationService._();

  static final ContentModerationService instance = ContentModerationService._();

  static const String _n8nModerationWebhook =
      'https://n8n.tgstack.dev/webhook/HowAreYou';
  static const bool _moderationFailOpen = bool.fromEnvironment(
    'N8N_MODERATION_FAIL_OPEN',
    defaultValue: true,
  );
  static const bool _allowBadCertificate = bool.fromEnvironment(
    'N8N_ALLOW_BAD_CERT',
    defaultValue: false, // SECURE
  );
  static const String _allowBadCertificateHosts = String.fromEnvironment(
    'N8N_ALLOW_BAD_CERT_HOSTS',
    defaultValue: 'n8n.tgstack.dev',
  );
  static const Duration _moderationTimeout = Duration(seconds: 6);
  static const List<String> _localProfanityTokens = [
    'เหี้ย',
    'ไอ้เหี้ย',
    'อีเหี้ย',
    'ควย',
    'ไอ้ควย',
    'อีควย',
    'หี',
    'หำ',
    'กระหรี่',
    'อีกะหรี่',
    'สัส',
    'ไอ้สัส',
    'อีสัส',
    'ไอสัส',
    'ไอสาด',
    'สัตว์',
    'สัด',
    'ส้นตีน',
    'ตีน',
    'ตรีน',
    'ตายห่า',
    'ห่า',
    'ห่าน',
    'หน้าหี',
    'หน้าควย',
    'เสือก',
    'กู',
    'เย็ด',
    'เย็ดแม่',
    'เย็ดพ่อ',
    'แม่ง',
    'มรึง',
    'มึง',
    'ควาย',
    'ไอ้ควาย',
    'อีควาย',
    'ควายเอ๊ย',
    'โง่สัส',
    'ค-ว-ย',
    'ห-ี',
    'เ-ห-ี้-ย',
    'fuck',
    'f*ck',
    'fuk',
    'fuc',
    'fucking',
    'fk',
    'wtf',
    'shit',
    'sh1t',
    'bullshit',
    'dipshit',
    'bitch',
    'b1tch',
    'son of bitch',
    'son of a bitch',
    'asshole',
    'ass hole',
    'arsehole',
    'jackass',
    'bastard',
    'motherfucker',
    'mother fucker',
    'mf',
    'mfer',
    'dick',
    'd1ck',
    'cock',
    'prick',
    'pussy',
    'pussyhole',
    'cunt',
    'slut',
    'whore',
    'hoe',
    'retard',
    'idiot',
    'stupid',
    'kys',
    'kill yourself',
    'nigga',
    'nigger',
    'faggot',
    'tranny',
    'rape',
    'raped',
    'rapist',
    'porn',
    'xxx',
    'blowjob',
    'handjob',
  ];
  static const String _userReportedProfanityBlock = '''
aisus
ai sus
i sus
sus
susss
sussss
aisat
ai sat
isat
sat
sas
aikwai
ai kwai
ikwai
kwai
kwaii
kwaiii
aingo
ai ngo
ingo
ngo
ngoo
aiba
ai ba
iba
ba
bah
aihere
ai here
ihere
here
hia
heea
hiaaa
aihia
aimaeng
ai maeng
imaeng
maeng
meng
meang
aihay
ai hay
ihay
hay
aihee
ai hee
ihee
hee
sus maeng
sus mak
sus sud
here maeng
here mak
here sud
kwai maeng
kwai mak
ngo maeng
ngo mak
ba maeng
hia maeng
sus wa
here wa
kwai wa
ngo wa
mung ngo
mung ngo wa
mung pen arai
mung pen arai wa
mung kid arai
mung kid arai wa
kid arai yu
kid arai wa
mai mee samaa
mai mee samaa loei
ba pai laew
arai khong mung
arai khong mung wa
kwai mak mak
ngo mak mak
aisusmaeng
aiheresud
aikwaimak
aingomaeng
aibamaeng
susssmaeng
hereeewa
kwaiiimak
ngooomak
isus
iss
isss
issss
isssss
aisuss
aisusss
aisussss
aisusssss
susmak
susmakmak
susmaeng
susmaengง
susmaenggg
suswa
susวะ
susวะะ
susเลย
sussud
sussudๆ
sussudสุด
aiheree
aihereee
aihereeee
aihereeeee
iheree
ihereee
ihereeee
hereee
hereeee
hereeeee
hiaaa
hiaaaa
hiaaaaa
hiaaaaaa
hiaaamak
hiaaamaeng
hiawa
hiaวะ
hiaวะะ
hiaเลย
hiasud
hiasudๆ
aikwaii
aikwaiii
aikwaiiii
ikwaii
ikwaiii
ikwaiiii
kwaiii
kwaiiii
kwaiiiii
kwaimak
kwaimaeng
kwaiwa
kwaiวะ
kwaisud
kwaisudๆ
aingoo
aingooo
aingoooo
ingoo
ingooo
ingoooo
ngooo
ngoooo
ngooooo
ngoomak
ngomaeng
ngowa
ngoวะ
ngosud
ngosudๆ
aibaa
aibaaa
aibaaaa
ibaa
ibaaa
ibaaaa
baaa
baaaa
baaaaa
baamak
baamaeng
bawa
baวะ
basud
basudๆ
aimaengg
aimaenggg
aimaengggg
imaengg
imaenggg
imaengggg
maengg
maenggg
maengggg
mengg
menggg
mengggg
meanggg
meangggg
aiheeey
aiheee
aiheeee
iheee
iheeee
heee
heeee
heeeee
aihayy
aihayyy
ihayy
ihayyy
hayyy
hayyyy
susๆ
susๆๆ
hereๆ
hereๆๆ
kwaiๆ
kwaiๆๆ
ngoๆ
ngoๆๆ
baๆ
baๆๆ
hiaๆ
hiaๆๆ
maengๆ
maengๆๆ
sus555
here555
kwai555
ngo555
ba555
hia555
maeng555
mung555
suslol
herelol
kwailol
ngolol
balol
hialol
maenglol
suswtf
herewtf
kwaiwtf
ngowtf
bawtf
hiawtf
maengwtf
mung ngo mak
mung ngo mak mak
mung ngo sus
mung ngo sus maeng
mung ngo here
mung ngo here maeng
mung ngo kwai
mung ngo kwai mak
mung ngo ba
mung ngo ba mak
mung pen kwai
mung pen kwai mak
mung pen sus
mung pen here
mung pen ngo
mung pen ba
mung pen rai
mung pen arai waaa
mung pen arai waaaa
mung pen arai waaaaa
mung pen arai sus
mung pen arai here
mung kid arai waaa
mung kid arai waaaa
mung kid arai waaaaa
mung kid arai sus
mung kid arai here
mung kid arai kwai
mung kid arai ba
arai khong mung sus
arai khong mung here
arai khong mung kwai
arai khong mung ngo
arai khong mung ba
arai khong mung maeng
arai khong mung waaa
arai khong mung waaaa
arai khong mung waaaaa
mai mee samaa sus
mai mee samaa here
mai mee samaa kwai
mai mee samaa ngo
mai mee samaa ba
mai mee samaa maeng
mai mee samaa loei sus
mai mee samaa loei here
mai mee samaa loei kwai
mai mee samaa loei ngo
mai mee samaa loei ba
mai mee samaa loei maeng
ba pai laew sus
ba pai laew here
ba pai laew kwai
ba pai laew ngo
ba pai laew maeng
kwai mak sus
kwai mak here
kwai mak ngo
kwai mak ba
ngo mak sus
ngo mak here
ngo mak kwai
ngo mak ba
sus mak here
sus mak kwai
sus mak ngo
sus mak ba
here mak sus
here mak kwai
here mak ngo
here mak ba
kuy
ikuy
ai kuy
aikuy
kuyy
kuyyy
kuyyyy
kuyyyyy
kuy mak
kuy mak mak
kuy maeng
kuy maengง
kuy wa
kuyวะ
kuyวะะ
kuy sud
kuy sudๆ
kuy sud sud
kuyเลย
kuy555
kuywtf
kuylol
kuyๆ
kuyๆๆ
aikuyy
aikuyyy
aikuyyyy
ikuyy
ikuyyy
ikuyyyy
kuymaeng
kuymak
kuysud
kuywa
kuyhere
kuysus
kuykwai
kuyngo
kuyba
kuyhia
kuymaenggg
kuymaengggg
kuymaengงง
kuymaengงงง
kuywaaa
kuywaaaa
kuywaaaaa
kuyhereee
kuyhereeee
kuyhereeeee
kuysusss
kuysussss
kuysusssss
kuykwaiii
kuykwaiiii
kuyngooo
kuyngoooo
kuyngooooo
kuybaaa
kuybaaaa
kuybaaaaa
kuyhiaaa
kuyhiaaaa
kuyhiaaaaa
kuy hee
kuy hia
kuy here
kuy sus
kuy kwai
kuy ngo
kuy ba
kuy maeng
kuy mak
kuy sud
kuy wa
ไอสัส
ไอสัตว์
สัส
สัตว์
เหี้ย
ไอเหี้ย
เหี้ยๆ
ควาย
ไอควาย
โง่
ไอโง่
บ้า
ไอบ้า
ห่า
ไอห่า
แม่ง
มึง
กู
อีดอก
ดอกทอง
อีเหี้ย
อีควาย
อีโง่
อีบ้า
สันดาน
ชิบหาย
ชิบหายวายวอด
ระยำ
เลว
เหี้ยมาก
เหี้ยสุด
ควายมาก
โง่มาก
โง่ชิบหาย
บ้าชิบหาย
มึงโง่
มึงโง่วะ
มึงเป็นอะไร
มึงเป็นอะไรของมึง
คิดได้ไง
คิดอะไรอยู่
ไม่มีสมอง
โง่ชิบหาย
ควายมาก
บ้าไปแล้ว
อะไรของมึง
มึงทำอะไร
มึงคิดอะไร
ไอสัสๆ
ไอสัสๆๆ
ไอสัส555
ไอสัสวะ
ไอสัสวะะ
ไอสัสเลย
ไอสัสมาก
ไอสัสมากๆ
ไอสัสสุด
ไอสัสสุดๆ
ไอสัสแม่ง
ไอสัสแม่งง
ไอสัสแม่งงง
ไอเหี้ยๆ
ไอเหี้ยๆๆ
ไอเหี้ย555
ไอเหี้ยวะ
ไอเหี้ยวะะ
ไอเหี้ยเลย
ไอเหี้ยมาก
ไอเหี้ยมากๆ
ไอเหี้ยสุด
ไอเหี้ยสุดๆ
ไอเหี้ยแม่ง
ไอเหี้ยแม่งง
ไอเหี้ยแม่งงง
ไอควายๆ
ไอควายๆๆ
ไอควาย555
ไอควายวะ
ไอควายวะะ
ไอควายเลย
ไอควายมาก
ไอควายมากๆ
ไอควายสุด
ไอควายสุดๆ
ไอควายแม่ง
ไอควายแม่งง
ไอควายแม่งงง
ไอโง่ๆ
ไอโง่ๆๆ
ไอโง่555
ไอโง่วะ
ไอโง่วะะ
ไอโง่เลย
ไอโง่มาก
ไอโง่มากๆ
ไอโง่สุด
ไอโง่สุดๆ
ไอโง่แม่ง
ไอโง่แม่งง
ไอโง่แม่งงง
ไอบ้าๆ
ไอบ้าๆๆ
ไอบ้า555
ไอบ้าวะ
ไอบ้าวะะ
ไอบ้าเลย
ไอบ้ามาก
ไอบ้ามากๆ
ไอบ้าสุด
ไอบ้าสุดๆ
ไอบ้าแม่ง
ไอบ้าแม่งง
ไอบ้าแม่งงง
เหี้ยๆๆ
เหี้ยๆๆๆ
เหี้ย555
เหี้ยวะ
เหี้ยวะะ
เหี้ยเลย
เหี้ยมาก
เหี้ยมากๆ
เหี้ยสุด
เหี้ยสุดๆ
เหี้ยแม่ง
เหี้ยแม่งง
เหี้ยแม่งงง
ควายๆๆ
ควายๆๆๆ
ควาย555
ควายวะ
ควายวะะ
ควายเลย
ควายมาก
ควายมากๆ
ควายสุด
ควายสุดๆ
ควายแม่ง
ควายแม่งง
ควายแม่งงง
โง่ๆๆ
โง่ๆๆๆ
โง่555
โง่วะ
โง่วะะ
โง่เลย
โง่มาก
โง่มากๆ
โง่สุด
โง่สุดๆ
โง่แม่ง
โง่แม่งง
โง่แม่งงง
บ้าๆๆ
บ้าๆๆๆ
บ้า555
บ้าวะ
บ้าวะะ
บ้าเลย
บ้ามาก
บ้ามากๆ
บ้าสุด
บ้าสุดๆ
บ้าแม่ง
บ้าแม่งง
บ้าแม่งงง
ควย
ไอควย
ควยๆ
ควยๆๆ
ควย555
ควยวะ
ควยวะะ
ควยเลย
ควยมาก
ควยมากๆ
ควยสุด
ควยสุดๆ
ควยแม่ง
ควยแม่งง
ควยแม่งงง
ควยมึง
ควยกู
ควยไง
ควยไร
ควยอะ
ควยสิ
ควยจัง
ควยว่ะ
ควยเว้ย
ควยนะ
ควยแหละ
ควยดิ
ควยห่า
ควยสัส
ควยเหี้ย
ควยควาย
ควยโง่
ควยบ้า
ควยแม่งๆ
ควยแม่งๆๆ
ควยยย
ควยยยย
ควยยยยย
ควยยยยยย
''';

  static final Set<String> _allLocalProfanityTokens = {
    ..._localProfanityTokens.map((token) => token.toLowerCase()),
    ..._userReportedProfanityBlock
        .split('\n')
        .map((token) => token.trim().toLowerCase())
        .where((token) => token.isNotEmpty),
  };

  late final http.Client _httpClient = _buildHttpClient();

  Future<ContentModerationResult> moderateText({
    required String source,
    required String text,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _n8nModerationWebhook.trim().isEmpty) {
      return ContentModerationResult.allow(trimmed);
    }

    final webhookUri = Uri.tryParse(_n8nModerationWebhook);
    debugPrint(
      'n8n moderation request source=$source url=$_n8nModerationWebhook host=${webhookUri?.host ?? '-'}',
    );

    final requestPayload = <String, dynamic>{
      'action': 'content_moderate',
      'source': source,
      'message': trimmed,
      'text': trimmed,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      ...metadata,
    };

    try {
      final response = await _httpClient
          .post(
            webhookUri ?? Uri.parse(_n8nModerationWebhook),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(requestPayload),
          )
          .timeout(_moderationTimeout);

      debugPrint(
        'n8n moderation http=${response.statusCode} source=$source body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackOnModerationError(
            trimmed, 'http-${response.statusCode}');
      }

      if (response.body.trim().isEmpty) {
        return _fallbackOnModerationError(trimmed, 'empty-body');
      }

      final responsePayload = _parseModerationPayload(response.body);
      if (responsePayload == null) {
        return _fallbackOnModerationError(trimmed, 'invalid-payload');
      }

      final status =
          (responsePayload['status'] ?? '').toString().trim().toLowerCase();
      final allowed = _readBool(responsePayload, const ['allowed', 'allow']);
      final explicitProfanity = _readBool(
            responsePayload,
            const ['isProfane', 'profanity', 'containsProfanity'],
          ) ==
          true;
      final safeText = _readSafeText(responsePayload, trimmed);

      debugPrint(
        'n8n moderation payload source=$source payload=$responsePayload',
      );

      if (allowed != null) {
        if (allowed) {
          return ContentModerationResult.allow(safeText);
        }
        return const ContentModerationResult.block(
          'moderation-blocked-by-n8n',
        );
      }

      if (explicitProfanity ||
          status == 'block' ||
          status == 'blocked' ||
          status == 'reject') {
        return const ContentModerationResult.block(
          'moderation-blocked-by-n8n',
        );
      }

      if (status == 'mask' ||
          status == 'sanitize' ||
          status == 'sanitized' ||
          status == 'allow' ||
          status == 'allowed' ||
          status == 'ok') {
        return ContentModerationResult.allow(safeText);
      }

      return _fallbackOnModerationError(trimmed, 'unknown-status:$status');
    } on TimeoutException {
      debugPrint('n8n moderation timeout source=$source');
      return _fallbackOnModerationError(trimmed, 'timeout');
    } catch (error) {
      debugPrint('n8n moderation failed source=$source error=$error');
      return _fallbackOnModerationError(trimmed, 'exception');
    }
  }

  ContentModerationResult _fallbackOnModerationError(
    String text,
    String reason,
  ) {
    final blockedByLocal = _containsLocalProfanity(text);
    debugPrint(
      'n8n moderation fallback(local) reason=$reason blocked=$blockedByLocal',
    );

    if (blockedByLocal) {
      return const ContentModerationResult.block(
        'moderation-blocked-local-fallback',
      );
    }

    if (_moderationFailOpen) {
      return ContentModerationResult.allow(text);
    }
    return ContentModerationResult.block('moderation-unavailable:$reason');
  }

  bool _containsLocalProfanity(String input) {
    final lowered = input.toLowerCase();
    final compact = lowered
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u0E00-\u0E7F]'), '');

    for (final token in _allLocalProfanityTokens) {
      if (lowered.contains(token) ||
          compact.contains(token.replaceAll(' ', ''))) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic>? _asMapPayload(dynamic decoded) {
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  Map<String, dynamic>? _parseModerationPayload(String body) {
    final trimmed = body.trim();

    try {
      final decoded = jsonDecode(trimmed);
      final payload = _asMapPayload(decoded);
      if (payload != null) {
        return payload;
      }
    } catch (_) {
      // Accept short plain-text responses such as allow/block.
    }

    final normalized = trimmed.toLowerCase();
    if (normalized == 'ok' ||
        normalized == 'allow' ||
        normalized == 'allowed' ||
        normalized == 'true' ||
        normalized == 'pass') {
      return {'allowed': true};
    }
    if (normalized == 'block' ||
        normalized == 'blocked' ||
        normalized == 'false' ||
        normalized == 'reject') {
      return {'allowed': false};
    }

    return null;
  }

  http.Client _buildHttpClient() {
    if (!_allowBadCertificate) {
      return http.Client();
    }

    final configuredHosts = _allowBadCertificateHosts
        .split(',')
        .map((host) => host.trim().toLowerCase())
        .where((host) => host.isNotEmpty)
        .toSet();
    final webhookHost = Uri.tryParse(_n8nModerationWebhook)?.host.toLowerCase();
    if (webhookHost != null && webhookHost.isNotEmpty) {
      configuredHosts.add(webhookHost);
    }

    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        final isAllowed = configuredHosts.contains(host.toLowerCase());
        if (isAllowed) {
          debugPrint(
            'n8n moderation warning: accepting untrusted cert from $host:$port',
          );
        } else {
          debugPrint(
            'n8n moderation blocked untrusted cert from non-allowed host $host:$port',
          );
        }
        return isAllowed;
      };

    return IOClient(ioClient);
  }

  bool? _readBool(Map<String, dynamic> payload, List<String> keys) {
    final keySet = keys.map((key) => key.toLowerCase()).toSet();
    for (final entry in payload.entries) {
      if (!keySet.contains(entry.key.toLowerCase())) continue;
      final parsed = _parseDynamicBool(entry.value);
      if (parsed != null) return parsed;
    }

    return _readBoolRecursive(payload, keySet);
  }

  bool? _readBoolRecursive(dynamic node, Set<String> keys) {
    var foundTrue = false;

    if (node is Map) {
      final map = Map<String, dynamic>.from(node);

      for (final entry in map.entries) {
        final key = entry.key.toLowerCase();
        if (keys.contains(key)) {
          final parsed = _parseDynamicBool(entry.value);
          if (parsed != null) {
            if (!parsed) return false;
            foundTrue = true;
          }
        }
      }

      for (final value in map.values) {
        final nested = _readBoolRecursive(value, keys);
        if (nested != null) {
          if (!nested) return false;
          foundTrue = true;
        }
      }
      return foundTrue ? true : null;
    }

    if (node is List) {
      for (final item in node) {
        final nested = _readBoolRecursive(item, keys);
        if (nested != null) {
          if (!nested) return false;
          foundTrue = true;
        }
      }
    }
    return foundTrue ? true : null;
  }

  bool? _parseDynamicBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final value = raw.trim().toLowerCase();
      if (value == 'true' || value == '1' || value == 'yes') return true;
      if (value == 'false' || value == '0' || value == 'no') return false;
    }
    return null;
  }

  String _readSafeText(Map<String, dynamic> payload, String fallback) {
    const keys = [
      'cleanMessage',
      'sanitizedText',
      'safeText',
      'maskedText',
      'message',
      'text',
    ];

    for (final key in keys) {
      final raw = payload[key];
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }
    return fallback;
  }
}

class ContentModerationResult {
  const ContentModerationResult({
    required this.allow,
    required this.safeText,
    required this.reason,
  });

  factory ContentModerationResult.allow(String text) => ContentModerationResult(
        allow: true,
        safeText: text,
        reason: '',
      );

  const ContentModerationResult.block(String reasonCode)
      : allow = false,
        safeText = '',
        reason = reasonCode;

  final bool allow;
  final String safeText;
  final String reason;
}

class ContentModerationBlockedException implements Exception {
  const ContentModerationBlockedException(this.reason);

  final String reason;

  @override
  String toString() => 'ContentModerationBlockedException($reason)';
}

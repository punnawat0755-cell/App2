import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/profile/controller/profile_avatar_controller.dart';
import 'package:flutter_application_1/features/setting/view/setting.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// 1. Controller
// ==========================================
class ProfileController extends GetxController {
  final supabase = Supabase.instance.client;
  late final http.Client _httpClient;
  StreamSubscription<AuthState>? _authSubscription;
  String? _activeUserId;

  static const String _n8nPeriodWebhook = String.fromEnvironment(
    'N8N_PERIOD_WEBHOOK',
    defaultValue: 'https://n8n.tgstack.dev/webhook/HowAreYou',
  );
  static const String _n8nPeriodToken = String.fromEnvironment(
    'N8N_PERIOD_TOKEN',
    defaultValue: 'CHANGE_ME_TOKEN',
  );
  // true = ยอมรับ cert ที่ไม่สมบูรณ์สำหรับ host ที่ whitelist ไว้ (แนะนำใช้เฉพาะ debug/profile)
  static const bool _allowBadCertificate = bool.fromEnvironment(
    'N8N_ALLOW_BAD_CERT',
    defaultValue: true,
  );
  static const String _allowBadCertificateHosts = String.fromEnvironment(
    'N8N_ALLOW_BAD_CERT_HOSTS',
    defaultValue: 'n8n.tgstack.dev',
  );
  static const Duration _predictionTimeout = Duration(seconds: 8);

  var coins = 138.obs;
  var today = DateTime.now().day.obs;
  var selectedMonth = DateTime.now().month.obs;
  var selectedYear = DateTime.now().year.obs;
  var selectedDate = 0.obs;

  var isLoading = false.obs;
  var predictionText = "".obs;
  var predictionConfidence = "".obs; // [ใหม่] 'high' หรือ 'low'
  var avgCycleLength = 0.obs; // [ใหม่] รอบเฉลี่ยจริง
  var latestCycleText = "".obs;
  var predictedPeriodDays = <String>{}.obs; // [ใหม่] ไฮไลต์วันคาดการณ์ในปฏิทิน

  // [ใหม่] สถิติรวม
  var statTotalCycles = 0.obs;
  var statAvgCycleLength = 0.obs;
  var statAvgPeriodDuration = 0.obs;
  var statCommonSymptoms = <String>[].obs;

  // ข้อมูลจาก Database (รายวัน)
  var dailyPeriodStatus = <String, bool>{}.obs;
  var dailySymptoms = <String, List<String>>{}.obs;
  var dailyMoodLevels = <String, int>{}.obs;
  var dailyFlowLevel = <String, String?>{}.obs; // [ใหม่]
  var dailyPainLevel = <String, int?>{}.obs; // [ใหม่]
  var dailyNotes = <String, String?>{}.obs; // [ใหม่]

  // State สำหรับ Input ที่กำลังแก้อยู่
  var currentFlowLevel = Rxn<String>(); // [ใหม่]
  var currentPainLevel = Rxn<int>(); // [ใหม่]
  var currentNotes = "".obs; // [ใหม่]

  final TextEditingController notesController =
      TextEditingController(); // [ใหม่]

  var profileName = 'Seal'.obs;
  var userGender = 'other'.obs;
  var isProfileReady = false.obs;

  bool get showsStressMenu => userGender.value != 'female';
  bool get isFemaleAccount => userGender.value == 'female';

  @override
  void onInit() {
    super.onInit();
    _httpClient = _buildHttpClient();
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final nextUserId = data.session?.user.id;
      if (nextUserId == _activeUserId) return;
      _resetProfileState();
      _bootstrapProfile();
    });
    _bootstrapProfile();
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    notesController.dispose();
    _httpClient.close();
    super.onClose();
  }

  /// สร้าง HTTP client สำหรับเรียก n8n
  /// - ปกติใช้ client ปกติ (ตรวจ cert ตามระบบ)
  /// - ถ้าเป็น debug/profile และเปิด allowBadCert -> ยอมรับ cert ไม่สมบูรณ์เฉพาะ host ที่ whitelist
  http.Client _buildHttpClient() {
    if (kReleaseMode || !_allowBadCertificate) {
      return http.Client();
    }

    final configuredHosts = _allowBadCertificateHosts
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    final webhookHost = Uri.tryParse(_n8nPeriodWebhook)?.host.toLowerCase();
    if (webhookHost != null && webhookHost.isNotEmpty) {
      configuredHosts.add(webhookHost);
    }

    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        final isAllowed = configuredHosts.contains(host.toLowerCase());
        if (isAllowed) {
          debugPrint(
            'n8n period warning: accepting untrusted cert from $host:$port (debug/profile only)',
          );
        } else {
          debugPrint(
            'n8n period blocked untrusted cert from non-allowed host $host:$port',
          );
        }
        return isAllowed;
      };

    return IOClient(ioClient);
  }

  String getDateKey(int year, int month, int day) =>
      "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

  String get dateKey =>
      getDateKey(selectedYear.value, selectedMonth.value, selectedDate.value);

  String _normalizeCalendarDateKey(dynamic rawValue) {
    final parsedDate = _tryParseDate(rawValue);
    if (parsedDate != null) {
      return getDateKey(parsedDate.year, parsedDate.month, parsedDate.day);
    }

    return rawValue?.toString() ?? '';
  }

  final List<String> monthNames = [
    "มกราคม",
    "กุมภาพันธ์",
    "มีนาคม",
    "เมษายน",
    "พฤษภาคม",
    "มิถุนายน",
    "กรกฎาคม",
    "สิงหาคม",
    "กันยายน",
    "ตุลาคม",
    "พฤศจิกายน",
    "ธันวาคม",
  ];

  int get daysInMonth =>
      DateTime(selectedYear.value, selectedMonth.value + 1, 0).day;
  int get firstDayOffset =>
      DateTime(selectedYear.value, selectedMonth.value, 1).weekday % 7;

  void changeMonth(String? monthName) {
    if (monthName != null) {
      selectedMonth.value = monthNames.indexOf(monthName) + 1;
      selectedDate.value = 0;
      _syncSelectedInputsForDate();
      loadMonthData();
      if (isFemaleAccount) {
        fetchPeriodPrediction();
      }
    }
  }

  // Sync input fields เมื่อ selectedDate เปลี่ยน
  void selectDay(int day) {
    selectedDate.value = day;
    _syncSelectedInputsForDate();
  }

  void _syncSelectedInputsForDate() => _syncPeriodInputStateForDate();

  void _syncPeriodInputStateForDate() {
    final key = dateKey;
    currentFlowLevel.value = dailyFlowLevel[key];
    currentPainLevel.value = dailyPainLevel[key];
    currentNotes.value = dailyNotes[key] ?? "";
    notesController.text = currentNotes.value;
  }

  Future<void> _bootstrapProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _activeUserId = null;
      isProfileReady.value = true;
      return;
    }

    _activeUserId = user.id;

    try {
      final Map<String, dynamic>? response = await supabase
          .from('profiles')
          .select('username, gender')
          .eq('id', user.id)
          .maybeSingle();

      final profile = response ?? <String, dynamic>{};
      final metadata = Map<String, dynamic>.from(
          user.userMetadata ?? const <String, dynamic>{});

      final name = _readStringIgnoreCase(
            profile,
            const ['username', 'name', 'display_name', 'displayName'],
          ) ??
          _readStringIgnoreCase(
            metadata,
            const ['username', 'name', 'display_name', 'displayName'],
          ) ??
          'Seal';

      final gender = _normalizeGender(
        _readStringIgnoreCase(profile, const ['gender', 'sex']) ??
            _readStringIgnoreCase(metadata, const ['gender', 'sex']),
      );

      profileName.value = name;
      userGender.value = gender;
    } catch (e) {
      debugPrint('profile bootstrap error: $e');
      profileName.value = 'Seal';
      userGender.value = 'other';
    } finally {
      isProfileReady.value = true;
    }

    await loadMonthData();

    if (showsStressMenu &&
        selectedMonth.value == DateTime.now().month &&
        selectedYear.value == DateTime.now().year) {
      selectedDate.value = today.value;
    }

    if (isFemaleAccount) {
      fetchPeriodPrediction();
      fetchLatestCycle();
      fetchMenstrualStats();
    }
  }

  void _resetProfileState() {
    final now = DateTime.now();
    selectedMonth.value = now.month;
    selectedYear.value = now.year;
    selectedDate.value = 0;

    isProfileReady.value = false;
    isLoading.value = false;

    profileName.value = 'Seal';
    userGender.value = 'other';

    predictionText.value = "";
    predictionConfidence.value = "";
    avgCycleLength.value = 0;
    latestCycleText.value = "";
    predictedPeriodDays.clear();

    statTotalCycles.value = 0;
    statAvgCycleLength.value = 0;
    statAvgPeriodDuration.value = 0;
    statCommonSymptoms.clear();

    dailyPeriodStatus.clear();
    dailySymptoms.clear();
    dailyMoodLevels.clear();
    dailyFlowLevel.clear();
    dailyPainLevel.clear();
    dailyNotes.clear();

    currentFlowLevel.value = null;
    currentPainLevel.value = null;
    currentNotes.value = "";
    notesController.clear();
  }

  String _normalizeGender(String? raw) {
    final value = raw?.trim().toLowerCase();
    switch (value) {
      case 'female':
      case 'woman':
      case 'f':
      case 'ผู้หญิง':
        return 'female';
      case 'male':
      case 'man':
      case 'm':
      case 'ผู้ชาย':
        return 'male';
      default:
        return 'other';
    }
  }

  Future<void> loadMonthData() async {
    try {
      isLoading.value = true;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase.rpc(
        'get_monthly_calendar_data',
        params: {'p_year': selectedYear.value, 'p_month': selectedMonth.value},
      );

      dailyPeriodStatus.clear();
      dailySymptoms.clear();
      dailyMoodLevels.clear();
      dailyFlowLevel.clear(); // [ใหม่]
      dailyPainLevel.clear(); // [ใหม่]
      dailyNotes.clear(); // [ใหม่]

      if (response != null) {
        for (var row in response) {
          final key = _normalizeCalendarDateKey(row['calendar_date']);
          if (key.isEmpty) continue;

          dailyPeriodStatus[key] = row['is_menstruating'] ?? false;

          if (row['symptoms'] != null) {
            dailySymptoms[key] = List<String>.from(row['symptoms']);
          }

          // [ใหม่] รับค่า flow_level, pain_level, notes
          dailyFlowLevel[key] = row['flow_level'];
          dailyPainLevel[key] = row['pain_level'];
          dailyNotes[key] = row['notes'];

          final moodLevel = _tryParseInt(row['mood_level']);
          if (moodLevel != null) {
            dailyMoodLevels[key] = moodLevel.clamp(1, 5).toInt();
          }
        }
      }

      _syncSelectedInputsForDate();
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchLatestCycle() async {
    try {
      final response = await supabase.rpc('get_my_menstrual_cycles');
      if (response != null && response is List && response.isNotEmpty) {
        var latest = response.first;
        DateTime start = DateTime.parse(latest['start_date'].toString());
        DateTime end = DateTime.parse(latest['end_date'].toString());
        int days = latest['duration_days'];
        String startStr = "${start.day} ${monthNames[start.month - 1]}";
        String endStr = "${end.day} ${monthNames[end.month - 1]}";
        if (startStr == endStr) {
          latestCycleText.value = "รอบเดือนล่าสุด: $startStr (รวม 1 วัน)";
        } else {
          latestCycleText.value =
              "รอบเดือนล่าสุด: $startStr ถึง $endStr (รวม $days วัน)";
        }
      } else {
        latestCycleText.value = "ยังไม่มีประวัติรอบเดือน";
      }
    } catch (e) {
      latestCycleText.value = "ยังไม่มีประวัติรอบเดือน";
    }
  }

  Future<void> fetchPeriodPrediction() async {
    predictedPeriodDays.clear();
    predictionConfidence.value = "";
    avgCycleLength.value = 0;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      predictionText.value = "";
      return;
    }

    if (_n8nPeriodWebhook.trim().isNotEmpty) {
      final ok = await _fetchPeriodPredictionFromN8n(userId);
      if (ok) {
        _trimPredictedDaysByRecordedPeriodStatus();
        return;
      }
    }

    await _fetchPeriodPredictionFromSupabaseRpc();
    _trimPredictedDaysByRecordedPeriodStatus();
  }

  Future<bool> _fetchPeriodPredictionFromN8n(String userId) async {
    try {
      final uri = Uri.parse(_n8nPeriodWebhook);
      final accessToken = supabase.auth.currentSession?.accessToken;
      debugPrint('n8n period prediction request url=$_n8nPeriodWebhook');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.trim().isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final from = getDateKey(selectedYear.value, selectedMonth.value, 1);
      final to =
          getDateKey(selectedYear.value, selectedMonth.value, daysInMonth);

      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'action': 'period_record',
              'token': _n8nPeriodToken,
              'user_id': userId,
              'from': from,
              'to': to,
              'year': selectedYear.value,
              'month': selectedMonth.value,
            }),
          )
          .timeout(_predictionTimeout);

      debugPrint(
        'n8n period prediction http=${response.statusCode} body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'n8n period prediction failed: ${response.statusCode} ${response.body}',
        );
        return false;
      }

      final decoded = jsonDecode(response.body);
      final payload = _unwrapWebhookPayload(decoded);
      return _applyPredictionPayload(payload);
    } catch (e) {
      debugPrint('n8n period prediction error: $e');
      return false;
    }
  }

  Future<void> _fetchPeriodPredictionFromSupabaseRpc() async {
    try {
      final response = await supabase.rpc('predict_next_period');
      if (response != null && response is List && response.isNotEmpty) {
        var data = response[0];
        avgCycleLength.value = data['avg_cycle_length'] ?? 28;
        predictionConfidence.value = data['confidence'] ?? 'low';

        final predicted = _tryParseDate(data['predicted_start_date']);
        if (predicted != null) {
          predictedPeriodDays.add(
            getDateKey(predicted.year, predicted.month, predicted.day),
          );
          _setPredictionTextFromDate(predicted);
          return;
        }
      }

      predictionText.value = "บันทึกข้อมูลเพื่อคำนวณรอบเดือนถัดไป 🌸";
      predictionConfidence.value = "";
      avgCycleLength.value = 0;
    } catch (e) {
      predictionText.value = "บันทึกข้อมูลเพื่อคำนวณรอบเดือนถัดไป 🌸";
      predictionConfidence.value = "";
      avgCycleLength.value = 0;
    }
  }

  Map<String, dynamic> _unwrapWebhookPayload(dynamic decoded) {
    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{};
  }

  dynamic _readValueIgnoreCase(
      Map<String, dynamic> payload, List<String> keys) {
    final keySet = keys.map((e) => e.toLowerCase()).toSet();
    for (final entry in payload.entries) {
      if (keySet.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }

  String? _readStringIgnoreCase(
      Map<String, dynamic> payload, List<String> keys) {
    final value = _readValueIgnoreCase(payload, keys);
    if (value == null) return null;
    if (value is String) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    if (value is int) {
      final ms = value > 100000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    if (value is double) {
      final asInt = value.toInt();
      final ms = asInt > 100000000000 ? asInt : asInt * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }

    if (value is String) {
      final raw = value.trim();
      if (raw.isEmpty) return null;

      final datePart = raw.length >= 10 ? raw.substring(0, 10) : raw;
      final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(datePart);
      if (match != null) {
        return DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }

      return DateTime.tryParse(raw);
    }

    return null;
  }

  void _setPredictionTextFromDate(DateTime predictedDate) {
    int daysLeft = predictedDate.difference(DateTime.now()).inDays;
    String thaiDate =
        "${predictedDate.day} ${monthNames[predictedDate.month - 1]}";

    if (daysLeft == 0) {
      predictionText.value = "คาดว่าประจำเดือนจะมา 🩸 วันนี้";
    } else if (daysLeft > 0) {
      predictionText.value =
          "คาดว่าประจำเดือนจะมา 🩸 $thaiDate (อีก $daysLeft วัน)";
    } else {
      predictionText.value = "ประจำเดือนมาช้ากว่ากำหนด ${daysLeft.abs()} วัน";
    }
  }

  void _setPredictionTextFromEndDate(DateTime predictedEndDate) {
    int daysLeft = predictedEndDate.difference(DateTime.now()).inDays;
    String thaiDate =
        "${predictedEndDate.day} ${monthNames[predictedEndDate.month - 1]}";

    if (daysLeft == 0) {
      predictionText.value = "คาดว่าประจำเดือนจะหมด 🩸 วันนี้";
    } else if (daysLeft > 0) {
      predictionText.value =
          "คาดว่าประจำเดือนจะหมด 🩸 $thaiDate (อีก $daysLeft วัน)";
    } else {
      predictionText.value = "ประจำเดือนน่าจะหมดไปแล้ว ${daysLeft.abs()} วัน";
    }
  }

  bool _hasExplicitNonPeriodRecord(String dayKey) =>
      dailyPeriodStatus.containsKey(dayKey) &&
      dailyPeriodStatus[dayKey] == false;

  void _trimPredictedDaysByRecordedPeriodStatus() {
    if (predictedPeriodDays.isEmpty) return;

    final sortedKeys = predictedPeriodDays.toList()..sort();

    String? firstRecordedPeriodDay;
    for (final key in sortedKeys) {
      if (dailyPeriodStatus[key] == true) {
        firstRecordedPeriodDay = key;
        break;
      }
    }

    if (firstRecordedPeriodDay == null) return;

    String? firstRecordedNonPeriodDay;
    for (final key in sortedKeys) {
      if (key.compareTo(firstRecordedPeriodDay) < 0) continue;
      if (_hasExplicitNonPeriodRecord(key)) {
        firstRecordedNonPeriodDay = key;
        break;
      }
    }

    if (firstRecordedNonPeriodDay == null) return;

    predictedPeriodDays.removeWhere(
      (key) => key.compareTo(firstRecordedNonPeriodDay!) >= 0,
    );
    predictedPeriodDays.refresh();
  }

  bool _applyPredictionPayload(Map<String, dynamic> payload) {
    if (payload.isEmpty) return false;

    Map<String, dynamic>? prediction;
    final predictionRaw = payload['prediction'];
    if (predictionRaw is Map<String, dynamic>) {
      prediction = predictionRaw;
    } else if (predictionRaw is Map) {
      prediction = Map<String, dynamic>.from(predictionRaw);
    }

    Map<String, dynamic>? analysis;
    final analysisRaw = payload['analysis'];
    if (analysisRaw is Map<String, dynamic>) {
      analysis = analysisRaw;
    } else if (analysisRaw is Map) {
      analysis = Map<String, dynamic>.from(analysisRaw);
    }

    final avgCycle = _tryParseInt(_readValueIgnoreCase(payload, [
      'avg_cycle_length',
      'avgCycleLength',
    ]));
    if (avgCycle != null) {
      avgCycleLength.value = avgCycle;
    } else if (analysis != null) {
      final cycleEstimate = _tryParseInt(_readValueIgnoreCase(analysis, [
        'cycle_length_estimate_days',
        'cycleLengthEstimateDays',
        'avg_cycle_length',
        'avgCycleLength',
      ]));
      if (cycleEstimate != null) avgCycleLength.value = cycleEstimate;
    }

    String? confidenceLabel = _readStringIgnoreCase(payload, [
      'confidence',
      'prediction_confidence',
      'predictionConfidence',
    ]);
    if (confidenceLabel == null && analysis != null) {
      final confidenceRaw =
          _readValueIgnoreCase(analysis, const ['confidence']);
      if (confidenceRaw is num) {
        confidenceLabel = confidenceRaw >= 0.7 ? 'high' : 'low';
      } else if (confidenceRaw != null) {
        final normalized = confidenceRaw.toString().trim().toLowerCase();
        if (normalized == 'high' || normalized == 'low') {
          confidenceLabel = normalized;
        }
      }
    }
    if (confidenceLabel == null && prediction != null) {
      final confidenceRaw =
          _readValueIgnoreCase(prediction, const ['confidence']);
      if (confidenceRaw is num) {
        confidenceLabel = confidenceRaw >= 0.7 ? 'high' : 'low';
      } else if (confidenceRaw != null) {
        final normalized = confidenceRaw.toString().trim().toLowerCase();
        if (normalized == 'high' || normalized == 'low') {
          confidenceLabel = normalized;
        }
      }
    }
    if (confidenceLabel != null) predictionConfidence.value = confidenceLabel;

    final message = _readStringIgnoreCase(payload, [
      'prediction_text',
      'predictionText',
      'message',
      'text',
    ]);

    DateTime? predictedStart = _tryParseDate(_readValueIgnoreCase(payload, [
      'predicted_start_date',
      'predictedStartDate',
      'predicted_next_period',
      'predictedNextPeriod',
    ]));
    if (predictedStart == null && analysis != null) {
      predictedStart = _tryParseDate(_readValueIgnoreCase(analysis, [
        'next_period_estimate',
        'nextPeriodEstimate',
        'predicted_start_date',
        'predictedStartDate',
      ]));
    }

    DateTime? predictedEnd = _tryParseDate(_readValueIgnoreCase(payload, [
      'predicted_end_date',
      'predictedEndDate',
      'period_end_date',
      'periodEndDate',
    ]));
    if (predictedEnd == null && prediction != null) {
      predictedEnd = _tryParseDate(_readValueIgnoreCase(prediction, [
        'predicted_end_date',
        'predictedEndDate',
        'latest_period_end_date',
        'latestPeriodEndDate',
      ]));
    }

    // รองรับ workflow "ทำนายวันหมดประจำเดือน" จาก n8n
    // - ใช้ latest_period_start_date เป็น start
    // - ถ้ามี predicted_end_date ใน prediction และเป็นวันหลังกว่า ให้ใช้แทน
    if (prediction != null) {
      predictedStart ??= _tryParseDate(
        _readValueIgnoreCase(prediction, [
          'latest_period_start_date',
          'latestPeriodStartDate',
        ]),
      );

      final endFromPrediction = _tryParseDate(
        _readValueIgnoreCase(prediction, [
          'predicted_end_date',
          'predictedEndDate',
        ]),
      );
      if (endFromPrediction != null) {
        if (predictedEnd == null || endFromPrediction.isAfter(predictedEnd)) {
          predictedEnd = endFromPrediction;
        }
      }
    }

    final predictedDaysValue = _readValueIgnoreCase(payload, [
      'predicted_period_days',
      'predicted_dates',
      'predictedDays',
      'period_days',
      'periodDays',
    ]);

    final predictedDays = <DateTime>[];
    if (predictedDaysValue is List) {
      for (final item in predictedDaysValue) {
        final parsed = _tryParseDate(item);
        if (parsed != null) predictedDays.add(parsed);
      }
    } else if (predictedDaysValue is String) {
      for (final part in predictedDaysValue.split(',')) {
        final parsed = _tryParseDate(part);
        if (parsed != null) predictedDays.add(parsed);
      }
    }

    predictedDays.sort((a, b) => a.compareTo(b));
    if (predictedStart == null && predictedDays.isNotEmpty) {
      predictedStart = predictedDays.first;
    }
    if (predictedEnd == null && predictedDays.isNotEmpty) {
      predictedEnd = predictedDays.last;
    }

    if (predictedStart == null && predictedDays.isEmpty) {
      final eventsRaw = payload['events'];
      if (eventsRaw is List) {
        for (final eventRaw in eventsRaw) {
          Map<String, dynamic>? event;
          if (eventRaw is Map<String, dynamic>) {
            event = eventRaw;
          } else if (eventRaw is Map) {
            event = Map<String, dynamic>.from(eventRaw);
          }
          if (event == null) continue;

          final type = (event['type'] ?? '').toString().trim().toLowerCase();
          if (type != 'next_period_estimate' &&
              type != 'next_period' &&
              type != 'predicted_period') {
            continue;
          }

          predictedStart = _tryParseDate(event['date'] ?? event['start_date']);
          if (predictedStart != null) break;
        }
      }
    }

    // ถ้ามี start/end แล้ว แต่รายการวันคาดเดายังไม่ครบ -> เติมช่วงวันต่อเนื่อง (สูงสุด 10 วัน)
    if (predictedStart != null && predictedEnd != null) {
      final startDate = DateTime(
        predictedStart.year,
        predictedStart.month,
        predictedStart.day,
      );
      final endDate = DateTime(
        predictedEnd.year,
        predictedEnd.month,
        predictedEnd.day,
      );

      final diffDays = endDate.difference(startDate).inDays;
      final shouldFill = predictedDays.isEmpty ||
          DateTime(
            predictedDays.first.year,
            predictedDays.first.month,
            predictedDays.first.day,
          ).isAfter(startDate) ||
          DateTime(
            predictedDays.last.year,
            predictedDays.last.month,
            predictedDays.last.day,
          ).isBefore(endDate);

      if (diffDays >= 0 && shouldFill) {
        final span = (diffDays + 1).clamp(1, 10).toInt();
        predictedDays
          ..clear()
          ..addAll(
              List.generate(span, (i) => startDate.add(Duration(days: i))));
      }
    }

    if (predictedDays.isEmpty && predictedStart != null) {
      int? estimatedDurationDays;
      if (analysis != null) {
        final latestPeriodRaw = analysis['latest_period'];
        Map<String, dynamic>? latestPeriod;
        if (latestPeriodRaw is Map<String, dynamic>) {
          latestPeriod = latestPeriodRaw;
        } else if (latestPeriodRaw is Map) {
          latestPeriod = Map<String, dynamic>.from(latestPeriodRaw);
        }

        if (latestPeriod != null) {
          estimatedDurationDays =
              _tryParseInt(_readValueIgnoreCase(latestPeriod, [
            'length_days',
            'lengthDays',
            'duration_days',
            'durationDays',
          ]));
        }
      }

      final duration =
          (estimatedDurationDays != null && estimatedDurationDays > 0)
              ? estimatedDurationDays
              : 1;
      final cappedDuration = duration.clamp(1, 7).toInt();
      for (int i = 0; i < cappedDuration; i++) {
        predictedDays.add(predictedStart.add(Duration(days: i)));
      }
    }

    if (predictedDays.isNotEmpty) {
      for (final date in predictedDays) {
        predictedPeriodDays.add(getDateKey(date.year, date.month, date.day));
      }
    } else if (predictedStart != null) {
      predictedPeriodDays.add(
        getDateKey(
            predictedStart.year, predictedStart.month, predictedStart.day),
      );
    }

    final hasPrediction = message != null ||
        predictedStart != null ||
        predictedEnd != null ||
        predictedDays.isNotEmpty;
    if (!hasPrediction) return false;

    if (message != null) {
      predictionText.value = message;
    } else if (predictedEnd != null) {
      _setPredictionTextFromEndDate(predictedEnd);
    } else if (predictedStart != null) {
      _setPredictionTextFromDate(predictedStart);
    } else {
      predictionText.value = "บันทึกข้อมูลเพื่อคำนวณรอบเดือนถัดไป 🌸";
    }

    return true;
  }

  // [ใหม่] ดึงสถิติรวม
  Future<void> fetchMenstrualStats() async {
    try {
      final response = await supabase.rpc('get_menstrual_stats');
      if (response != null && response is List && response.isNotEmpty) {
        var data = response[0];
        statTotalCycles.value = data['total_cycles_recorded'] ?? 0;
        statAvgCycleLength.value = data['avg_cycle_length'] ?? 0;
        statAvgPeriodDuration.value = data['avg_period_duration'] ?? 0;
        if (data['most_common_symptoms'] != null) {
          statCommonSymptoms.value =
              List<String>.from(data['most_common_symptoms']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
  }

  bool getPeriodStatusForSelectedDay() => dailyPeriodStatus[dateKey] ?? false;
  List<String> getSymptomsForSelectedDay() => dailySymptoms[dateKey] ?? [];

  void setPeriodStatus(bool status) {
    if (selectedDate.value != 0) {
      dailyPeriodStatus[dateKey] = status;
      dailyPeriodStatus.refresh();
      // ถ้าเปลี่ยนเป็น "ไม่เป็น" ให้ reset flow และ pain
      if (!status) {
        currentFlowLevel.value = null;
        currentPainLevel.value = null;
      }
    }
  }

  void toggleSymptom(String symptomName) {
    if (selectedDate.value == 0) return;
    List<String> currentList = List.from(getSymptomsForSelectedDay());
    if (currentList.contains(symptomName)) {
      currentList.remove(symptomName);
    } else {
      currentList.add(symptomName);
    }
    dailySymptoms[dateKey] = currentList;
    dailySymptoms.refresh();
  }

  Future<void> saveDailyData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      Get.snackbar("ข้อผิดพลาด", "กรุณาเข้าสู่ระบบก่อน",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    try {
      bool isPeriod = getPeriodStatusForSelectedDay();
      await supabase.rpc(
        'save_calendar_health_log',
        params: {
          'p_log_date': dateKey,
          'p_is_menstruating': isPeriod,
          'p_symptoms': getSymptomsForSelectedDay(),
          // [ใหม่] ส่งค่าใหม่ทั้งหมด (null ถ้าไม่เป็นประจำเดือน)
          'p_flow_level':
              isFemaleAccount && isPeriod ? currentFlowLevel.value : null,
          'p_pain_level':
              isFemaleAccount && isPeriod ? currentPainLevel.value : null,
          'p_notes': notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        },
      );

      // อัปเดต local state
      dailyFlowLevel[dateKey] = isPeriod ? currentFlowLevel.value : null;
      dailyPainLevel[dateKey] = isPeriod ? currentPainLevel.value : null;
      dailyNotes[dateKey] = notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim();

      Get.snackbar(
        "สำเร็จ ✨",
        "บันทึกข้อมูลวันที่ ${selectedDate.value} เรียบร้อยแล้ว",
        backgroundColor: const Color(0xFF2C5282),
        colorText: Colors.white,
      );

      if (isFemaleAccount) {
        fetchPeriodPrediction();
        fetchLatestCycle();
        fetchMenstrualStats(); // [ใหม่] รีเฟรชสถิติ
      } else {
        await loadMonthData();
      }
    } catch (e) {
      Get.snackbar("เกิดข้อผิดพลาด", "ไม่สามารถบันทึกข้อมูลได้: $e",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  String? _moodImagePathFromLevel(int? moodLevel) {
    switch (moodLevel) {
      case 1:
        return 'assets/images/whale_cry.png';
      case 2:
        return 'assets/images/whale_sad.png';
      case 3:
        return 'assets/images/whale_impassible.png';
      case 4:
        return 'assets/images/whale_happy.png';
      case 5:
        return 'assets/images/whale_love.png';
      default:
        return null;
    }
  }

  String? getWhaleImage(int day) {
    final dk = getDateKey(selectedYear.value, selectedMonth.value, day);
    return _moodImagePathFromLevel(dailyMoodLevels[dk]);
  }

  bool hasMaleHealthRecord(String dayKey) {
    final symptoms = dailySymptoms[dayKey];
    final note = dailyNotes[dayKey]?.trim() ?? '';
    return dailyMoodLevels.containsKey(dayKey) ||
        dailyPeriodStatus[dayKey] == true ||
        (symptoms != null && symptoms.isNotEmpty) ||
        note.isNotEmpty;
  }

  String? getMaleHealthImage(int day) {
    final dayKey = getDateKey(selectedYear.value, selectedMonth.value, day);
    return _moodImagePathFromLevel(dailyMoodLevels[dayKey]);
  }

  final List<Map<String, String>> symptomsList = [
    {'name': 'ปวดท้อง', 'img': 'assets/images/thunder 1.png'},
    {'name': 'แปรปรวน', 'img': 'assets/images/thunder 2.png'},
    {'name': 'ท้องอืด', 'img': 'assets/images/thunder 3.png'},
    {'name': 'ปวดหัวไมเกรน', 'img': 'assets/images/thunder 4.png'},
    {'name': 'หงุดหงิด', 'img': 'assets/images/thunder 5.png'},
    {'name': 'เป็นไข้', 'img': 'assets/images/thunder 6.png'},
    {'name': 'หิวบ่อย', 'img': 'assets/images/thunder 7.png'},
    {'name': 'สิวขึ้น', 'img': 'assets/images/thunder 8.png'},
  ];

  final List<Map<String, String>> maleSymptomsList = [
    {'name': 'เครียด', 'img': 'assets/images/thunder 1.png'},
    {'name': 'นอนไม่หลับ', 'img': 'assets/images/thunder 2.png'},
    {'name': 'ปวดหัว', 'img': 'assets/images/thunder 3.png'},
    {'name': 'อ่อนเพลีย', 'img': 'assets/images/thunder 4.png'},
    {'name': 'ปวดเมื่อย', 'img': 'assets/images/thunder 5.png'},
    {'name': 'เป็นไข้', 'img': 'assets/images/thunder 6.png'},
    {'name': 'เวียนหัว', 'img': 'assets/images/thunder 7.png'},
    {'name': 'เบื่ออาหาร', 'img': 'assets/images/thunder 8.png'},
  ];
}

// ==========================================
// 2. ProfilePage
// ==========================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());
    final ProfileAvatarController avatarController =
        Get.isRegistered<ProfileAvatarController>()
            ? Get.find<ProfileAvatarController>()
            : Get.put(ProfileAvatarController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          if (!controller.isProfileReady.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(controller, avatarController),
                const SizedBox(height: 25),
                if (controller.showsStressMenu)
                  _buildStressContent(controller)
                else
                  _buildMenstrualContent(controller),
                const SizedBox(height: 40),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(
    ProfileController controller,
    ProfileAvatarController avatarController,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDA7B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Image.asset('assets/images/k1.png', width: 35, height: 30),
              const SizedBox(width: 1),
              Obx(() => Text(
                    "${controller.coins}",
                    style: const TextStyle(
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Get.to(() => const SettingPage()),
          child: Obx(
            () => CircleAvatar(
              radius: 25,
              backgroundImage: avatarController.avatarImageProvider,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenstrualContent(ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "รอบเดือนและอาการ",
              style: GoogleFonts.mitr(
                textStyle: const TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Obx(() => DropdownButton<String>(
                  value:
                      controller.monthNames[controller.selectedMonth.value - 1],
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Color(0xFF757575)),
                  underline: const SizedBox(),
                  style: GoogleFonts.mitr(
                    textStyle: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onChanged: (val) => controller.changeMonth(val),
                  items: controller.monthNames
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m, style: GoogleFonts.mitr()),
                        ),
                      )
                      .toList(),
                )),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFCEEFFE).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"]
                    .map(
                      (day) => SizedBox(
                        width: 35,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF4489D7),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Obx(
                () => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.daysInMonth + controller.firstDayOffset,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.65,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 0,
                  ),
                  itemBuilder: (context, index) {
                    final day = index - controller.firstDayOffset + 1;
                    if (day < 1 || day > controller.daysInMonth) {
                      return const SizedBox();
                    }

                    return Obx(() {
                      final dayKey = controller.getDateKey(
                        controller.selectedYear.value,
                        controller.selectedMonth.value,
                        day,
                      );
                      final whaleImage = controller.getWhaleImage(day);

                      final isSelected = controller.selectedDate.value == day;
                      final isToday = controller.today.value == day &&
                          controller.selectedMonth.value ==
                              DateTime.now().month;
                      final isPeriodDay =
                          controller.dailyPeriodStatus[dayKey] ?? false;
                      final isPredictedDay =
                          controller.predictedPeriodDays.contains(dayKey);

                      Color bgColor = Colors.transparent;
                      Color textColor = const Color(0xFF4489D7);

                      if (isSelected) {
                        bgColor = const Color(0xFFFFD348);
                      } else if (isPeriodDay) {
                        bgColor = const Color(0xFFFF5240);
                        textColor = Colors.white;
                      } else if (isPredictedDay) {
                        bgColor = const Color(0xFFFFBCB5);
                        textColor = Colors.white;
                      } else if (isToday) {
                        bgColor = const Color(0xFFCCCCCC);
                      }

                      return GestureDetector(
                        onTap: () => controller.selectDay(day),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: bgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "$day",
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (whaleImage != null)
                              const SizedBox(height: 4),
                            if (whaleImage != null)
                              Image.asset(
                                whaleImage,
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox(height: 32),
                              ),
                          ],
                        ),
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Text(
          "บันทึกอาการ",
          style: GoogleFonts.mitr(
            textStyle: const TextStyle(
              color: Color(0xFF4489D7),
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Obx(() {
          if (controller.selectedDate.value == 0) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDA7B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF757575),
                  width: 1.5,
                ),
              ),
              child: const Text(
                "กรุณาเลือกวันที่ต้องการ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5D4037),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusButton(
                    controller,
                    "เป็นประจำเดือน",
                    const Color(0xFFA6E3F9),
                    true,
                  ),
                  const SizedBox(width: 15),
                  _buildStatusButton(
                    controller,
                    "ไม่เป็นประจำเดือน",
                    const Color(0xFFA6E3F9),
                    false,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 15,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: controller.symptomsList.map((item) {
                  final isSelected = controller
                      .getSymptomsForSelectedDay()
                      .contains(item['name']);
                  return GestureDetector(
                    onTap: () => controller.toggleSymptom(item['name']!),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFA6E3F9)
                                : const Color(0xFFFFDA7B)
                                    .withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4489D7)
                                  : Colors.black12,
                              width: 1.5,
                            ),
                          ),
                          child: Image.asset(
                            item['img']!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['name']!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => controller.saveDailyData(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C5282),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "บันทึก",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildStressContent(ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "ความเครียดและอารมณ์",
              style: GoogleFonts.mitr(
                textStyle: const TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Obx(() => DropdownButton<String>(
                  value:
                      controller.monthNames[controller.selectedMonth.value - 1],
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Color(0xFF757575)),
                  underline: const SizedBox(),
                  style: GoogleFonts.mitr(
                    textStyle: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onChanged: (val) => controller.changeMonth(val),
                  items: controller.monthNames
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m, style: GoogleFonts.mitr()),
                        ),
                      )
                      .toList(),
                )),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFCEEFFE).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"]
                    .map(
                      (day) => SizedBox(
                        width: 35,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF4489D7),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Obx(
                () => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.daysInMonth + controller.firstDayOffset,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.65,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 0,
                  ),
                  itemBuilder: (context, index) {
                    final day = index - controller.firstDayOffset + 1;
                    if (day < 1 || day > controller.daysInMonth) {
                      return const SizedBox();
                    }

                    return Obx(() {
                      final dayKey = controller.getDateKey(
                        controller.selectedYear.value,
                        controller.selectedMonth.value,
                        day,
                      );
                      final whaleImage = controller.getMaleHealthImage(day);
                      final isToday = controller.today.value == day &&
                          controller.selectedMonth.value ==
                              DateTime.now().month &&
                          controller.selectedYear.value == DateTime.now().year;
                      final isSelected = controller.selectedDate.value == day;
                      final hasRecord = controller.hasMaleHealthRecord(dayKey);

                      Color bgColor = Colors.transparent;
                      Color textColor = const Color(0xFF4489D7);

                      if (isSelected) {
                        bgColor = const Color(0xFFFFD348);
                      } else if (hasRecord) {
                        bgColor = const Color(0xFFFF5240);
                        textColor = Colors.white;
                      } else if (isToday) {
                        bgColor = const Color(0xFFCCCCCC);
                        textColor = const Color(0xFF2C5282);
                      }

                      return GestureDetector(
                        onTap: () => controller.selectDay(day),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: bgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "$day",
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (whaleImage != null)
                              const SizedBox(height: 4),
                            if (whaleImage != null)
                              Image.asset(
                                whaleImage,
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox(height: 32),
                              ),
                          ],
                        ),
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Text(
          "บันทึกอาการ",
          style: GoogleFonts.mitr(
            textStyle: const TextStyle(
              color: Color(0xFF4489D7),
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Obx(() {
          if (controller.selectedDate.value == 0) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDA7B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF757575),
                  width: 1.5,
                ),
              ),
              child: const Text(
                "กรุณาเลือกวันที่ต้องการ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5D4037),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusButton(
                    controller,
                    "มีความเครียด/ไม่สบาย",
                    const Color(0xFFA6E3F9),
                    true,
                  ),
                  const SizedBox(width: 15),
                  _buildStatusButton(
                    controller,
                    "ปกติ",
                    const Color(0xFFA6E3F9),
                    false,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 15,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: controller.maleSymptomsList.map((tag) {
                  final isSelected = controller
                      .getSymptomsForSelectedDay()
                      .contains(tag['name']);

                  return GestureDetector(
                    onTap: () => controller.toggleSymptom(tag['name']!),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFA6E3F9)
                                : const Color(0xFFFFDA7B)
                                    .withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4489D7)
                                  : Colors.black12,
                              width: 1.5,
                            ),
                          ),
                          child: Image.asset(
                            tag['img']!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tag['name']!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => controller.saveDailyData(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C5282),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "บันทึก",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildStatusButton(
    ProfileController controller,
    String title,
    Color activeColor,
    bool isPeriodTab,
  ) {
    return Obx(() {
      bool isSelected =
          controller.getPeriodStatusForSelectedDay() == isPeriodTab;
      return GestureDetector(
        onTap: () => controller.setPeriodStatus(isPeriodTab),
        child: Container(
          width: Get.width * 0.42,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF757575), width: 1.5),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF424242),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }
}

// // ==========================================
// // Widgets แยกย่อย
// // ==========================================

// // ─── [ใหม่] Flow Level Selector ──────────────────────────────────────────────
// class _FlowLevelSelector extends StatelessWidget {
//   final ProfileController controller;
//   const _FlowLevelSelector({required this.controller});

//   static const _levels = [
//     {
//       'value': 'spotting',
//       'label': 'Spotting',
//       'emoji': '🩷',
//       'desc': 'กระปิดกระปอย'
//     },
//     {'value': 'light', 'label': 'Light', 'emoji': '🩸', 'desc': 'น้อย'},
//     {'value': 'medium', 'label': 'Medium', 'emoji': '🩸🩸', 'desc': 'ปานกลาง'},
//     {'value': 'heavy', 'label': 'Heavy', 'emoji': '🩸🩸🩸', 'desc': 'มาก'},
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       final selected = controller.currentFlowLevel.value;
//       return Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: _levels.map((level) {
//           final isSelected = selected == level['value'];
//           return GestureDetector(
//             onTap: () => controller.currentFlowLevel.value = level['value'],
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               width: 75,
//               padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
//               decoration: BoxDecoration(
//                 color: isSelected ? const Color(0xFFF05A42) : Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(
//                   color: isSelected
//                       ? const Color(0xFFF05A42)
//                       : const Color(0xFFE0E0E0),
//                   width: 1.5,
//                 ),
//                 boxShadow: isSelected
//                     ? [
//                         BoxShadow(
//                             color:
//                                 const Color(0xFFF05A42).withValues(alpha: 0.3),
//                             blurRadius: 8)
//                       ]
//                     : [],
//               ),
//               child: Column(
//                 children: [
//                   Text(level['emoji']!, style: const TextStyle(fontSize: 18)),
//                   const SizedBox(height: 4),
//                   Text(
//                     level['desc']!,
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.bold,
//                       color:
//                           isSelected ? Colors.white : const Color(0xFF757575),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }).toList(),
//       );
//     });
//   }
// }

// // ─── [ใหม่] Pain Level Selector ──────────────────────────────────────────────
// class _PainLevelSelector extends StatelessWidget {
//   final ProfileController controller;
//   const _PainLevelSelector({required this.controller});

//   static const _painLabels = [
//     'แทบไม่เจ็บ',
//     'เล็กน้อย',
//     'พอทน',
//     'เจ็บมาก',
//     'ทนไม่ได้'
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       final selected = controller.currentPainLevel.value;
//       return Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: List.generate(5, (i) {
//               final level = i + 1;
//               final isSelected = selected == level;
//               return GestureDetector(
//                 onTap: () => controller.currentPainLevel.value = level,
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 180),
//                   width: 52,
//                   height: 52,
//                   decoration: BoxDecoration(
//                     color: isSelected ? _painColor(level) : Colors.white,
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: isSelected
//                           ? _painColor(level)
//                           : const Color(0xFFE0E0E0),
//                       width: 2,
//                     ),
//                     boxShadow: isSelected
//                         ? [
//                             BoxShadow(
//                                 color:
//                                     _painColor(level).withValues(alpha: 0.35),
//                                 blurRadius: 8)
//                           ]
//                         : [],
//                   ),
//                   alignment: Alignment.center,
//                   child: Text(
//                     '$level',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color:
//                           isSelected ? Colors.white : const Color(0xFF9E9E9E),
//                     ),
//                   ),
//                 ),
//               );
//             }),
//           ),
//           if (selected != null) ...[
//             const SizedBox(height: 8),
//             Text(
//               _painLabels[selected - 1],
//               style: TextStyle(
//                 color: _painColor(selected),
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//               ),
//             ),
//           ],
//         ],
//       );
//     });
//   }

//   Color _painColor(int level) {
//     const colors = [
//       Color(0xFF66BB6A), // 1 - เขียว
//       Color(0xFFFFEB3B), // 2 - เหลือง
//       Color(0xFFFF9800), // 3 - ส้ม
//       Color(0xFFF44336), // 4 - แดง
//       Color(0xFF880E4F), // 5 - แดงเข้มมาก
//     ];
//     return colors[level - 1];
//   }
// }

// // ─── [ใหม่] Confidence Badge ──────────────────────────────────────────────────
// class _ConfidenceBadge extends StatelessWidget {
//   final String confidence;
//   const _ConfidenceBadge({required this.confidence});

//   @override
//   Widget build(BuildContext context) {
//     final isHigh = confidence == 'high';
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//       decoration: BoxDecoration(
//         color: isHigh ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: isHigh ? const Color(0xFF66BB6A) : const Color(0xFFFF9800),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isHigh ? Icons.verified : Icons.info_outline,
//             size: 12,
//             color: isHigh ? const Color(0xFF66BB6A) : const Color(0xFFFF9800),
//           ),
//           const SizedBox(width: 4),
//           Text(
//             isHigh ? "แม่นยำสูง" : "ข้อมูลน้อย",
//             style: TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.bold,
//               color: isHigh ? const Color(0xFF388E3C) : const Color(0xFFE65100),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── [ใหม่] Menstrual Stats Card ─────────────────────────────────────────────
// class _MenstrualStatsCard extends StatelessWidget {
//   final ProfileController controller;
//   const _MenstrualStatsCard({required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       if (controller.statTotalCycles.value == 0) return const SizedBox();
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.05),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4))
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "สถิติรอบเดือนของคุณ",
//               style: GoogleFonts.mitr(
//                 textStyle: const TextStyle(
//                     color: Color(0xFF4489D7),
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500),
//               ),
//             ),
//             const SizedBox(height: 14),
//             Row(
//               children: [
//                 _StatItem(
//                   icon: Icons.loop,
//                   value: "${controller.statTotalCycles.value}",
//                   label: "รอบที่บันทึก",
//                   color: const Color(0xFF4489D7),
//                 ),
//                 _StatDivider(),
//                 _StatItem(
//                   icon: Icons.date_range,
//                   value: controller.statAvgCycleLength.value > 0
//                       ? "${controller.statAvgCycleLength.value} วัน"
//                       : "-",
//                   label: "รอบเฉลี่ย",
//                   color: const Color(0xFFF05A42),
//                 ),
//                 _StatDivider(),
//                 _StatItem(
//                   icon: Icons.water_drop,
//                   value: controller.statAvgPeriodDuration.value > 0
//                       ? "${controller.statAvgPeriodDuration.value} วัน"
//                       : "-",
//                   label: "ประจำเดือนเฉลี่ย",
//                   color: const Color(0xFFFF9800),
//                 ),
//               ],
//             ),
//             // อาการที่พบบ่อย
//             if (controller.statCommonSymptoms.isNotEmpty) ...[
//               const SizedBox(height: 12),
//               const Divider(color: Color(0xFFF0F0F0)),
//               const SizedBox(height: 8),
//               Text(
//                 "อาการที่พบบ่อย",
//                 style: GoogleFonts.mitr(
//                   textStyle:
//                       const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
//                 ),
//               ),
//               const SizedBox(height: 6),
//               Wrap(
//                 spacing: 8,
//                 children: controller.statCommonSymptoms.map((s) {
//                   return Chip(
//                     label: Text(s,
//                         style: const TextStyle(
//                             fontSize: 12, color: Color(0xFF5D4037))),
//                     backgroundColor: const Color(0xFFFFF8E1),
//                     side: const BorderSide(color: Color(0xFFFFD348)),
//                     padding: const EdgeInsets.symmetric(horizontal: 4),
//                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                   );
//                 }).toList(),
//               ),
//             ],
//           ],
//         ),
//       );
//     });
//   }
// }

// class _StatItem extends StatelessWidget {
//   final IconData icon;
//   final String value;
//   final String label;
//   final Color color;

//   const _StatItem({
//     required this.icon,
//     required this.value,
//     required this.label,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 22),
//           const SizedBox(height: 6),
//           Text(value,
//               style: TextStyle(
//                   color: color, fontWeight: FontWeight.bold, fontSize: 16)),
//           const SizedBox(height: 2),
//           Text(label,
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
//         ],
//       ),
//     );
//   }
// }

// class _StatDivider extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(width: 1, height: 50, color: const Color(0xFFF0F0F0));
//   }
// }

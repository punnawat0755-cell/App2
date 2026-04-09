import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/services/coin_service.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/features/home/service/daily_mission_streak_service.dart';
import 'package:flutter_application_1/features/profile/controller/profile_avatar_controller.dart';
import 'package:flutter_application_1/features/setting/view/setting_page.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// 1. Controller
// ==========================================
class ProfileController extends GetxController {
  static const int maxSymptomsPerDay = 3;

  final supabase = Supabase.instance.client;
  late final http.Client _httpClient;
  late final CoinService _coinService;
  late final DailyMissionStreakService _dailyMissionStreakService;
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

  RxInt get coins => _coinService.coins;
  final missionStreakDays = 0.obs;
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
  var draftSymptoms = <String, List<String>>{}.obs;
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
    _coinService = Get.isRegistered<CoinService>()
        ? Get.find<CoinService>()
        : Get.put(CoinService(), permanent: true);
    _dailyMissionStreakService = DailyMissionStreakService();
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

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime dateForDay(int day) =>
      DateTime(selectedYear.value, selectedMonth.value, day);

  bool isFutureDay(int day) => _dateOnly(dateForDay(day)).isAfter(
        _dateOnly(DateTime.now()),
      );

  bool get isSelectedDateInFuture {
    final day = selectedDate.value;
    if (day == 0) return false;
    return isFutureDay(day);
  }

  void _showFutureDateBlockedSnackbar() {
    Get.snackbar(
      "แจ้งเตือน",
      "ไม่สามารถบันทึกล่วงหน้าได้ (บันทึกได้เฉพาะวันนี้และย้อนหลัง)",
      backgroundColor: const Color(0xFF2C5282),
      colorText: Colors.white,
    );
  }

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
      _discardUnsavedSymptomChanges();
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
    if (selectedDate.value != day) {
      _discardUnsavedSymptomChanges();
    }
    selectedDate.value = day;
    _syncSelectedInputsForDate();
  }

  void _discardUnsavedSymptomChanges() {
    if (draftSymptoms.isNotEmpty) {
      draftSymptoms.clear();
      draftSymptoms.refresh();
    }
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

    await _loadMissionStreakDays();
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
    missionStreakDays.value = 0;

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
    draftSymptoms.clear();
    dailyMoodLevels.clear();
    dailyFlowLevel.clear();
    dailyPainLevel.clear();
    dailyNotes.clear();

    currentFlowLevel.value = null;
    currentPainLevel.value = null;
    currentNotes.value = "";
    notesController.clear();
  }

  Future<void> refreshProfile() async {
    _resetProfileState();
    await _bootstrapProfile();
  }

  Future<void> _loadMissionStreakDays() async {
    final streakDays = await _dailyMissionStreakService.getCurrentStreakDays();
    missionStreakDays.value = streakDays > 0 ? streakDays : 0;
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

          final isMenstruating = row['is_menstruating'];
          if (isMenstruating is bool) {
            dailyPeriodStatus[key] = isMenstruating;
          }

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
        _reconcilePredictedDaysWithRecordedStatus();
        return;
      }
    }

    final usedLocalFallback = _applyLocalOngoingPeriodFallback();
    if (usedLocalFallback) {
      _reconcilePredictedDaysWithRecordedStatus();
      return;
    }

    await _fetchPeriodPredictionFromSupabaseRpc();
    _reconcilePredictedDaysWithRecordedStatus();
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
      if (!_payloadHasExplicitPredictionWindow(payload)) {
        return false;
      }
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

  bool _isCurrentSelectedMonth() {
    final now = DateTime.now();
    return selectedYear.value == now.year && selectedMonth.value == now.month;
  }

  List<DateTime> _latestRecordedPeriodStreak() {
    final dates = dailyPeriodStatus.entries
        .where((entry) => entry.value == true)
        .map((entry) => _tryParseDate(entry.key))
        .whereType<DateTime>()
        .map(_dateOnly)
        .where((date) =>
            date.year == selectedYear.value &&
            date.month == selectedMonth.value)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    if (dates.isEmpty) return <DateTime>[];

    var currentStreak = <DateTime>[];
    var latestStreak = <DateTime>[];

    for (final date in dates) {
      if (currentStreak.isEmpty) {
        currentStreak = <DateTime>[date];
        continue;
      }

      if (date.difference(currentStreak.last).inDays == 1) {
        currentStreak.add(date);
        continue;
      }

      latestStreak = List<DateTime>.from(currentStreak);
      currentStreak = <DateTime>[date];
    }

    if (currentStreak.isNotEmpty) {
      latestStreak = List<DateTime>.from(currentStreak);
    }

    return latestStreak;
  }

  bool _hasExplicitNonPeriodAfterDate(DateTime date) {
    final target = _dateOnly(date);
    for (final entry in dailyPeriodStatus.entries) {
      if (entry.value != false) continue;

      final parsed = _tryParseDate(entry.key);
      if (parsed == null) continue;

      final day = _dateOnly(parsed);
      if (day.year != selectedYear.value || day.month != selectedMonth.value) {
        continue;
      }

      if (day.isAfter(target)) return true;
    }

    return false;
  }

  int _estimatedLocalPeriodDurationDays(int recordedDays) {
    final statsBased =
        statAvgPeriodDuration.value > 0 ? statAvgPeriodDuration.value : 5;
    final estimated = statsBased < recordedDays ? recordedDays : statsBased;
    return estimated.clamp(1, 10).toInt();
  }

  bool _applyLocalOngoingPeriodFallback() {
    if (!_isCurrentSelectedMonth()) return false;

    final streak = _latestRecordedPeriodStreak();
    if (streak.isEmpty) return false;

    final start = streak.first;
    final actualEnd = streak.last;
    if (_hasExplicitNonPeriodAfterDate(actualEnd)) return false;

    final durationDays = _estimatedLocalPeriodDurationDays(streak.length);
    final predictedEnd = start.add(Duration(days: durationDays - 1));
    if (!predictedEnd.isAfter(actualEnd)) return false;

    _replacePredictedDays(
      List.generate(durationDays, (index) => start.add(Duration(days: index))),
    );

    if (predictionConfidence.value.trim().isEmpty) {
      predictionConfidence.value = 'low';
    }
    _setPredictionTextFromEndDate(predictedEnd);
    debugPrint(
      'period prediction local fallback start=$start actualEnd=$actualEnd predictedEnd=$predictedEnd',
    );
    return true;
  }

  bool _payloadHasExplicitPredictionWindow(Map<String, dynamic> payload) {
    if (payload.isEmpty) return false;

    final directPredictedStart = _tryParseDate(_readValueIgnoreCase(payload, [
      'predicted_start_date',
      'predictedStartDate',
      'predicted_next_period',
      'predictedNextPeriod',
    ]));
    final directPredictedEnd = _tryParseDate(_readValueIgnoreCase(payload, [
      'predicted_end_date',
      'predictedEndDate',
      'period_end_date',
      'periodEndDate',
    ]));
    if (directPredictedStart != null || directPredictedEnd != null) {
      return true;
    }

    final predictionRaw = payload['prediction'];
    if (predictionRaw is Map || predictionRaw is Map<String, dynamic>) {
      final prediction = predictionRaw is Map<String, dynamic>
          ? predictionRaw
          : Map<String, dynamic>.from(predictionRaw as Map);
      final nestedPredictedEnd =
          _tryParseDate(_readValueIgnoreCase(prediction, [
        'predicted_end_date',
        'predictedEndDate',
      ]));
      if (nestedPredictedEnd != null) return true;
    }

    final predictedDaysValue = _readValueIgnoreCase(payload, [
      'predicted_period_days',
      'predicted_dates',
      'predictedDays',
      'period_days',
      'periodDays',
    ]);
    if (predictedDaysValue is List && predictedDaysValue.isNotEmpty) {
      return true;
    }
    if (predictedDaysValue is String && predictedDaysValue.trim().isNotEmpty) {
      return true;
    }

    bool hasSupportedEvents(dynamic eventsRaw) {
      if (eventsRaw is! List) return false;

      for (final eventRaw in eventsRaw) {
        Map<String, dynamic>? event;
        if (eventRaw is Map<String, dynamic>) {
          event = eventRaw;
        } else if (eventRaw is Map) {
          event = Map<String, dynamic>.from(eventRaw);
        }
        if (event == null) continue;

        final type = (event['type'] ?? '').toString().trim().toLowerCase();
        if (type == 'next_period_estimate' ||
            type == 'next_period' ||
            type == 'predicted_period' ||
            type == 'predicted_period_end') {
          return true;
        }
      }

      return false;
    }

    return hasSupportedEvents(payload['events']) ||
        hasSupportedEvents(payload['calendar_events']);
  }

  List<DateTime> _sortedPredictedDates() {
    final dates = predictedPeriodDays
        .map(_tryParseDate)
        .whereType<DateTime>()
        .map(_dateOnly)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));
    return dates;
  }

  void _replacePredictedDays(Iterable<DateTime> dates) {
    final nextKeys = dates
        .map((date) => getDateKey(date.year, date.month, date.day))
        .toSet();

    predictedPeriodDays
      ..clear()
      ..addAll(nextKeys);
    predictedPeriodDays.refresh();
  }

  bool _shiftPredictedDaysForwardIfNeeded() {
    final predictedDates = _sortedPredictedDates();
    if (predictedDates.isEmpty) return false;

    final hasRecordedPeriod = predictedDates.any((date) {
      final key = getDateKey(date.year, date.month, date.day);
      return dailyPeriodStatus[key] == true;
    });
    if (hasRecordedPeriod) return false;

    final todayDate = _dateOnly(DateTime.now());
    final originalStart = predictedDates.first;

    int shiftDays = 0;
    if (originalStart.isBefore(todayDate)) {
      shiftDays = todayDate.difference(originalStart).inDays;
    }

    while (true) {
      final shiftedStart = originalStart.add(Duration(days: shiftDays));
      final shiftedStartKey = getDateKey(
        shiftedStart.year,
        shiftedStart.month,
        shiftedStart.day,
      );
      if (!_hasExplicitNonPeriodRecord(shiftedStartKey)) break;
      shiftDays++;
    }

    if (shiftDays <= 0) return false;

    _replacePredictedDays(
      predictedDates.map((date) => date.add(Duration(days: shiftDays))),
    );
    return true;
  }

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

  void _reconcilePredictedDaysWithRecordedStatus() {
    if (predictedPeriodDays.isEmpty) return;

    final shifted = _shiftPredictedDaysForwardIfNeeded();
    _trimPredictedDaysByRecordedPeriodStatus();

    if (shifted && predictedPeriodDays.isNotEmpty) {
      final shiftedDates = _sortedPredictedDates();
      if (shiftedDates.isNotEmpty) {
        _setPredictionTextFromDate(shiftedDates.first);
      }
    }
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

  bool? getExplicitPeriodStatusForSelectedDay() {
    if (selectedDate.value == 0 || !dailyPeriodStatus.containsKey(dateKey)) {
      return null;
    }
    return dailyPeriodStatus[dateKey];
  }

  bool getPeriodStatusForSelectedDay() =>
      getExplicitPeriodStatusForSelectedDay() == true;

  List<String> getSymptomsForSelectedDay() {
    if (selectedDate.value == 0) return <String>[];
    if (draftSymptoms.containsKey(dateKey)) {
      return draftSymptoms[dateKey] ?? <String>[];
    }
    return dailySymptoms[dateKey] ?? <String>[];
  }

  void setPeriodStatus(bool status) {
    if (selectedDate.value == 0) return;
    if (isSelectedDateInFuture) {
      _showFutureDateBlockedSnackbar();
      return;
    }

    dailyPeriodStatus[dateKey] = status;
    dailyPeriodStatus.refresh();
    // ถ้าเปลี่ยนเป็น "ไม่เป็น" ให้ reset flow และ pain
    if (!status) {
      currentFlowLevel.value = null;
      currentPainLevel.value = null;
    }
  }

  void toggleSymptom(String symptomName) {
    if (selectedDate.value == 0) return;
    if (isSelectedDateInFuture) {
      _showFutureDateBlockedSnackbar();
      return;
    }
    List<String> currentList = List.from(getSymptomsForSelectedDay());
    if (currentList.contains(symptomName)) {
      currentList.remove(symptomName);
    } else {
      if (currentList.length >= maxSymptomsPerDay) {
        Get.snackbar(
          "แจ้งเตือน",
          "เลือกอาการได้ไม่เกิน $maxSymptomsPerDay รายการต่อวัน",
          backgroundColor: const Color(0xFF2C5282),
          colorText: Colors.white,
        );
        return;
      }
      currentList.add(symptomName);
    }
    draftSymptoms[dateKey] = currentList;
    draftSymptoms.refresh();
  }

  Future<bool> saveDailyData({bool showSuccessSnackbar = true}) async {
    if (selectedDate.value == 0) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกวันที่ต้องการ",
        backgroundColor: const Color(0xFF2C5282),
        colorText: Colors.white,
      );
      return false;
    }

    if (isSelectedDateInFuture) {
      _showFutureDateBlockedSnackbar();
      return false;
    }

    final selectedSymptoms = getSymptomsForSelectedDay();
    if (selectedSymptoms.length > maxSymptomsPerDay) {
      Get.snackbar(
        "แจ้งเตือน",
        "เลือกอาการได้ไม่เกิน $maxSymptomsPerDay รายการต่อวัน",
        backgroundColor: const Color(0xFF2C5282),
        colorText: Colors.white,
      );
      return false;
    }

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      Get.snackbar("ข้อผิดพลาด", "กรุณาเข้าสู่ระบบก่อน",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }

    try {
      final hasExplicitPeriodStatus = dailyPeriodStatus.containsKey(dateKey);
      final bool? isPeriod =
          hasExplicitPeriodStatus ? dailyPeriodStatus[dateKey] : null;
      await supabase.rpc(
        'save_calendar_health_log',
        params: {
          'p_log_date': dateKey,
          'p_is_menstruating': isPeriod,
          'p_symptoms': selectedSymptoms,
          // [ใหม่] ส่งค่าใหม่ทั้งหมด (null ถ้าไม่เป็นประจำเดือน)
          'p_flow_level': isFemaleAccount && isPeriod == true
              ? currentFlowLevel.value
              : null,
          'p_pain_level': isFemaleAccount && isPeriod == true
              ? currentPainLevel.value
              : null,
          'p_notes': notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        },
      );

      // อัปเดต local state
      if (selectedSymptoms.isEmpty) {
        dailySymptoms.remove(dateKey);
      } else {
        dailySymptoms[dateKey] = List<String>.from(selectedSymptoms);
      }
      draftSymptoms.remove(dateKey);
      dailySymptoms.refresh();
      draftSymptoms.refresh();
      dailyFlowLevel[dateKey] =
          isPeriod == true ? currentFlowLevel.value : null;
      dailyPainLevel[dateKey] =
          isPeriod == true ? currentPainLevel.value : null;
      dailyNotes[dateKey] = notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim();

      if (showSuccessSnackbar) {
        Get.snackbar(
          "สำเร็จ ✨",
          "บันทึกข้อมูลวันที่ ${selectedDate.value} เรียบร้อยแล้ว",
          backgroundColor: const Color(0xFF2C5282),
          colorText: Colors.white,
        );
      }

      if (isFemaleAccount) {
        fetchPeriodPrediction();
        fetchLatestCycle();
        fetchMenstrualStats(); // [ใหม่] รีเฟรชสถิติ
      } else {
        await loadMonthData();
      }
      return true;
    } catch (e) {
      Get.snackbar("เกิดข้อผิดพลาด", "ไม่สามารถบันทึกข้อมูลได้: $e",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
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

  List<Map<String, String>> get maleSymptomsList => symptomsList;
}

// ==========================================
// 2. ProfilePage
// ==========================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const List<_PeriodCareSectionData> _periodCareSections = [
    _PeriodCareSectionData(
      symptomKey: 'ปวดท้อง',
      title: 'ปวดท้อง',
      tips: [
        'ประคบร้อน: ใช้กระเป๋าน้ำร้อนหรือแผ่นแปะแก้ปวดท้อง วางบริเวณท้องน้อยความร้อนจะช่วยให้กล้ามเนื้อมดลูกที่หดตัวอยู่คลายตัวลง และเพิ่มการไหลเวียนเลือด',
        'ยาแก้ปวด: กลุ่ม NSAIDs: เช่น Ibuprofen หรือ Mefenamic acid (พอนสแตน) จะช่วยยับยั้งสาร Prostaglandins ที่ทำให้มดลูกบีบตัว ได้ดีกว่าพาราเซตามอลปกติ (ควรทานหลังอาหารทันทีเพราะกัดกระเพาะ)',
        'ยาคลายกล้ามเนื้อมดลูก: เช่น Buscopan ช่วยลดการเกร็งปวดได้ตรงจุด',
        'จิบน้ำอุ่น: หลีกเลี่ยงน้ำเย็นจัดเพราะน้ำอุ่นช่วยให้เลือดไหลเวียนดีขึ้นและลดการเกร็งของกล้ามเนื้อ',
        'เลี่ยงคาเฟอีน: ชา กาแฟ หรือน้ำอัดลมที่มีคาเฟอีน จะทำให้หลอดเลือดหดตัวและอาจกระตุ้นให้ปวดท้องมากขึ้น รวมถึงทำให้หงุดหงิดง่ายขึ้นด้วย',
      ],
    ),
    _PeriodCareSectionData(
      symptomKey: 'แปรปรวน',
      title: 'อารมณ์แปรปรวน',
      tips: [
        'กินแป้งเชิงซ้อน (Complex Carbs): เช่น ข้าวกล้อง ขนมปังโฮลวีต ช่วยให้ระดับน้ำตาลในเลือดนิ่ง และช่วยเพิ่มการผลิต Serotonin ทำให้ใจนิ่งขึ้น',
        'ลดน้ำตาลและคาเฟอีน: น้ำตาลทำให้สะใจแค่แป๊บเดียวแต่จะทำให้ "ดิ่ง" หนักกว่าเดิมตอนน้ำตาลตก ส่วนคาเฟอีนจะกระตุ้นความกระวนกระวาย และทำให้นอนไม่หลับ ซึ่งยิ่งทำให้อารมณ์พัง',
      ],
    ),
    _PeriodCareSectionData(
      symptomKey: 'ท้องอืด',
      title: 'ท้องอืด',
      tips: [
        'ขยับร่างกายเบาๆ: การเดินเล่นสัก 10-15 นาที ช่วยกระตุ้นให้ลำไส้เคลื่อนตัวและขับลมออกมาได้ดีขึ้นมากครับ',
        'เลี่ยงผักตระกูลกะหล่ำ: เช่น บรอกโคลี กะหล่ำปลี เพราะมีน้ำตาลที่ย่อยยากและทำให้เกิดแก๊สเยอะ',
        'ลดอาหารรสจัดและของเค็ม: โซเดียมจะทำให้ร่างกายกักเก็บน้ำไว้มากขึ้น ยิ่งทำให้รู้สึกตัวบวมและท้องอืดหนักกว่าเดิม',
      ],
    ),
    _PeriodCareSectionData(
      symptomKey: 'ปวดหัวไมเกรน',
      title: 'ปวดหัวไมเกรน',
      tips: [
        'หา "ที่มืดและเงียบ": สมองช่วงไมเกรนจะไวต่อสิ่งเร้ามาก การปิดไฟ นอนพักในห้องเงียบๆ สัก 20 นาทีช่วยได้มหาศาล',
        'ประคบเย็น: ใช้เจลเย็นหรือผ้าชุบน้ำเย็นจัดประคบที่ท้ายทอยหรือขมับ ความเย็นจะช่วยให้หลอดเลือดที่ขยายตัวเกินไป (สาเหตุของไมเกรน) หดตัวลง',
        'ยาแก้ปวด (ต้องไว): ไมเกรนต้องดักด้วยยาตั้งแต่ "เริ่มรู้สึกจี๊ด" ถ้าปล่อยให้ปวดจนคลื่นไส้ ยาจะดูดซึมได้ยากขึ้น (ยาเฉพาะกลุ่ม Triptans หรือยาพื้นฐานอย่าง Naproxen/Ibuprofen)',
        'จิบน้ำเปล่าเยอะๆ: ร่างกายที่ขาดน้ำ (Dehydration) คือตัวกระตุ้นไมเกรนชั้นดี',
      ],
    ),
    _PeriodCareSectionData(
      symptomKey: 'หงุดหงิด',
      title: 'หงุดหงิด',
      tips: [
        'Box Breathing: หายใจเข้า 4 วินาที, กลั้น 4 วินาที, ออก 4 วินาที, กลั้น 4 วินาที ทำวนไป 3-4 รอบ เพื่อลดการทำงานของระบบประสาท Sympathetic ที่ทำให้เรารู้สึก "อยากปะทะ"',
        'ลดสิ่งเร้า: ปิดเสียงแจ้งเตือน หรือใส่หูฟังตัดเสียงรบกวน (Noise Cancelling) เพื่อลดภาระของสมองในการรับข้อมูล',
      ],
    ),
    _PeriodCareSectionData(
      symptomKey: 'เป็นไข้',
      title: 'เป็นไข้',
      tips: [
        'เช็ดตัว: ใช้ผ้าชุบน้ำอุณหภูมิห้องเช็ดตามข้อพับเพื่อระบายความร้อน',
        'ดื่มน้ำเยอะๆ: ไข้ทำให้ร่างกายเสียน้ำง่าย การดื่มน้ำช่วยลดอุณหภูมิและช่วยให้ระบบภูมิคุ้มกันทำงานดีขึ้น',
        'พักผ่อนแบบ 100%: หยุดกิจกรรมทุกอย่าง เพราะร่างกายต้องใช้พลังงานทั้งหมดไปกับการซ่อมแซม',
      ],
    ),
    _PeriodCareSectionData(
      symptomKey: 'หิวบ่อย',
      title: 'หิวบ่อย',
      tips: [
        'เน้นโปรตีนและใยอาหาร: กินไข่ต้ม ถั่ว หรือผัก เพื่อให้อิ่มนานขึ้นและน้ำตาลในเลือดนิ่ง',
        'จิบน้ำก่อนกิน: บางครั้งสมองแยกไม่ออกระหว่าง "หิวน้ำ" กับ "หิวข้าว" ลองดื่มน้ำดูก่อน 1 แก้ว',
        'ดาร์กช็อกโกแลต: ถ้าอยากของหวาน ให้เลือกอันที่มีโกโก้สูงๆ จะช่วยลดความอยากได้ดีกว่าขนมหวานจัดๆ',
      ],
    ),
    _PeriodCareSectionData(
      symptomKey: 'สิวขึ้น',
      title: 'สิวขึ้น',
      tips: [
        'งดสัมผัสใบหน้า: มือเราสกปรกกว่าที่คิด ยิ่งจับยิ่งอักเสบ',
        'ล้างปลอกหมอน: ถ้าสิวขึ้นซ้ำซาก ลองเช็กความสะอาดของที่นอน',
        'ลดนมและน้ำตาล: งานวิจัยหลายฉบับชี้ว่านมวัวและของหวานกระตุ้นการอักเสบของผิว',
      ],
    ),
  ];

  static const Map<String, List<String>> _symptomAdviceFemale = {
    'ปวดท้อง': [
      'ประคบร้อน: ใช้กระเป๋าน้ำร้อนหรือแผ่นแปะลดปวดท้องบริเวณท้องน้อย',
      'ยาแก้ปวดกลุ่ม NSAIDs ตามคำแนะนำแพทย์หรือฉลากยา เพื่อบรรเทาปวดเกร็ง',
      'ดื่มน้ำอุ่น และหลีกเลี่ยงน้ำเย็นจัด',
      'เลี่ยงคาเฟอีน ชา หรือแอลกอฮอล์ที่อาจกระตุ้นอาการปวดเพิ่ม',
    ],
    'แปรปรวน': [
      'กินอาหารเชิงซ้อน เช่น ข้าวกล้องหรือธัญพืช เพื่อให้พลังงานคงที่',
      'ลดน้ำตาลและคาเฟอีน หากทำให้อารมณ์แปรปรวนหรือนอนไม่หลับ',
      'พักผ่อนให้พอ และทำกิจกรรมเบาๆ เช่น เดินหรือยืดเหยียด',
    ],
    'หงุดหงิด': [
      'Box breathing: หายใจเข้า 4 กลั้น 4 ออก 4 กลั้น 4 ทำ 3-4 รอบ',
      'ลดสิ่งเร้า เช่น ปิดเสียงแจ้งเตือนหรือพักจากหน้าจอชั่วคราว',
    ],
    'ท้องอืด': [
      'ขยับร่างกายเบาๆ เช่น เดินเล่น 10-15 นาที',
      'เลี่ยงอาหารก่อแก๊ส เช่น บรอกโคลี กะหล่ำปลี หรือถั่วบางชนิด',
      'ลดอาหารรสจัดและของเค็มเพื่อลดบวมน้ำ',
    ],
    'ปวดหัวไมเกรน': [
      'อยู่ในที่เงียบหรือแสงน้อย และประคบเย็นบริเวณหน้าผากหรือขมับ',
      'พักสายตาและนอนให้พอ',
      'ดื่มน้ำให้เพียงพอเพื่อลดภาวะขาดน้ำที่กระตุ้นไมเกรน',
    ],
    'เป็นไข้': [
      'เช็ดตัวด้วยน้ำอุณหภูมิห้องบริเวณข้อพับเพื่อระบายความร้อน',
      'ดื่มน้ำเยอะๆ เพื่อชดเชยการสูญเสียน้ำ',
      'พักผ่อนให้เต็มที่ เพราะร่างกายต้องใช้พลังงานในการฟื้นตัว',
    ],
    'หิวบ่อย': [
      'เน้นโปรตีนและใยอาหารเพื่อให้อิ่มนานขึ้น',
      'ลองดื่มน้ำก่อนกิน 1 แก้ว เผื่อร่างกายกำลังหิวน้ำ',
      'ถ้าอยากของหวาน ลองเลือกดาร์กช็อกโกแลตแทนขนมหวานจัด',
    ],
    'สิวขึ้น': [
      'หลีกเลี่ยงการสัมผัสหรือแกะสิว',
      'เปลี่ยนปลอกหมอนสม่ำเสมอ',
      'ลดนมและน้ำตาลถ้าสังเกตว่ากระตุ้นการอักเสบของผิว',
    ],
  };

  static const Map<String, List<String>> _symptomAdviceMale = {
    'เครียด': [
      'เปลี่ยนสภาพแวดล้อมสักครู่ เดินออกจากโต๊ะทำงานหรือไปเจอแดดอ่อนๆ',
      'หายใจแบบ Box breathing เพื่อลดความตึงของระบบประสาท',
      'พักจากโซเชียลหรือสิ่งเร้าที่ทำให้คิดวนชั่วคราว',
    ],
    'นอนไม่หลับ': [
      'ลดคาเฟอีนช่วงบ่ายและเย็น',
      'งดเล่นมือถือก่อนนอน และลดแสงในห้องให้มากขึ้น',
      'ถ้ายังไม่ง่วง ลองลุกไปทำกิจกรรมเบาๆ แล้วค่อยกลับมานอน',
    ],
    'ปวดหัว': [
      'พักในที่เงียบหรือแสงน้อย และประคบเย็นบริเวณหน้าผาก',
      'ดื่มน้ำเพิ่ม เพราะอาการปวดหัวอาจสัมพันธ์กับการขาดน้ำ',
      'พักสายตาจากหน้าจอ และยืดคอหรือบ่าเบาๆ',
    ],
    'อ่อนเพลีย': [
      'พักผ่อนให้พอ และอย่าฝืนใช้งานร่างกายหนักเกินไป',
      'กินมื้อที่มีโปรตีนและคาร์บเชิงซ้อนเพื่อเติมพลังงาน',
      'ถ้าเพลียร่วมกับมีไข้หรือเป็นนานผิดปกติ ควรเฝ้าดูอาการใกล้ชิด',
    ],
    'ปวดเมื่อย': [
      'ยืดเหยียดกล้ามเนื้อเบาๆ หรืออาบน้ำอุ่นเพื่อลดอาการเกร็ง',
      'หลีกเลี่ยงท่าเดิมนานเกินไป และขยับร่างกายระหว่างวัน',
      'พักการออกกำลังกายหนักถ้ากล้ามเนื้อยังล้าอยู่',
    ],
    'เป็นไข้': [
      'เช็ดตัวด้วยน้ำอุณหภูมิห้องบริเวณข้อพับเพื่อระบายความร้อน',
      'ดื่มน้ำมากขึ้นเพื่อลดการขาดน้ำ',
      'พักผ่อนให้เต็มที่ หากอาการหนักขึ้นควรพบแพทย์',
    ],
    'เวียนหัว': [
      'นั่งพักและเปลี่ยนท่าช้าๆ อย่าลุกเร็ว',
      'จิบน้ำหรือเกลือแร่ หากก่อนหน้านี้กินน้ำน้อย',
      'ถ้าเวียนหัวร่วมกับใจสั่นหรือเป็นบ่อย ควรติดตามอาการต่อ',
    ],
    'เบื่ออาหาร': [
      'เริ่มจากอาหารอ่อนหรือมื้อเล็กๆ ก่อน',
      'ดื่มน้ำให้พอ แต่ไม่ต้องฝืนกินทีละมาก',
      'ถ้ามีอาการร่วมเช่นไข้ คลื่นไส้ หรือกินได้น้อยหลายวัน ควรเฝ้าดูเพิ่ม',
    ],
  };

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
            final horizontalPadding = constraints.maxWidth < 360
                ? scale.rs(12, min: 10, max: 14)
                : scale.rs(20, min: 14, max: 20);

            return Obx(() {
              if (!controller.isProfileReady.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: scale.rs(20, min: 14, max: 20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(
                          controller,
                          avatarController,
                          scale,
                        ),
                        SizedBox(height: scale.rs(25, min: 18, max: 25)),
                        if (controller.showsStressMenu)
                          _buildStressContent(
                            context,
                            controller,
                            scale,
                          )
                        else
                          _buildMenstrualContent(
                            context,
                            controller,
                            scale,
                          ),
                        SizedBox(height: scale.rs(40, min: 28, max: 40)),
                      ],
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Future<void> _handleMenstrualSave(ProfileController controller) async {
    final selectedSections = _selectedPeriodCareSections(controller);
    final selectedSymptoms = controller.getSymptomsForSelectedDay();
    final shouldShowPeriodCareDialog =
        controller.getPeriodStatusForSelectedDay() &&
            selectedSections.isNotEmpty;
    final saved = await controller.saveDailyData(
      showSuccessSnackbar: !shouldShowPeriodCareDialog,
    );

    if (saved && shouldShowPeriodCareDialog) {
      await _showPeriodCareDialog(selectedSections);
      return;
    }

    if (saved &&
        !controller.getPeriodStatusForSelectedDay() &&
        selectedSymptoms.isNotEmpty) {
      await _showSymptomAdviceDialog(
        title: 'แนะนำวิธีการดูแลตัวเอง',
        sections: _buildAdviceSections(
          selectedSymptoms,
          _symptomAdviceFemale,
        ),
      );
    }
  }

  Future<void> _handleMaleSave(ProfileController controller) async {
    if (controller.selectedDate.value == 0) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกวันที่ต้องการ",
        backgroundColor: const Color(0xFF2C5282),
        colorText: Colors.white,
      );
      return;
    }

    final saved = await controller.saveDailyData(showSuccessSnackbar: false);
    if (!saved) return;

    final selectedSymptoms = controller.getSymptomsForSelectedDay();
    if (selectedSymptoms.isNotEmpty) {
      await _showSymptomAdviceDialog(
        title: 'แนะนำวิธีการดูแลตัวเอง',
        sections: _buildAdviceSections(
          selectedSymptoms,
          _symptomAdviceMale,
        ),
      );
      return;
    }

    Get.snackbar(
      "สำเร็จ",
      "บันทึกเรียบร้อย",
      backgroundColor: const Color(0xFF2C5282),
      colorText: Colors.white,
    );
  }

  List<_PeriodCareSectionData> _selectedPeriodCareSections(
    ProfileController controller,
  ) {
    final selectedSymptoms = controller.getSymptomsForSelectedDay().toSet();
    return _periodCareSections
        .where((section) => selectedSymptoms.contains(section.symptomKey))
        .toList();
  }

  List<MapEntry<String, List<String>>> _buildAdviceSections(
    List<String> selectedSymptoms,
    Map<String, List<String>> dataSource,
  ) {
    return selectedSymptoms
        .toSet()
        .map((name) => MapEntry(name, dataSource[name] ?? const <String>[]))
        .where((entry) => entry.value.isNotEmpty)
        .toList();
  }

  Future<void> _showPeriodCareDialog(
    List<_PeriodCareSectionData> sections,
  ) {
    return Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: Get.height * 0.9,
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFABE7F8),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'แนะนำวิธีการดูแลตัวเองช่วงเป็นประจำเดือน',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mitr(
                      textStyle: const TextStyle(
                        color: Color(0xFF4489D7),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              sections.map(_buildPeriodCareSection).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 110,
                    height: 42,
                    child: FilledButton(
                      onPressed: () => Get.back<void>(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5ECAF4),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        'ปิด',
                        style: GoogleFonts.mitr(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildPeriodCareSection(_PeriodCareSectionData section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: GoogleFonts.mitr(
              textStyle: const TextStyle(
                color: Color(0xFF4489D7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...section.tips.map(_buildPeriodCareTip),
        ],
      ),
    );
  }

  Future<void> _showSymptomAdviceDialog({
    required String title,
    required List<MapEntry<String, List<String>>> sections,
  }) {
    if (sections.isEmpty) {
      Get.snackbar(
        'สำเร็จ',
        'บันทึกเรียบร้อย',
        backgroundColor: const Color(0xFF2C5282),
        colorText: Colors.white,
      );
      return Future.value();
    }

    return Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFCEEFFE),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: Get.height * 0.55,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in sections) ...[
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Color(0xFF4489D7),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final bullet in entry.value)
                          _buildAdviceItem(bullet),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.back<void>(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20C2FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'ปิด',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdviceItem(String text) {
    final normalized = text.replaceFirst(RegExp(r'^\s*[-•]\s*'), '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              '•',
              style: TextStyle(
                color: Color(0xFF4489D7),
                fontSize: 16,
                height: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              normalized,
              style: const TextStyle(
                color: Color(0xFF5D4037),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCareTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7, right: 8),
            child: Icon(
              Icons.circle,
              size: 5,
              color: Color(0xFF4B94E9),
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.mitr(
                textStyle: const TextStyle(
                  color: Color(0xFF4B94E9),
                  fontSize: 16,
                  height: 1.28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ProfileController controller,
    ProfileAvatarController avatarController,
    ResponsiveScale scale,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: scale.rs(10, min: 8, max: 10),
            vertical: scale.rs(6, min: 4, max: 6),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDA7B),
            borderRadius: BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/k1.png',
                width: scale.rs(35, min: 28, max: 35),
                height: scale.rs(30, min: 24, max: 30),
              ),
              SizedBox(width: scale.rs(1, min: 1, max: 2)),
              Obx(() => Text(
                    "${controller.missionStreakDays}",
                    style: TextStyle(
                      color: const Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                      fontSize: scale.rf(16, min: 13.5, max: 16),
                    ),
                  )),
            ],
          ),
        ),
        GestureDetector(
          onTap: () async {
            await Get.to(() => const SettingPage());
            await controller.refreshProfile();
          },
          child: Obx(
            () => CircleAvatar(
              radius: scale.rs(25, min: 20, max: 25),
              backgroundImage: avatarController.avatarImageProvider,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenstrualContent(
    BuildContext context,
    ProfileController controller,
    ResponsiveScale scale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "ความเครียดและอารมณ์",
              style: GoogleFonts.mitr(
                textStyle: TextStyle(
                  color: const Color(0xFF4489D7),
                  fontSize: scale.rf(22, min: 19, max: 22),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _buildMonthDropdownButton(controller, scale),
          ],
        ),
        SizedBox(height: scale.rs(15, min: 12, max: 15)),
        Container(
          padding: EdgeInsets.all(scale.rs(16, min: 12, max: 16)),
          decoration: BoxDecoration(
            color: const Color(0xFFCEEFFE).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(scale.rs(25, min: 20, max: 25)),
            border: Border.all(
              color: const Color(0xFF90CAF9),
              width: scale.rs(1.5, min: 1.2, max: 1.5),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"]
                    .map(
                      (day) => SizedBox(
                        width: scale.rs(35, min: 28, max: 35),
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF4489D7),
                            fontWeight: FontWeight.w300,
                            fontSize: scale.rf(16, min: 13.5, max: 16),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: scale.rs(10, min: 8, max: 10)),
              Obx(
                () => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.daysInMonth + controller.firstDayOffset,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: scale.isCompact ? 0.72 : 0.67,
                    mainAxisSpacing: scale.rs(5, min: 3, max: 5),
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
                      final isFutureDay = controller.isFutureDay(day);
                      final isPeriodDay =
                          controller.dailyPeriodStatus[dayKey] ?? false;
                      final isPredictedDay =
                          controller.predictedPeriodDays.contains(dayKey);
                      final hasSymptoms =
                          (controller.dailySymptoms[dayKey]?.isNotEmpty ??
                              false);

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

                      if (isFutureDay && !isSelected) {
                        bgColor = bgColor.withValues(
                          alpha: bgColor == Colors.transparent ? 0.0 : 0.35,
                        );
                        textColor = textColor.withValues(alpha: 0.4);
                      }

                      return GestureDetector(
                        onTap: () => controller.selectDay(day),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          children: [
                            Container(
                              width: scale.rs(34, min: 28, max: 34),
                              height: scale.rs(34, min: 28, max: 34),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: bgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "$day",
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          scale.rf(16, min: 13.5, max: 16),
                                      height: 1,
                                    ),
                                  ),
                                  if (hasSymptoms) ...[
                                    const SizedBox(height: 0),
                                    Transform.translate(
                                      offset: const Offset(0, 1),
                                      child: Container(
                                        width: scale.rs(16, min: 12, max: 16),
                                        height: 2,
                                        decoration: BoxDecoration(
                                          color: textColor,
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (whaleImage != null)
                              SizedBox(height: scale.rs(2, min: 1, max: 2)),
                            if (whaleImage != null)
                              Image.asset(
                                whaleImage,
                                width: scale.rs(32, min: 32, max: 40),
                                height: scale.rs(32, min: 32, max: 40),
                                fit: BoxFit.contain,
                                color: isFutureDay && !isSelected
                                    ? Colors.white.withValues(alpha: 0.55)
                                    : null,
                                colorBlendMode: isFutureDay && !isSelected
                                    ? BlendMode.modulate
                                    : null,
                                errorBuilder: (_, __, ___) => SizedBox(
                                    height: scale.rs(40, min: 32, max: 40)),
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
        SizedBox(height: scale.rs(25, min: 18, max: 25)),
        Text(
          "บันทึกอาการ",
          style: GoogleFonts.mitr(
            textStyle: TextStyle(
              color: const Color(0xFF4489D7),
              fontSize: scale.rf(22, min: 19, max: 22),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: scale.rs(20, min: 14, max: 20)),
        Obx(() {
          if (controller.selectedDate.value == 0) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: scale.rs(10, min: 8, max: 10),
                horizontal: scale.rs(10, min: 8, max: 10),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDA7B),
                borderRadius:
                    BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
                border: Border.all(
                  color: const Color(0xFF757575),
                  width: scale.rs(1.5, min: 1.2, max: 1.5),
                ),
              ),
              child: Text(
                "กรุณาเลือกวันที่ต้องการ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF5D4037),
                  fontSize: scale.rf(16, min: 13.5, max: 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          if (controller.isSelectedDateInFuture) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: scale.rs(10, min: 8, max: 10),
                horizontal: scale.rs(10, min: 8, max: 10),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDA7B),
                borderRadius:
                    BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
                border: Border.all(
                  color: const Color(0xFF757575),
                  width: scale.rs(1.5, min: 1.2, max: 1.5),
                ),
              ),
              child: Text(
                "ไม่สามารถบันทึกล่วงหน้าได้ (บันทึกได้เฉพาะวันนี้และย้อนหลัง)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF5D4037),
                  fontSize: scale.rf(16, min: 13.5, max: 16),
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
                    context,
                    controller,
                    "เป็นประจำเดือน",
                    const Color(0xFFA6E3F9),
                    true,
                    scale,
                  ),
                  SizedBox(width: scale.rs(15, min: 10, max: 15)),
                  _buildStatusButton(
                    context,
                    controller,
                    "ไม่เป็นประจำเดือน",
                    const Color(0xFFA6E3F9),
                    false,
                    scale,
                  ),
                ],
              ),
              SizedBox(height: scale.rs(30, min: 20, max: 30)),
              Wrap(
                spacing: 15,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: controller.symptomsList.map((item) {
                  final isSelected = controller
                      .getSymptomsForSelectedDay()
                      .contains(item['name']);
                  return _buildSymptomButton(
                    name: item['name']!,
                    imagePath: item['img']!,
                    isSelected: isSelected,
                    onTap: () => controller.toggleSymptom(item['name']!),
                  );
                }).toList(),
              ),
              SizedBox(height: scale.rs(25, min: 18, max: 25)),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _handleMenstrualSave(controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20C2FF),
                    padding: EdgeInsets.symmetric(
                      horizontal: scale.rs(18, min: 14, max: 18),
                      vertical: scale.rs(10, min: 8, max: 10),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
                    ),
                  ),
                  child: Text(
                    "บันทึก",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: scale.rf(14, min: 12.5, max: 14),
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

  Widget _buildStressContent(
    BuildContext context,
    ProfileController controller,
    ResponsiveScale scale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "ความเครียดและอารมณ์",
              style: GoogleFonts.mitr(
                textStyle: TextStyle(
                  color: const Color(0xFF4489D7),
                  fontSize: scale.rf(22, min: 19, max: 22),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _buildMonthDropdownButton(controller, scale),
          ],
        ),
        SizedBox(height: scale.rs(15, min: 12, max: 15)),
        Container(
          padding: EdgeInsets.all(scale.rs(16, min: 12, max: 16)),
          decoration: BoxDecoration(
            color: const Color(0xFFCEEFFE).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(scale.rs(25, min: 20, max: 25)),
            border: Border.all(
              color: const Color(0xFF90CAF9),
              width: scale.rs(1.5, min: 1.2, max: 1.5),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"]
                    .map(
                      (day) => SizedBox(
                        width: scale.rs(35, min: 28, max: 35),
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF4489D7),
                            fontWeight: FontWeight.bold,
                            fontSize: scale.rf(16, min: 13.5, max: 16),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: scale.rs(10, min: 8, max: 10)),
              Obx(
                () => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.daysInMonth + controller.firstDayOffset,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: scale.isCompact ? 0.72 : 0.67,
                    mainAxisSpacing: scale.rs(5, min: 3, max: 5),
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
                      final isFutureDay = controller.isFutureDay(day);
                      final hasRecord = controller.hasMaleHealthRecord(dayKey);
                      final hasSymptoms =
                          (controller.dailySymptoms[dayKey]?.isNotEmpty ??
                              false);

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

                      if (isFutureDay && !isSelected) {
                        bgColor = bgColor.withValues(
                          alpha: bgColor == Colors.transparent ? 0.0 : 0.35,
                        );
                        textColor = textColor.withValues(alpha: 0.4);
                      }

                      return GestureDetector(
                        onTap: () => controller.selectDay(day),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          children: [
                            Container(
                              width: scale.rs(34, min: 28, max: 34),
                              height: scale.rs(34, min: 28, max: 34),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: bgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "$day",
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          scale.rf(16, min: 13.5, max: 16),
                                      height: 1,
                                    ),
                                  ),
                                  if (hasSymptoms) ...[
                                    const SizedBox(height: 0),
                                    Transform.translate(
                                      offset: const Offset(0, -1.5),
                                      child: Container(
                                        width: scale.rs(16, min: 12, max: 16),
                                        height: 2,
                                        decoration: BoxDecoration(
                                          color: textColor,
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (whaleImage != null)
                              SizedBox(height: scale.rs(2, min: 1, max: 2)),
                            if (whaleImage != null)
                              Image.asset(
                                whaleImage,
                                width: scale.rs(32, min: 32, max: 40),
                                height: scale.rs(32, min: 32, max: 40),
                                fit: BoxFit.contain,
                                color: isFutureDay && !isSelected
                                    ? Colors.white.withValues(alpha: 0.55)
                                    : null,
                                colorBlendMode: isFutureDay && !isSelected
                                    ? BlendMode.modulate
                                    : null,
                                errorBuilder: (_, __, ___) => SizedBox(
                                    height: scale.rs(40, min: 32, max: 40)),
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
        SizedBox(height: scale.rs(25, min: 18, max: 25)),
        Text(
          "บันทึกอาการ",
          style: GoogleFonts.mitr(
            textStyle: TextStyle(
              color: const Color(0xFF4489D7),
              fontSize: scale.rf(22, min: 19, max: 22),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: scale.rs(20, min: 14, max: 20)),
        Obx(() {
          if (controller.selectedDate.value == 0) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: scale.rs(10, min: 8, max: 10),
                horizontal: scale.rs(10, min: 8, max: 10),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDA7B),
                borderRadius:
                    BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
                border: Border.all(
                  color: const Color(0xFF757575),
                  width: scale.rs(1.5, min: 1.2, max: 1.5),
                ),
              ),
              child: Text(
                "กรุณาเลือกวันที่ต้องการ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF5D4037),
                  fontSize: scale.rf(16, min: 13.5, max: 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          if (controller.isSelectedDateInFuture) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: scale.rs(10, min: 8, max: 10),
                horizontal: scale.rs(10, min: 8, max: 10),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDA7B),
                borderRadius:
                    BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
                border: Border.all(
                  color: const Color(0xFF757575),
                  width: scale.rs(1.5, min: 1.2, max: 1.5),
                ),
              ),
              child: Text(
                "ไม่สามารถบันทึกล่วงหน้าได้ (บันทึกได้เฉพาะวันนี้และย้อนหลัง)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF5D4037),
                  fontSize: scale.rf(16, min: 13.5, max: 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return Column(
            children: [
              Wrap(
                spacing: 15,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: controller.maleSymptomsList.map((tag) {
                  final isSelected = controller
                      .getSymptomsForSelectedDay()
                      .contains(tag['name']);

                  return _buildSymptomButton(
                    name: tag['name']!,
                    imagePath: tag['img']!,
                    isSelected: isSelected,
                    onTap: () => controller.toggleSymptom(tag['name']!),
                  );
                }).toList(),
              ),
              SizedBox(height: scale.rs(25, min: 18, max: 25)),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _handleMaleSave(controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20C2FF),
                    padding: EdgeInsets.symmetric(
                      horizontal: scale.rs(18, min: 14, max: 18),
                      vertical: scale.rs(10, min: 8, max: 10),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(scale.rs(20, min: 16, max: 20)),
                    ),
                  ),
                  child: Text(
                    "บันทึก",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: scale.rf(14, min: 12.5, max: 14),
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
    BuildContext context,
    ProfileController controller,
    String title,
    Color activeColor,
    bool isPeriodTab,
    ResponsiveScale scale,
  ) {
    return Obx(() {
      final selectedStatus = controller.getExplicitPeriodStatusForSelectedDay();
      final isSelected = selectedStatus == isPeriodTab;
      final buttonWidth = (MediaQuery.sizeOf(context).width * 0.42).clamp(
          scale.rs(120, min: 112, max: 120), scale.rs(180, min: 160, max: 180));
      return GestureDetector(
        onTap: () => controller.setPeriodStatus(isPeriodTab),
        child: Container(
          width: buttonWidth.toDouble(),
          padding: EdgeInsets.symmetric(
            vertical: scale.rs(12, min: 9, max: 12),
          ),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(scale.rs(15, min: 12, max: 15)),
            border: Border.all(
              color: const Color(0xFF757575),
              width: scale.rs(1.5, min: 1.2, max: 1.5),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF424242),
              fontSize: scale.rf(16, min: 13.5, max: 16),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMonthDropdownButton(
    ProfileController controller,
    ResponsiveScale scale,
  ) {
    return Obx(() {
      final selectedMonth =
          controller.monthNames[controller.selectedMonth.value - 1];

      return PopupMenuButton<String>(
        onSelected: controller.changeMonth,
        color: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        itemBuilder: (context) => controller.monthNames
            .map(
              (month) => PopupMenuItem<String>(
                value: month,
                child: Text(
                  month,
                  style: TextStyle(
                    color: const Color(0xFF757575),
                    fontSize: scale.rf(16, min: 14, max: 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
            .toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedMonth,
              style: TextStyle(
                color: const Color(0xFF757575),
                fontSize: scale.rf(16, min: 14, max: 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down,
              color: const Color(0xFF757575),
              size: scale.rs(29, min: 25, max: 29),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSymptomButton({
    required String name,
    required String imagePath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFA6E3F9)
                  : const Color(0xFFFFDA7B).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? const Color(0xFF4489D7) : Colors.black12,
                width: 1.5,
              ),
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5D4037),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodCareSectionData {
  final String symptomKey;
  final String title;
  final List<String> tips;

  const _PeriodCareSectionData({
    required this.symptomKey,
    required this.title,
    required this.tips,
  });
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

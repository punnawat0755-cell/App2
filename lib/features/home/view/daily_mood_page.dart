import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/features/profile/view/profile_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/features/home/service/daily_mood_status_service.dart';

class DailyMoodPage extends StatefulWidget {
  const DailyMoodPage({super.key});

  @override
  State<DailyMoodPage> createState() => _DailyMoodPageState();
}

class _DailyMoodPageState extends State<DailyMoodPage> {
  // ---------- UI mood options (5 levels) ----------
  static const List<_MoodOption> _moodOptions = [
    _MoodOption(
        label: 'แย่มาก',
        score: 0,
        icon: Icons.sentiment_very_dissatisfied,
        color: Color(0xFFD32F2F)),
    _MoodOption(
        label: 'แย่',
        score: 25,
        icon: Icons.sentiment_dissatisfied,
        color: Color(0xFFF57C00)),
    _MoodOption(
        label: 'เฉยๆ',
        score: 50,
        icon: Icons.sentiment_neutral,
        color: Color(0xFFFBC02D)),
    _MoodOption(
        label: 'ดี',
        score: 75,
        icon: Icons.sentiment_satisfied,
        color: Color(0xFF7CB342)),
    _MoodOption(
        label: 'ดีมาก',
        score: 100,
        icon: Icons.sentiment_very_satisfied,
        color: Color(0xFF2E7D32)),
  ];
  static const List<String> _moodImages = [
    'assets/images/whale_cry.png',
    'assets/images/whale_sad.png',
    'assets/images/whale_impassible.png',
    'assets/images/whale_happy.png',
    'assets/images/whale_love.png',
  ];
  static const List<List<String>> _moodTags = [
    [
      'เศร้า',
      'มีความหวัง',
      'หดหู่',
      'พยายามปรับ',
      'สู้ต่อ',
      'ใจเย็นลง',
      'น้อยใจ',
      'โกรธ'
    ],
    [
      'วิตกกังวล',
      'ปล่อยวาง',
      'เสียใจ',
      'ผิดหวัง',
      'สงบนิ่ง',
      'เหนื่อย',
      'โมโห',
      'ดีขึ้น'
    ],
    [
      'เรื่อยๆ',
      'สบายใจ',
      'มีกำลังใจ',
      'ภูมิใจ',
      'สงบนิ่ง',
      'เหนื่อย',
      'เบื่อ',
      'อ่อนเพลีย'
    ],
    [
      'เบิกบาน',
      'ร่าเริง',
      'วิตกกังวล',
      'เฉยๆ',
      'สงบนิ่ง',
      'เหนื่อย',
      'งานเยอะ',
      'สนุกสนาน'
    ],
    [
      'กดดัน',
      'ร่าเริง',
      'ตื่นเต้น',
      'อ่อนล้า',
      'สงบนิ่ง',
      'เหนื่อย',
      'แรงบันดาลใจ',
      'ดีใจ'
    ],
  ];

  // ---------- State ----------
  bool _isLoading = true;
  bool _answeredToday = false;
  bool _editUsedToday = false;
  bool _isEditMode = false;
  int _selectedMoodIndex = 2;
  final List<String> _selectedTags = [];

  int? _todayScore;
  // String? _todayLabel; // hidden with the answered summary card for now

  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _healingCtrl = TextEditingController();
  String? _serverNote;
  String? _serverHealingQuote;

  // เรียกใช้ Supabase Client ให้สั้นลง
  SupabaseClient get _sb => Supabase.instance.client;
  bool get _isLoggedIn => _sb.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _healingCtrl.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------
  int _scoreToMoodLevel(int score) {
    if (score <= 12) return 1;
    if (score <= 37) return 2;
    if (score <= 62) return 3;
    if (score <= 87) return 4;
    return 5;
  }

  _MoodOption _moodOptionFromLevel(int moodLevel) {
    final idx = (moodLevel - 1).clamp(0, _moodOptions.length - 1);
    return _moodOptions[idx];
  }

  int _indexFromOption(_MoodOption option) {
    final idx = _moodOptions.indexWhere((m) => m.score == option.score);
    return idx >= 0 ? idx : 2;
  }

  Future<void> _bootstrap() async {
    await _loadLocalStatus();
    await _syncFromSupabaseToday();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ---------- Local (SharedPreferences) ----------
  Future<void> _loadLocalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(DailyMoodStatusService.dateKey);
    final today = DailyMoodStatusService.todayAsKey();

    if (!mounted) return;
    setState(() {
      _answeredToday = (savedDate == today);
      _todayScore =
          _answeredToday ? prefs.getInt(DailyMoodStatusService.scoreKey) : null;
      // _todayLabel = _answeredToday
      //     ? prefs.getString(DailyMoodStatusService.labelKey)
      //     : null;
      _editUsedToday =
          (prefs.getString(DailyMoodStatusService.editUsedDateKey) == today);
      _isEditMode = false;
      if (_answeredToday && _todayScore != null) {
        final option = _moodOptions.firstWhere(
          (m) => m.score == _todayScore,
          orElse: () => _moodOptions[2],
        );
        _selectedMoodIndex = _indexFromOption(option);
      } else {
        _selectedMoodIndex = 2;
      }
    });
  }

  Future<void> _saveLocalToday(_MoodOption option,
      {required bool markEditUsed}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DailyMoodStatusService.todayAsKey();

    await prefs.setString(DailyMoodStatusService.dateKey, today);
    await prefs.setInt(DailyMoodStatusService.scoreKey, option.score);
    await prefs.setString(DailyMoodStatusService.labelKey, option.label);

    if (markEditUsed) {
      await prefs.setString(DailyMoodStatusService.editUsedDateKey, today);
    }
  }

  Future<void> _clearDailyMoodCache({bool showSnackbar = true}) async {
    await DailyMoodStatusService.clearLocalCache();

    _noteCtrl.clear();
    _healingCtrl.clear();
    _selectedTags.clear();
    _serverNote = null;
    _serverHealingQuote = null;

    await _loadLocalStatus();
    if (!mounted) return;

    if (showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('รีเซ็ตสถานะวันนี้แล้ว กดส่งพลังใจเพื่อบันทึกคำตอบใหม่'),
        ),
      );
    }
  }

  /* void _prepareSingleEditReset() {
    if (!_answeredToday || _editUsedToday) return;

    setState(() {
      _isEditMode = true;
      _selectedMoodIndex = 2;
      _selectedTags.clear();
      _noteCtrl.clear();
      _healingCtrl.clear();
      _serverNote = null;
      _serverHealingQuote = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('ล้างฟอร์มแล้ว คุณแก้ไขคำตอบวันนี้ได้อีก 1 ครั้งเท่านั้น'),
      ),
    );
  } */

  Future<void> _refreshProfileCalendarIfNeeded() async {
    if (!Get.isRegistered<ProfileController>()) return;
    await Get.find<ProfileController>().loadMonthData();
  }

  /* Future<void> _confirmClearCache() async {
    if (_answeredToday) {
      if (_editUsedToday) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คุณใช้สิทธิ์แก้ไขคำตอบวันนี้แล้ว')),
        );
        return;
      }

      final shouldResetForEdit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ล้างฟอร์มเพื่อแก้ไข'),
          content: const Text(
            'ต้องการล้างคำตอบบนหน้าจอเพื่อแก้ไขใหม่ใช่ไหม? คุณจะแก้ไขได้เพียง 1 ครั้งต่อวัน',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ล้างฟอร์ม'),
            ),
          ],
        ),
      );

      if (shouldResetForEdit == true && mounted) {
        _prepareSingleEditReset();
      }
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('รีเซ็ตคำตอบวันนี้'),
        content: const Text('ต้องการล้างคำตอบและสิทธิ์แก้ไขของวันนี้ใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('รีเซ็ต'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      // สามารถใส่คำสั่งลบข้อมูลจาก Supabase ตรงนี้เพิ่มได้ ถ้าต้องการให้ลบ DB ด้วย
      await _clearDailyMoodCache();
    }
  } */

  // ---------- Supabase ----------
  Future<void> _syncFromSupabaseToday() async {
    if (!_isLoggedIn) return;

    try {
      // ดึงข้อมูลใหม่มาให้ครบ รวมถึง emotions และ healing_quote
      final response = await _sb
          .from('v_my_mood_today')
          .select('mood_level, note, emotions, healing_quote')
          .maybeSingle();

      if (response == null) {
        await _clearDailyMoodCache(showSnackbar: false);
        if (mounted) {
          setState(() {
            _answeredToday = false;
            _isEditMode = false;
          });
        }
        return;
      }

      final moodLevel = response['mood_level'] as int?;
      final note = response['note'] as String?;
      final healingQuote = response['healing_quote'] as String?;
      final emotionsData = response['emotions'] as List<dynamic>?;

      if (moodLevel == null) return;

      final option = _moodOptionFromLevel(moodLevel);
      await _saveLocalToday(option, markEditUsed: false);

      if (!mounted) return;
      setState(() {
        _answeredToday = true;
        _todayScore = option.score;
        // _todayLabel = option.label;

        _serverNote = note;
        _serverHealingQuote = healingQuote;
        _noteCtrl.text = note ?? '';
        _healingCtrl.text = healingQuote ?? '';

        _selectedTags.clear();
        if (emotionsData != null) {
          _selectedTags.addAll(emotionsData.map((e) => e.toString()));
        }

        _selectedMoodIndex = _indexFromOption(option);
      });
    } catch (e) {
      debugPrint('Error syncing mood from Supabase: $e');
    }
  }

  Future<void> _saveToSupabase(
    _MoodOption option, {
    required String? note,
    required List<String> emotions,
    required String? healingQuote,
  }) async {
    if (!_isLoggedIn) throw Exception('ยังไม่ได้ล็อกอิน');

    final moodLevel = _scoreToMoodLevel(option.score);

    // ยิง RPC ฟังก์ชันที่แก้ไขใหม่
    await _sb.rpc('save_my_daily_mood', params: {
      'p_mood_level': moodLevel,
      'p_note': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      'p_emotions': emotions.isNotEmpty ? emotions : null,
      'p_healing_quote':
          (healingQuote != null && healingQuote.trim().isNotEmpty)
              ? healingQuote.trim()
              : null,
    });
  }

  // ---------- Actions ----------
  /* void _startEditOnce() {
    if (!_answeredToday || _editUsedToday) return;
    setState(() => _isEditMode = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เลือกคำตอบใหม่ได้ 1 ครั้ง')),
    );
  } */

  Future<void> _submitMood(_MoodOption option) async {
    final isFirstAnswer = !_answeredToday;
    final canEditNow = _answeredToday && _isEditMode && !_editUsedToday;

    if (!isFirstAnswer && !canEditNow) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('กำลังบันทึก...'), duration: Duration(seconds: 1)),
    );

    // 1) Save to Supabase
    if (_isLoggedIn) {
      try {
        await _saveToSupabase(
          option,
          note: _noteCtrl.text,
          emotions: _selectedTags,
          healingQuote: _healingCtrl.text,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ (Supabase): $e')),
        );
        return;
      }
    }

    // 2) Save to local cache
    await _saveLocalToday(option, markEditUsed: canEditNow);
    await _refreshProfileCalendarIfNeeded();

    final message = canEditNow
        ? 'แก้ไขคำตอบสำเร็จ: ${option.label} (${option.score}/100)'
        : 'บันทึกอารมณ์วันนี้แล้ว: ${option.label} (${option.score}/100)';

    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Navigator.of(context).pop(message);
      return;
    }

    setState(() {
      _answeredToday = true;
      _todayScore = option.score;
      // _todayLabel = option.label;

      _serverNote =
          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
      _serverHealingQuote =
          _healingCtrl.text.trim().isEmpty ? null : _healingCtrl.text.trim();
      _selectedMoodIndex = _indexFromOption(option);

      if (canEditNow) {
        _editUsedToday = true;
      }
      _isEditMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool get _canLeavePage => _answeredToday;

  void _showLockedExitHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กรุณาทำ Daily Mood ของวันนี้ก่อน จึงจะออกจากหน้านี้ได้'),
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final canSelectMood = !_answeredToday || _isEditMode;
    final selectedOption = _moodOptions[_selectedMoodIndex];
    final currentTags = _moodTags[_selectedMoodIndex];
    const mainBlue = Color(0xFF4A89D8);

    return PopScope(
      canPop: _canLeavePage,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _canLeavePage) return;
        _showLockedExitHint();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hidden for now per latest UI request:
                      // back button + reset button
                      /*
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_canLeavePage)
                            IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                  width: 32, height: 32),
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: mainBlue,
                              ),
                              tooltip: 'ย้อนกลับ',
                            )
                          else
                            const SizedBox(width: 32),
                          TextButton.icon(
                            onPressed: _confirmClearCache,
                            style: TextButton.styleFrom(
                              foregroundColor: mainBlue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.restart_alt, size: 18),
                            label: const Text(
                              'รีเซ็ต',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      */
                      const Text(
                        'วันนี้คุณรู้สึกยังไง ?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: mainBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Hidden for now per latest UI request:
                      // status chips
                      /*
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            icon: _answeredToday
                                ? Icons.check_circle
                                : Icons.access_time_filled,
                            label: _answeredToday
                                ? 'ตอบแล้ววันนี้'
                                : 'ยังไม่ตอบวันนี้',
                            backgroundColor: _answeredToday
                                ? const Color(0xFFDFF6E8)
                                : const Color(0xFFEAF2FF),
                          ),
                          _buildInfoChip(
                            icon: !_answeredToday
                                ? Icons.today
                                : _editUsedToday
                                    ? Icons.lock
                                    : (_isEditMode
                                        ? Icons.edit
                                        : Icons.edit_outlined),
                            label: !_answeredToday
                                ? 'ตอบได้วันละ 1 ครั้ง'
                                : _editUsedToday
                                    ? 'ใช้สิทธิ์แก้ไขแล้ว'
                                    : (_isEditMode
                                        ? 'กำลังแก้ไขคำตอบ'
                                        : 'แก้ได้อีก 1 ครั้ง'),
                            backgroundColor: _editUsedToday
                                ? const Color(0xFFFFE7D6)
                                : const Color(0xFFEAF7FF),
                          ),
                          _buildInfoChip(
                            icon: _isLoggedIn
                                ? Icons.cloud_done
                                : Icons.smartphone,
                            label: _isLoggedIn
                                ? 'ซิงก์กับบัญชีแล้ว'
                                : 'บันทึกลงเครื่องเท่านั้น',
                            backgroundColor: const Color(0xFFF1F5FF),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      */
                      Row(
                        children: List.generate(_moodOptions.length, (index) {
                          final option = _moodOptions[index];
                          final isSelected = _selectedMoodIndex == index;
                          final hasSelection = _selectedMoodIndex >= 0;
                          final currentOpacity =
                              isSelected ? 1.0 : (hasSelection ? 0.4 : 1.0);
                          return Expanded(
                            child: GestureDetector(
                              onTap: canSelectMood
                                  ? () => setState(() {
                                        _selectedMoodIndex = index;
                                        _selectedTags.clear();
                                      })
                                  : null,
                              child: Column(
                                children: [
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: currentOpacity,
                                    child: AnimatedScale(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      scale: isSelected ? 1.4 : 1.0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: Image.asset(
                                          _moodImages[index],
                                          width: 50,
                                          height: 50,
                                          errorBuilder: (_, __, ___) => Icon(
                                            option.icon,
                                            size: 45,
                                            color: mainBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      option.label,
                                      style: TextStyle(
                                        color: mainBlue,
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      Column(
                        children: [
                          _buildTagRow(currentTags.sublist(0, 4),
                              enabled: canSelectMood),
                          const SizedBox(height: 12),
                          _buildTagRow(currentTags.sublist(4, 8),
                              enabled: canSelectMood),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Hidden for now per latest UI request:
                      // answered-today summary card
                      /*
                      if (_answeredToday) ...[
                        _buildStatusCard(canSelectMood: canSelectMood),
                        const SizedBox(height: 24),
                      ],
                      */
                      const Text(
                        'บันทึกเรื่องราวของวันนี้',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: mainBlue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildPulseTextField(
                        controller: _noteCtrl,
                        enabled: canSelectMood,
                        maxLength: 200,
                        height: 120,
                      ),
                      const SizedBox(height: 8),
                      if (!_isLoggedIn)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            'ยังไม่ได้ล็อกอิน: จะบันทึกลงเครื่องเท่านั้น',
                            style: TextStyle(
                                color: Color(0xFF607D8B), fontSize: 12),
                          ),
                        ),
                      if (_isLoggedIn &&
                          !canSelectMood &&
                          ((_serverNote?.isNotEmpty ?? false) ||
                              (_serverHealingQuote?.isNotEmpty ?? false)))
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'ข้อมูลล่าสุดถูกโหลดจากบัญชีของคุณแล้ว',
                            style: TextStyle(
                              color: mainBlue.withValues(alpha: 0.72),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Text(
                            'ประโยคฮีลใจประจำวัน',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: mainBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '+2 coin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Image.asset('assets/images/coin2.png',
                              width: 18, height: 18),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildPulseTextField(
                        controller: _healingCtrl,
                        enabled: canSelectMood,
                        maxLength: 50,
                        height: 84,
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.85,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: canSelectMood
                                ? () => _submitMood(selectedOption)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB5EFFF),
                              disabledBackgroundColor: const Color(0xFFDBEEF7),
                              elevation: 6,
                              shadowColor: Colors.black.withValues(alpha: 0.25),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/heart.png',
                                  height: 40,
                                  width: 40,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'ส่งพลังใจ (Energy)',
                                  style: TextStyle(
                                    color: mainBlue,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /* Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color backgroundColor,
  }) {
    const mainBlue = Color(0xFF4A89D8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDEF7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: mainBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: mainBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  } */

  /* Widget _buildStatusCard({required bool canSelectMood}) {
    const mainBlue = Color(0xFF4A89D8);
    final selectedTagsSummary = _selectedTags.isEmpty
        ? 'ยังไม่ได้เลือกคำอธิบายความรู้สึกเพิ่มเติม'
        : _selectedTags.join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'วันนี้ตอบแล้ว: ${_todayLabel ?? '-'} | คะแนน ${_todayScore ?? '-'} / 100',
            style: const TextStyle(
              color: Color(0xFF0D47A1),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedTagsSummary,
            style: TextStyle(
              color: mainBlue.withValues(alpha: 0.78),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          if (_isEditMode)
            const Text(
              'กำลังแก้ไขคำตอบวันนี้ กดส่งพลังใจเพื่อบันทึกอีกครั้ง',
              style: TextStyle(
                color: mainBlue,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (!_editUsedToday)
            OutlinedButton.icon(
              onPressed: canSelectMood ? null : _startEditOnce,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('แก้ไขคำตอบ (ได้ 1 ครั้ง)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: mainBlue,
                side: const BorderSide(color: Color(0xFF93C5FD)),
              ),
            )
          else
            const Text(
              'คุณใช้สิทธิ์แก้ไขคำตอบวันนี้แล้ว',
              style: TextStyle(
                color: mainBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  } */

  Widget _buildPulseTextField({
    required TextEditingController controller,
    required bool enabled,
    required int maxLength,
    required double height,
  }) {
    const mainBlue = Color(0xFF4A89D8);
    const fillBlue = Color(0xFFE0F2FE);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: fillBlue,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: mainBlue, width: 1),
      ),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            maxLength: maxLength,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            enabled: enabled,
            style: const TextStyle(color: mainBlue, fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'มาเริ่มการบันทึกกันเถอะ......',
              hintStyle: TextStyle(color: Colors.black38),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 25),
              counterText: '',
            ),
          ),
          Positioned(
            bottom: 8,
            right: 12,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) => Text(
                '${value.text.length}/$maxLength',
                style: TextStyle(
                  color: mainBlue.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagRow(List<String> rowTags, {required bool enabled}) {
    const mainBlue = Color(0xFF4A89D8);
    const lightFillBlue = Color(0xFFE0F2FE);
    const tagFillBlue = Color(0xFF93C5FD);

    return Row(
      children: rowTags.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: enabled
                  ? () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? tagFillBlue : lightFillBlue,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: mainBlue, width: 1.2),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: mainBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MoodOption {
  final String label;
  final int score;
  final IconData icon;
  final Color color;

  const _MoodOption({
    required this.label,
    required this.score,
    required this.icon,
    required this.color,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/navigation/bottom_nav_bar.dart';
import 'package:flutter_application_1/core/services/coin_service.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
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
  static const int _maxSelectedTags = 3;

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
      final todayScore =
          _answeredToday ? prefs.getInt(DailyMoodStatusService.scoreKey) : null;
      _editUsedToday =
          (prefs.getString(DailyMoodStatusService.editUsedDateKey) == today);
      _isEditMode = false;
      if (_answeredToday && todayScore != null) {
        final option = _moodOptions.firstWhere(
          (m) => m.score == todayScore,
          orElse: () => _moodOptions[2],
        );
        _selectedMoodIndex = _indexFromOption(option);
      } else {
        _selectedMoodIndex = 2;
      }
    });
  }

  Future<void> _saveLocalToday(
    _MoodOption option, {
    required bool markEditUsed,
  }) async {
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

  Future<void> _refreshProfileCalendarIfNeeded() async {
    if (!Get.isRegistered<ProfileController>()) return;
    await Get.find<ProfileController>().loadMonthData();
  }

  Future<void> _refreshCoinsIfNeeded() async {
    final coinService = Get.isRegistered<CoinService>()
        ? Get.find<CoinService>()
        : Get.put(CoinService(), permanent: true);
    await coinService.loadCoins();
  }

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
  Future<void> _submitMood(_MoodOption option) async {
    final isFirstAnswer = !_answeredToday;
    final canEditNow = _answeredToday && _isEditMode && !_editUsedToday;

    if (!isFirstAnswer && !canEditNow) return;
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนบันทึก Daily Mood')),
      );
      return;
    }

    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //       content: Text('กำลังบันทึก...'), duration: Duration(seconds: 1)),
    // );

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

    await _saveLocalToday(option, markEditUsed: canEditNow);
    await _refreshProfileCalendarIfNeeded();
    await _refreshCoinsIfNeeded();
    if (!mounted) return;

    setState(() {
      _answeredToday = true;

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

    Get.offAll(() => const BottomNavBar());
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final scale =
                        ResponsiveScale.fromWidth(constraints.maxWidth);
                    final horizontalPadding = constraints.maxWidth < 360
                        ? scale.rs(14, min: 10, max: 14)
                        : scale.rs(24, min: 16, max: 24);

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: scale.rs(30, min: 20, max: 30),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'วันนี้คุณรู้สึกยังไง ?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: scale.rf(26, min: 21, max: 26),
                              fontWeight: FontWeight.bold,
                              color: mainBlue,
                            ),
                          ),
                          SizedBox(height: scale.rs(16, min: 12, max: 16)),
                          Row(
                            children:
                                List.generate(_moodOptions.length, (index) {
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
                                        duration:
                                            const Duration(milliseconds: 200),
                                        opacity: currentOpacity,
                                        child: AnimatedScale(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          scale: isSelected ? 1.4 : 1.0,
                                          child: Padding(
                                            padding: EdgeInsets.all(
                                              scale.rs(2, min: 1, max: 2),
                                            ),
                                            child: Image.asset(
                                              _moodImages[index],
                                              width: scale.rs(50,
                                                  min: 40, max: 50),
                                              height: scale.rs(50,
                                                  min: 40, max: 50),
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(
                                                option.icon,
                                                size: scale.rs(45,
                                                    min: 35, max: 45),
                                                color: mainBlue,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                          height: scale.rs(4, min: 2, max: 4)),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          option.label,
                                          style: TextStyle(
                                            color: mainBlue,
                                            fontSize:
                                                scale.rf(13, min: 11, max: 13),
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
                          SizedBox(height: scale.rs(32, min: 20, max: 32)),
                          Column(
                            children: [
                              _buildTagRow(currentTags.sublist(0, 4),
                                  enabled: canSelectMood, scale: scale),
                              SizedBox(height: scale.rs(12, min: 8, max: 12)),
                              _buildTagRow(currentTags.sublist(4, 8),
                                  enabled: canSelectMood, scale: scale),
                            ],
                          ),
                          SizedBox(height: scale.rs(30, min: 16, max: 54)),
                          Text(
                            'บันทึกเรื่องราวของวันนี้',
                            style: TextStyle(
                              fontSize: scale.rf(18, min: 15.5, max: 18),
                              fontWeight: FontWeight.bold,
                              color: mainBlue,
                            ),
                          ),
                          SizedBox(height: scale.rs(10, min: 8, max: 10)),
                          _buildPulseTextField(
                            controller: _noteCtrl,
                            enabled: canSelectMood,
                            maxLength: 200,
                            height: 120,
                            scale: scale,
                          ),
                          SizedBox(height: scale.rs(8, min: 6, max: 8)),
                          if (!_isLoggedIn)
                            Padding(
                              padding: EdgeInsets.only(
                                  left: scale.rs(4, min: 3, max: 4)),
                              child: Text(
                                'ยังไม่ได้ล็อกอิน: ไม่สามารถบันทึกข้อมูลได้',
                                style: TextStyle(
                                  color: const Color(0xFF607D8B),
                                  fontSize: scale.rf(12, min: 10.5, max: 12),
                                ),
                              ),
                            ),
                          if (_isLoggedIn &&
                              !canSelectMood &&
                              ((_serverNote?.isNotEmpty ?? false) ||
                                  (_serverHealingQuote?.isNotEmpty ?? false)))
                            Padding(
                              padding: EdgeInsets.only(
                                  left: scale.rs(4, min: 3, max: 4)),
                              child: Text(
                                'ข้อมูลล่าสุดถูกโหลดจากบัญชีของคุณแล้ว',
                                style: TextStyle(
                                  color: mainBlue.withValues(alpha: 0.72),
                                  fontSize: scale.rf(12, min: 10.5, max: 12),
                                ),
                              ),
                            ),
                          SizedBox(height: scale.rs(24, min: 16, max: 24)),
                          Row(
                            children: [
                              Text(
                                'ประโยคฮีลใจประจำวัน',
                                style: TextStyle(
                                  fontSize: scale.rf(18, min: 15.5, max: 18),
                                  fontWeight: FontWeight.bold,
                                  color: mainBlue,
                                ),
                              ),
                              SizedBox(width: scale.rs(8, min: 6, max: 8)),
                              Text(
                                '+2 coin',
                                style: TextStyle(
                                  fontSize: scale.rf(16, min: 14, max: 16),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFBBF24),
                                ),
                              ),
                              SizedBox(width: scale.rs(3, min: 2, max: 3)),
                              Image.asset('assets/images/coin2.png',
                                  width: scale.rs(18, min: 14, max: 18),
                                  height: scale.rs(18, min: 14, max: 18)),
                            ],
                          ),
                          SizedBox(height: scale.rs(10, min: 8, max: 10)),
                          _buildPulseTextField(
                            controller: _healingCtrl,
                            enabled: canSelectMood,
                            maxLength: 50,
                            height: 84,
                            scale: scale,
                          ),
                          SizedBox(height: scale.rs(40, min: 24, max: 120)),
                          Center(
                            child: SizedBox(
                              width: scale.rw(0.85, min: 220, max: 420),
                              height: scale.rs(55, min: 46, max: 55),
                              child: ElevatedButton(
                                onPressed: canSelectMood
                                    ? () => _submitMood(selectedOption)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB5EFFF),
                                  disabledBackgroundColor:
                                      const Color(0xFFDBEEF7),
                                  elevation: 6,
                                  shadowColor:
                                      Colors.black.withValues(alpha: 0.25),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      scale.rs(20, min: 16, max: 20),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      "assets/images/heartpulse.png",
                                      height: scale.rs(40, min: 32, max: 40),
                                      width: scale.rs(40, min: 32, max: 40),
                                    ),
                                    SizedBox(
                                        width: scale.rs(10, min: 8, max: 10)),
                                    Text(
                                      'ส่งพลังใจ (Energy)',
                                      style: TextStyle(
                                        color: mainBlue,
                                        fontWeight: FontWeight.w500,
                                        fontSize:
                                            scale.rf(18, min: 15.5, max: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // SizedBox(height: scale.rs(30, min: 20, max: 30)),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildPulseTextField({
    required TextEditingController controller,
    required bool enabled,
    required int maxLength,
    required double height,
    required ResponsiveScale scale,
  }) {
    const mainBlue = Color(0xFF4A89D8);
    const fillBlue = Color(0xFFE0F2FE);

    return Container(
      height: scale.rs(height, min: height * 0.8, max: height),
      decoration: BoxDecoration(
        color: fillBlue,
        borderRadius: BorderRadius.circular(scale.rs(15, min: 12, max: 15)),
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
            style: TextStyle(
              color: Color(0xFF4489D7),
              fontSize: scale.rf(16, min: 14, max: 16),
            ),
            decoration: InputDecoration(
              hintText: 'มาเริ่มการบันทึกกันเถอะ......',
              hintStyle: TextStyle(
                color: Color(0xFF9FBCDB),
                fontSize: scale.rf(14, min: 12, max: 14),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(
                left: scale.rs(15, min: 12, max: 15),
                right: scale.rs(15, min: 12, max: 15),
                top: scale.rs(15, min: 12, max: 15),
                bottom: scale.rs(25, min: 18, max: 25),
              ),
              counterText: '',
            ),
          ),
          Positioned(
            bottom: scale.rs(8, min: 6, max: 8),
            right: scale.rs(12, min: 9, max: 12),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) => Text(
                '${value.text.length}/$maxLength',
                style: TextStyle(
                  color: Color(0xFF9FBCDB),
                  fontSize: scale.rf(12, min: 10.5, max: 12),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagRow(
    List<String> rowTags, {
    required bool enabled,
    required ResponsiveScale scale,
  }) {
    return Row(
      children: rowTags.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: scale.rs(4, min: 2, max: 4),
            ),
            child: GestureDetector(
              onTap: enabled
                  ? () {
                      if (!isSelected &&
                          _selectedTags.length >= _maxSelectedTags) {
                        return;
                      }

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
                height: scale.rs(42, min: 34, max: 42),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFF8BE2FB) : Color(0xFFCEEFFE),
                  borderRadius: BorderRadius.circular(
                    scale.rs(25, min: 18, max: 25),
                  ),
                  border: Border.all(
                    color: Color(0xFF4489D7),
                    width: scale.rs(1.2, min: 1, max: 1.2),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: Color(0xFF4489D7),
                      fontWeight: FontWeight.bold,
                      fontSize: scale.rf(14, min: 12, max: 14),
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

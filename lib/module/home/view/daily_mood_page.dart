import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyMoodPage extends StatefulWidget {
  const DailyMoodPage({super.key});

  @override
  State<DailyMoodPage> createState() => _DailyMoodPageState();
}

class _DailyMoodPageState extends State<DailyMoodPage> {
  // ---------- Local cache keys ----------
  static const String _dateKey = 'daily_mood_last_date';
  static const String _scoreKey = 'daily_mood_last_score';
  static const String _labelKey = 'daily_mood_last_label';
  static const String _editUsedDateKey = 'daily_mood_edit_used_date';

  // ---------- UI mood options (5 levels) ----------
  static const List<_MoodOption> _moodOptions = [
    _MoodOption(label: 'แย่มาก', score: 0, icon: Icons.sentiment_very_dissatisfied, color: Color(0xFFD32F2F)),
    _MoodOption(label: 'แย่', score: 25, icon: Icons.sentiment_dissatisfied, color: Color(0xFFF57C00)),
    _MoodOption(label: 'เฉยๆ', score: 50, icon: Icons.sentiment_neutral, color: Color(0xFFFBC02D)),
    _MoodOption(label: 'ดี', score: 75, icon: Icons.sentiment_satisfied, color: Color(0xFF7CB342)),
    _MoodOption(label: 'ดีมาก', score: 100, icon: Icons.sentiment_very_satisfied, color: Color(0xFF2E7D32)),
  ];
  static const List<String> _moodImages = [
    'assets/images/whale_cry.png',
    'assets/images/whale_sad.png',
    'assets/images/whale_impassible.png',
    'assets/images/whale_happy.png',
    'assets/images/whale_love.png',
  ];
  static const List<List<String>> _moodTags = [
    ['เศร้า', 'มีความหวัง', 'หดหู่', 'พยายามปรับ', 'สู้ต่อ', 'ใจเย็นลง', 'น้อยใจ', 'โกรธ'],
    ['วิตกกังวล', 'ปล่อยวาง', 'เสียใจ', 'ผิดหวัง', 'สงบนิ่ง', 'เหนื่อย', 'โมโห', 'ดีขึ้น'],
    ['เรื่อยๆ', 'สบายใจ', 'มีกำลังใจ', 'ภูมิใจ', 'สงบนิ่ง', 'เหนื่อย', 'เบื่อ', 'อ่อนเพลีย'],
    ['เบิกบาน', 'ร่าเริง', 'วิตกกังวล', 'เฉยๆ', 'สงบนิ่ง', 'เหนื่อย', 'งานเยอะ', 'สนุกสนาน'],
    ['กดดัน', 'ร่าเริง', 'ตื่นเต้น', 'อ่อนล้า', 'สงบนิ่ง', 'เหนื่อย', 'แรงบันดาลใจ', 'ดีใจ'],
  ];

  // ---------- State ----------
  bool _isLoading = true;
  bool _answeredToday = false;
  bool _editUsedToday = false;
  bool _isEditMode = false;
  int _selectedMoodIndex = 2;
  final List<String> _selectedTags = [];

  int? _todayScore;
  String? _todayLabel;

  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _healingCtrl = TextEditingController();
  String? _serverNote;

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
  String _todayAsKey() {
    var now = DateTime.now();
    // 📌 ปรับปรุง: ตัดรอบตี 5 ให้ตรงกับฐานข้อมูล SQL แบบเป๊ะๆ
    if (now.hour < 5) {
      now = now.subtract(const Duration(days: 1));
    }
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

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
    final savedDate = prefs.getString(_dateKey);
    final today = _todayAsKey();

    if (!mounted) return;
    setState(() {
      _answeredToday = (savedDate == today);
      _todayScore = _answeredToday ? prefs.getInt(_scoreKey) : null;
      _todayLabel = _answeredToday ? prefs.getString(_labelKey) : null;
      _editUsedToday = (prefs.getString(_editUsedDateKey) == today);
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

  Future<void> _saveLocalToday(_MoodOption option, {required bool markEditUsed}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayAsKey();

    await prefs.setString(_dateKey, today);
    await prefs.setInt(_scoreKey, option.score);
    await prefs.setString(_labelKey, option.label);

    if (markEditUsed) {
      await prefs.setString(_editUsedDateKey, today);
    }
  }

  Future<void> _clearDailyMoodCache({bool showSnackbar = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dateKey);
    await prefs.remove(_scoreKey);
    await prefs.remove(_labelKey);
    await prefs.remove(_editUsedDateKey);

    _noteCtrl.clear();
    _serverNote = null;

    await _loadLocalStatus();
    if (!mounted) return;

    if (showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รีเซ็ตแบบทดสอบวันนี้แล้ว')),
      );
    }
  }

  Future<void> _confirmClearCache() async {
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
      await _clearDailyMoodCache();
    }
  }

  // ---------- Supabase ----------
  Future<void> _syncFromSupabaseToday() async {
    if (!_isLoggedIn) return;

    try {
      final response = await _sb.from('v_my_mood_today').select('mood_level, note').maybeSingle();
      
      // 📌 จุดที่แก้ไขปัญหา: ถ้า Supabase บอกว่ายังไม่มีข้อมูล (เช่น สลับไปไอดีใหม่)
      if (response == null) {
        // ต้องเคลียร์ Local Cache เก่าทิ้ง และรีเซ็ตหน้าจอให้กลับเป็น "ยังไม่ได้ตอบ"
        await _clearDailyMoodCache(showSnackbar: false);
        if (mounted) {
          setState(() {
            _answeredToday = false;
            _isEditMode = false;
          });
        }
        return; // จบการทำงานตรงนี้
      }

      // กรณีมีข้อมูลใน Supabase ให้อัปเดต UI และ Local Cache ตามปกติ
      final moodLevel = response['mood_level'] as int?;
      final note = response['note'] as String?;

      if (moodLevel == null) return;

      final option = _moodOptionFromLevel(moodLevel);
      await _saveLocalToday(option, markEditUsed: false);

      if (!mounted) return;
      setState(() {
        _answeredToday = true;
        _todayScore = option.score;
        _todayLabel = option.label;
        _serverNote = note;
        _noteCtrl.text = note ?? '';
        _selectedMoodIndex = _indexFromOption(option);
      });
    } catch (e) {
      debugPrint('Error syncing mood from Supabase: $e');
    }
  }

  Future<void> _saveToSupabase(_MoodOption option, {required String? note}) async {
    if (!_isLoggedIn) throw Exception('ยังไม่ได้ล็อกอิน');

    final moodLevel = _scoreToMoodLevel(option.score);

    await _sb.rpc('save_my_daily_mood', params: {
      'p_mood_level': moodLevel,
      'p_note': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
    });
  }

  // ---------- Actions ----------
  void _startEditOnce() {
    if (!_answeredToday || _editUsedToday) return;
    setState(() => _isEditMode = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เลือกคำตอบใหม่ได้ 1 ครั้ง')),
    );
  }

  Future<void> _submitMood(_MoodOption option) async {
    final isFirstAnswer = !_answeredToday;
    final canEditNow = _answeredToday && _isEditMode && !_editUsedToday;

    if (!isFirstAnswer && !canEditNow) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('กำลังบันทึก...'), duration: Duration(seconds: 1)),
    );

    // 1) Save to Supabase
    if (_isLoggedIn) {
      try {
        await _saveToSupabase(option, note: _noteCtrl.text);
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

    if (!mounted) return;
    setState(() {
      _answeredToday = true;
      _todayScore = option.score;
      _todayLabel = option.label;
      _serverNote = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
      _selectedMoodIndex = _indexFromOption(option);

      if (canEditNow) {
        _editUsedToday = true;
      }
      _isEditMode = false;
    });

    final message = canEditNow
        ? 'แก้ไขคำตอบสำเร็จ: ${option.label} (${option.score}/100)'
        : 'บันทึกอารมณ์วันนี้แล้ว: ${option.label} (${option.score}/100)';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final canSelectMood = !_answeredToday || _isEditMode;
    final selectedOption = _moodOptions[_selectedMoodIndex];
    final currentTags = _moodTags[_selectedMoodIndex];
    const mainBlue = Color(0xFF4A89D8);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'คำถามรายวัน',
          style: TextStyle(color: mainBlue, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _confirmClearCache,
            child: const Text('รีเซ็ต', style: TextStyle(color: mainBlue)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'วันนี้คุณรู้สึกยังไง ?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: mainBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ตอบได้วันละ 1 ครั้ง และแก้ไขเพิ่มได้ 1 ครั้ง',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF5F7FA3)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: List.generate(_moodOptions.length, (index) {
                        final option = _moodOptions[index];
                        final isSelected = _selectedMoodIndex == index;
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
                                  duration: const Duration(milliseconds: 180),
                                  opacity: isSelected ? 1 : 0.45,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 180),
                                    scale: isSelected ? 1.34 : 1.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: isSelected
                                            ? Border.all(color: const Color(0xFFB5EFFF), width: 2)
                                            : null,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Image.asset(
                                          _moodImages[index],
                                          width: 48,
                                          height: 48,
                                          errorBuilder: (_, __, ___) => Icon(
                                            option.icon,
                                            size: 36,
                                            color: mainBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      color: mainBlue,
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        _buildTagRow(currentTags.sublist(0, 4), enabled: canSelectMood),
                        const SizedBox(height: 12),
                        _buildTagRow(currentTags.sublist(4, 8), enabled: canSelectMood),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_answeredToday)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBFDEF7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'วันนี้ตอบแล้ว: ${_todayLabel ?? '-'} | คะแนน ${_todayScore ?? '-'} / 100',
                              style: const TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!_editUsedToday)
                              OutlinedButton.icon(
                                onPressed: _isEditMode ? null : _startEditOnce,
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
                                style: TextStyle(color: mainBlue),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 6),
                    if (!_isLoggedIn)
                      const Text(
                        'ยังไม่ได้ล็อกอิน: จะบันทึกลงเครื่องเท่านั้น',
                        style: TextStyle(color: Color(0xFF607D8B), fontSize: 12),
                      ),
                    if (_isLoggedIn && _serverNote != null && _serverNote!.isNotEmpty && !canSelectMood)
                      Text(
                        'บันทึกล่าสุด: $_serverNote',
                        style: TextStyle(
                          color: mainBlue.withValues(alpha: 0.72),
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 26),
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
                        Image.asset('assets/images/coin2.png', width: 18, height: 18),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildPulseTextField(
                      controller: _healingCtrl,
                      enabled: canSelectMood,
                      maxLength: 50,
                      height: 84,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: canSelectMood ? () => _submitMood(selectedOption) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB5EFFF),
                          disabledBackgroundColor: const Color(0xFFDBEEF7),
                          elevation: 6,
                          shadowColor: Colors.black.withValues(alpha: 0.25),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const ImageIcon(
                              AssetImage('assets/images/heart.png'),
                              size: 32,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'ส่งพลังใจ (Energy)',
                              style: TextStyle(
                                color: mainBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
              contentPadding: EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 25),
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

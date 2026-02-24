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

  // ---------- State ----------
  bool _isLoading = true;
  bool _answeredToday = false;
  bool _editUsedToday = false;
  bool _isEditMode = false;

  int? _todayScore;
  String? _todayLabel;

  final TextEditingController _noteCtrl = TextEditingController();
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

    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6F7FF),
        elevation: 0,
        title: const Text(
          'คำถามรายวัน',
          style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _confirmClearCache,
            child: const Text('รีเซ็ต'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'วันนี้คุณรู้สึกอย่างไร?\nเลือกได้วันละ 1 ครั้ง',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1565C0),
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'บันทึกสั้นๆ (ไม่บังคับ)',
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _noteCtrl,
                            minLines: 1,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'เช่น วันนี้เครียดนิดหน่อย แต่ยังไหว',
                              filled: true,
                              fillColor: const Color(0xFFF5FBFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            enabled: canSelectMood,
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
                              style: const TextStyle(color: Color(0xFF607D8B), fontSize: 12),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_answeredToday)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDFF3FF),
                          borderRadius: BorderRadius.circular(14),
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
                                icon: const Icon(Icons.edit),
                                label: const Text('แก้ไขคำตอบ (ได้ 1 ครั้ง)'),
                              )
                            else
                              const Text(
                                'คุณใช้สิทธิ์แก้ไขคำตอบวันนี้แล้ว',
                                style: TextStyle(color: Color(0xFF1565C0)),
                              ),
                          ],
                        ),
                      )
                    else
                      const Text(
                        'เลือกอารมณ์ของคุณ',
                        style: TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView.separated(
                        itemCount: _moodOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final option = _moodOptions[index];
                          return ElevatedButton.icon(
                            onPressed: canSelectMood ? () => _submitMood(option) : null,
                            icon: Icon(option.icon, color: Colors.white),
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                '${option.label}  (${option.score}/100)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: option.color,
                              disabledBackgroundColor: option.color.withAlpha(102),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// Controller
// ==========================================
class HealthDashboardController extends GetxController {
  final supabase = Supabase.instance.client;

  var isLoading = false.obs;

  // สถิติรวม (จาก get_menstrual_stats)
  var totalCycles      = 0.obs;
  var avgCycleLength   = 0.obs;
  var avgDuration      = 0.obs;
  var topSymptoms      = <String>[].obs;

  // Timeline รายรอบ (จาก get_my_menstrual_cycles)
  var cycles = <_CycleData>[].obs;

  // สรุปรายเดือน (คำนวณจาก period days ที่ดึงมา)
  var monthlySummaries = <_MonthlySummary>[].obs;

  final List<String> monthNamesFull = [
    "มกราคม","กุมภาพันธ์","มีนาคม","เมษายน","พฤษภาคม","มิถุนายน",
    "กรกฎาคม","สิงหาคม","กันยายน","ตุลาคม","พฤศจิกายน","ธันวาคม",
  ];
  final List<String> monthNamesShort = [
    "ม.ค.","ก.พ.","มี.ค.","เม.ย.","พ.ค.","มิ.ย.",
    "ก.ค.","ส.ค.","ก.ย.","ต.ค.","พ.ย.","ธ.ค.",
  ];

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      await Future.wait([_loadStats(), _loadCyclesAndMonthly()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadStats() async {
    try {
      final res = await supabase.rpc('get_menstrual_stats');
      if (res != null && res is List && res.isNotEmpty) {
        final d = res[0];
        totalCycles.value    = d['total_cycles_recorded'] ?? 0;
        avgCycleLength.value = d['avg_cycle_length']      ?? 0;
        avgDuration.value    = d['avg_period_duration']   ?? 0;
        if (d['most_common_symptoms'] != null) {
          topSymptoms.value = List<String>.from(d['most_common_symptoms']);
        }
      }
    } catch (e) {
      debugPrint('_loadStats error: $e');
    }
  }

  Future<void> _loadCyclesAndMonthly() async {
    try {
      // ─── 1. ดึงรายรอบ ───
      final cycleRes = await supabase.rpc('get_my_menstrual_cycles');
      if (cycleRes != null && cycleRes is List) {
        cycles.value = cycleRes
            .take(6)
            .map((e) => _CycleData.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }

      // ─── 2. ดึงข้อมูลรายวัน 4 เดือนย้อนหลัง เพื่อสรุปรายเดือน ───
      final now    = DateTime.now();
      final Map<String, List<Map<String, dynamic>>> byMonth = {};

      for (int i = 0; i < 4; i++) {
        final target = DateTime(now.year, now.month - i, 1);
        final key    = "${target.year}-${target.month.toString().padLeft(2,'0')}";
        final res    = await supabase.rpc('get_monthly_calendar_data', params: {
          'p_year': target.year, 'p_month': target.month,
        });
        if (res != null) {
          byMonth[key] = (res as List)
              .where((r) => r['is_menstruating'] == true)
              .map((r) => Map<String, dynamic>.from(r))
              .toList();
        }
      }

      // ─── 3. คำนวณสรุปรายเดือน ───
      final List<_MonthlySummary> summaries = [];
      byMonth.forEach((key, days) {
        if (days.isEmpty) return;
        final parts = key.split('-');
        final year  = int.parse(parts[0]);
        final month = int.parse(parts[1]);

        // flow ที่เด่นสุด
        final flowCount = <String, int>{};
        double totalPain = 0;
        int    painCount = 0;

        for (var d in days) {
          final f = d['flow_level'] as String?;
          if (f != null) flowCount[f] = (flowCount[f] ?? 0) + 1;
          final p = d['pain_level'] as int?;
          if (p != null) { totalPain += p; painCount++; }
        }

        String? dominantFlow;
        if (flowCount.isNotEmpty) {
          dominantFlow = flowCount.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;
        }

        summaries.add(_MonthlySummary(
          year:          year,
          month:         month,
          periodDays:    days.length,
          dominantFlow:  dominantFlow,
          avgPain:       painCount > 0 ? (totalPain / painCount) : null,
        ));
      });

      summaries.sort((a, b) {
        final da = DateTime(a.year, a.month);
        final db = DateTime(b.year, b.month);
        return db.compareTo(da);
      });
      monthlySummaries.value = summaries;

    } catch (e) {
      debugPrint('_loadCyclesAndMonthly error: $e');
    }
  }

  String formatDateShort(DateTime d) =>
      "${d.day} ${monthNamesShort[d.month - 1]}";

  String formatDateFull(DateTime d) =>
      "${d.day} ${monthNamesFull[d.month - 1]} ${d.year}";
}

// ─── Data Models ──────────────────────────────────────────────────────────────
class _CycleData {
  final DateTime startDate;
  final DateTime endDate;
  final int      durationDays;

  _CycleData({required this.startDate, required this.endDate, required this.durationDays});

  factory _CycleData.fromMap(Map<String, dynamic> m) => _CycleData(
    startDate:    DateTime.parse(m['start_date'].toString()),
    endDate:      DateTime.parse(m['end_date'].toString()),
    durationDays: m['duration_days'] as int,
  );
}

class _MonthlySummary {
  final int     year, month, periodDays;
  final String? dominantFlow;
  final double? avgPain;

  _MonthlySummary({
    required this.year,
    required this.month,
    required this.periodDays,
    this.dominantFlow,
    this.avgPain,
  });
}

// ==========================================
// Page
// ==========================================
class HealthDashboardPage extends StatefulWidget {
  const HealthDashboardPage({super.key});

  @override
  State<HealthDashboardPage> createState() => _HealthDashboardPageState();
}

class _HealthDashboardPageState extends State<HealthDashboardPage>
    with WidgetsBindingObserver {
  late final HealthDashboardController c;

  @override
  void initState() {
    super.initState();
    c = Get.put(HealthDashboardController(), permanent: false);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) c.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6F7FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4489D7)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "สรุปสุขภาพรอบเดือน",
          style: GoogleFonts.mitr(
            textStyle: const TextStyle(
                color: Color(0xFF4489D7), fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        actions: [
          Obx(() => controller.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF4489D7)),
                  ))
              : IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4489D7)),
                  onPressed: c.loadAll,
                )),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value && c.cycles.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4489D7)));
        }
        return RefreshIndicator(
          onRefresh: c.loadAll,
          color: const Color(0xFF4489D7),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stat Cards ────────────────────────────────────────
                _buildStatCards(),
                const SizedBox(height: 24),

                // ── สรุปรายเดือน ──────────────────────────────────────
                _SectionHeader(title: "สรุปรายเดือน", icon: Icons.calendar_today_rounded),
                const SizedBox(height: 12),
                _buildMonthlySummary(),
                const SizedBox(height: 24),

                // ── Timeline รายรอบ ───────────────────────────────────
                _SectionHeader(title: "Timeline รายรอบ", icon: Icons.timeline_rounded),
                const SizedBox(height: 12),
                _buildCycleTimeline(),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── Stat Cards ──────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    return Obx(() => Row(
      children: [
        _StatCard(
          emoji: "🔄",
          value: "${c.totalCycles.value}",
          label: "รอบที่บันทึก",
          accent: const Color(0xFF4489D7),
        ),
        const SizedBox(width: 10),
        _StatCard(
          emoji: "📅",
          value: c.avgCycleLength.value > 0 ? "${c.avgCycleLength.value}" : "—",
          unit: "วัน",
          label: "รอบเฉลี่ย",
          accent: const Color(0xFFF05A42),
        ),
        const SizedBox(width: 10),
        _StatCard(
          emoji: "🩸",
          value: c.avgDuration.value > 0 ? "${c.avgDuration.value}" : "—",
          unit: "วัน",
          label: "มาเฉลี่ย",
          accent: const Color(0xFFFF6B6B),
        ),
      ],
    ));
  }

  // ─── Monthly Summary ─────────────────────────────────────────────────────
  Widget _buildMonthlySummary() {
    return Obx(() {
      if (c.monthlySummaries.isEmpty) {
        return _EmptyState(message: "ยังไม่มีข้อมูล\nบันทึกประจำเดือนก่อนนะคะ");
      }
      return Column(
        children: c.monthlySummaries.map((s) => _MonthlyCard(
          summary: s,
          controller: c,
        )).toList(),
      );
    });
  }

  // ─── Cycle Timeline ──────────────────────────────────────────────────────
  Widget _buildCycleTimeline() {
    return Obx(() {
      if (c.cycles.isEmpty) {
        return _EmptyState(message: "ยังไม่มีข้อมูลรอบเดือน");
      }

      final totalCyclesCount = c.cycles.length;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          children: c.cycles.asMap().entries.map((entry) {
            final idx   = entry.key;
            final cycle = entry.value;
            final isLast = idx == c.cycles.length - 1;
            final cycleNo = totalCyclesCount - idx;

            return _TimelineRow(
              cycleNo:   cycleNo,
              cycle:     cycle,
              controller: c,
              isLast:    isLast,
              isLatest:  idx == 0,
            );
          }).toList(),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-Widgets
// ─────────────────────────────────────────────────────────────────────────────

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF4489D7).withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF4489D7)),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: GoogleFonts.mitr(
          textStyle: const TextStyle(
              color: Color(0xFF2C5282), fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String emoji, value, label;
  final String? unit;
  final Color accent;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.accent,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: accent.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                    style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        height: 1)),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(unit!,
                        style: TextStyle(
                            color: accent.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Monthly Card ──────────────────────────────────────────────────────────────
class _MonthlyCard extends StatelessWidget {
  final _MonthlySummary summary;
  final HealthDashboardController controller;
  const _MonthlyCard({required this.summary, required this.controller});

  static const _flowData = {
    'spotting': ('🩷', 'กระปิดกระปอย', Color(0xFFFFB3C6)),
    'light':    ('🩸', 'น้อย',          Color(0xFFFF8FAB)),
    'medium':   ('🩸🩸', 'ปานกลาง',    Color(0xFFF05A42)),
    'heavy':    ('🩸🩸🩸', 'มาก',       Color(0xFFB71C1C)),
  };

  @override
  Widget build(BuildContext context) {
    final fd   = _flowData[summary.dominantFlow];
    final pain = summary.avgPain;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // ── Month Badge ──
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.monthNamesShort[summary.month - 1],
                  style: const TextStyle(
                      color: Color(0xFF4489D7),
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                Text(
                  '${summary.year}',
                  style: const TextStyle(
                      color: Color(0xFF9E9E9E), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ── Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.monthNamesFull[summary.month - 1],
                  style: GoogleFonts.mitr(
                    textStyle: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // จำนวนวัน
                    _InfoChip(
                      icon: Icons.water_drop_rounded,
                      label: "${summary.periodDays} วัน",
                      color: const Color(0xFFF05A42),
                      bgColor: const Color(0xFFFFEBEE),
                    ),
                    // Flow
                    if (fd != null)
                      _InfoChip(
                        label: "${fd.$1} ${fd.$2}",
                        color: fd.$3,
                        bgColor: fd.$3.withOpacity(0.12),
                      ),
                    // Pain
                    if (pain != null)
                      _InfoChip(
                        icon: _painIcon(pain),
                        label: "ปวด ${pain.toStringAsFixed(1)}",
                        color: _painColor(pain),
                        bgColor: _painColor(pain).withOpacity(0.1),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _painIcon(double pain) {
    if (pain <= 1.5) return Icons.sentiment_very_satisfied_rounded;
    if (pain <= 2.5) return Icons.sentiment_satisfied_rounded;
    if (pain <= 3.5) return Icons.sentiment_neutral_rounded;
    if (pain <= 4.5) return Icons.sentiment_dissatisfied_rounded;
    return Icons.sentiment_very_dissatisfied_rounded;
  }

  Color _painColor(double pain) {
    if (pain <= 1.5) return const Color(0xFF66BB6A);
    if (pain <= 2.5) return const Color(0xFFFDD835);
    if (pain <= 3.5) return const Color(0xFFFF9800);
    if (pain <= 4.5) return const Color(0xFFF44336);
    return const Color(0xFF880E4F);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color, bgColor;
  final IconData? icon;

  const _InfoChip({
    required this.label,
    required this.color,
    required this.bgColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

// ── Timeline Row ──────────────────────────────────────────────────────────────
class _TimelineRow extends StatelessWidget {
  final int cycleNo;
  final _CycleData cycle;
  final HealthDashboardController controller;
  final bool isLast, isLatest;

  const _TimelineRow({
    required this.cycleNo,
    required this.cycle,
    required this.controller,
    required this.isLast,
    required this.isLatest,
  });

  @override
  Widget build(BuildContext context) {
    final dur = cycle.durationDays;

    // สีแท่งตามความยาว
    Color barColor;
    if (dur <= 3) {
      barColor = const Color(0xFF90CAF9);
    } else if (dur <= 5) barColor = const Color(0xFFF05A42);
    else               barColor = const Color(0xFFB71C1C);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dot + Line ──
          SizedBox(
            width: 40,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isLatest)
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF05A42).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: isLatest
                            ? const Color(0xFFF05A42)
                            : const Color(0xFFBDBDBD),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: isLatest
                            ? [const BoxShadow(
                                color: Color(0x33F05A42),
                                blurRadius: 6)]
                            : [],
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "รอบที่ $cycleNo",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                            fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      if (isLatest)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF05A42),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("ล่าสุด",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${controller.formatDateShort(cycle.startDate)} — ${controller.formatDateShort(cycle.endDate)}",
                    style: const TextStyle(
                        color: Color(0xFF757575), fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  // Duration bar
                  Row(
                    children: [
                      // แท่งความยาวรอบ (max = 10 วัน)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              Container(height: 8, color: const Color(0xFFF5F5F5)),
                              FractionallySizedBox(
                                widthFactor: (dur / 10).clamp(0.05, 1.0),
                                child: Container(
                                    height: 8, color: barColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "$dur วัน",
                        style: TextStyle(
                            color: barColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Text("🌸", style: TextStyle(fontSize: 36)),
        const SizedBox(height: 10),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF9E9E9E), fontSize: 13, height: 1.6)),
      ],
    ),
  );
}

// ── Helper ─────────────────────────────────────────────────────────────────────
BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  boxShadow: [
    BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 3)),
  ],
);

// ── Getter ผ่าน Obx ───────────────────────────────────────────────────────────
extension on _HealthDashboardPageState {
  HealthDashboardController get controller => c;
}
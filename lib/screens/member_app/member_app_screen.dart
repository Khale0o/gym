import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/apex_progress_bar.dart';
import 'package:gymsaas/widgets/occupancy_ring.dart';
import 'package:gymsaas/widgets/hourly_chart.dart';
import 'package:gymsaas/widgets/line_chart_widget.dart';

class MemberAppScreen extends ConsumerStatefulWidget {
  const MemberAppScreen({super.key});

  @override
  ConsumerState<MemberAppScreen> createState() => _MemberAppScreenState();
}

class _MemberAppScreenState extends ConsumerState<MemberAppScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(currentLinkedMemberProvider);
    return Scaffold(
      backgroundColor: bgDark,
      body: memberAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: gold)),
        error: (error, _) => Center(
          child: ApexText(
            'Member profile could not be loaded: $error',
            color: redAlert,
            textAlign: TextAlign.center,
          ),
        ),
        data: (member) {
          if (member == null) {
            return const Center(
              child: ApexText(
                'No linked member profile found for this account.',
                color: Color(0xFF888888),
                textAlign: TextAlign.center,
              ),
            );
          }
          return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GoldHeading('Member App Preview', fontSize: 16),
            const SizedBox(height: 4),
            const ApexText('Mobile simulation — Ahmed Khalil\'s view',
                fontSize: 11, color: Color(0xFF555555)),
            const SizedBox(height: 20),
            // Phone frame
            Container(
              width: 360,
              height: 720,
              decoration: BoxDecoration(
                color: const Color(0xFF080808),
                borderRadius: BorderRadius.circular(44),
                border: Border.all(color: const Color(0xFF2A2A2A), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.08),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(41),
                child: Column(
                  children: [
                    // Notch
                    Container(
                      height: 36,
                      color: const Color(0xFF050505),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: IndexedStack(
                        index: _tab,
                        children: const [
                          _HomeTab(),
                          _WorkoutTab(),
                          _NutritionTab(),
                          _ProgressTab(),
                        ],
                      ),
                    ),
                    // Bottom nav
                    Container(
                      color: const Color(0xFF0E0E0E),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _AppNavItem(icon: Icons.home_rounded, label: 'Home', idx: 0, current: _tab, onTap: (i) => setState(() => _tab = i)),
                          _AppNavItem(icon: Icons.fitness_center_rounded, label: 'Workout', idx: 1, current: _tab, onTap: (i) => setState(() => _tab = i)),
                          _AppNavItem(icon: Icons.restaurant_rounded, label: 'Nutrition', idx: 2, current: _tab, onTap: (i) => setState(() => _tab = i)),
                          _AppNavItem(icon: Icons.bar_chart_rounded, label: 'Progress', idx: 3, current: _tab, onTap: (i) => setState(() => _tab = i)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
        },
      ),
    );
  }
}

class _AppNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int idx;
  final int current;
  final Function(int) onTap;

  const _AppNavItem({
    required this.icon, required this.label,
    required this.idx, required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = idx == current;
    return GestureDetector(
      onTap: () => onTap(idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? gold : const Color(0xFF444444), size: 20),
          const SizedBox(height: 3),
          ApexText(label, fontSize: 9,
              color: active ? gold : const Color(0xFF444444)),
        ],
      ),
    );
  }
}

// ── Home Tab ────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ApexText('Good morning,', fontSize: 11),
                  GoldHeading('Ahmed 👋', fontSize: 16),
                ],
              ),
              const Spacer(),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: goldDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: ApexText('AK', fontSize: 12,
                      color: Color(0xFFE8E8E8), fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Plan card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1200), Color(0xFF0E0A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: gold.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    ApexText('Elite Plan', fontSize: 11, color: gold,
                        fontWeight: FontWeight.w600),
                    Spacer(),
                    ApexText('22 days left', fontSize: 10,
                        color: Color(0xFF888888)),
                  ],
                ),
                const SizedBox(height: 10),
                const ApexProgressBar(value: 8, max: 30, color: gold, height: 4),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PhoneStat(label: 'Sessions', value: '42'),
                    _PhoneStat(label: 'Streak', value: '7 🔥'),
                    _PhoneStat(label: 'Rank', value: '#4'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Occupancy
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderDark),
            ),
            child: Column(
              children: [
                const OccupancyRing(current: 23, capacity: 60, compact: true),
                const SizedBox(height: 8),
                const ApexText('Perfect time to visit!',
                    fontSize: 11, color: greenSuccess,
                    fontWeight: FontWeight.w600),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const GoldHeading('Today\'s Crowd', fontSize: 12),
          const SizedBox(height: 8),
          const HourlyChart(),
          const SizedBox(height: 16),
          // NFC check-in button
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [gold, goldDark]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.3),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.nfc_rounded, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  ApexText('NFC Check-in', fontSize: 14,
                      color: Colors.black, fontWeight: FontWeight.w700),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneStat extends StatelessWidget {
  final String label;
  final String value;
  const _PhoneStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ApexText(value, fontSize: 14, color: const Color(0xFFE8E8E8),
            fontWeight: FontWeight.w700),
        const SizedBox(height: 2),
        ApexText(label, fontSize: 9, color: const Color(0xFF888888)),
      ],
    );
  }
}

// ── Workout Tab ─────────────────────────────────────────────────────────────
class _WorkoutTab extends StatelessWidget {
  const _WorkoutTab();

  static const _exercises = [
    {'name': 'Bench Press', 'sets': '4×8', 'done': true},
    {'name': 'Squat', 'sets': '4×6', 'done': true},
    {'name': 'Deadlift', 'sets': '3×5', 'done': false},
    {'name': 'Overhead Press', 'sets': '3×8', 'done': false},
    {'name': 'Pull-ups', 'sets': '3×10', 'done': false},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: greenSuccess.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: greenSuccess.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.play_circle_rounded, color: greenSuccess, size: 20),
                SizedBox(width: 8),
                ApexText('Session Active · 00:42:18',
                    fontSize: 12, color: greenSuccess, fontWeight: FontWeight.w600),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const GoldHeading('Push Day A', fontSize: 14),
          const SizedBox(height: 12),
          ..._exercises.map((ex) => _ExerciseRow(
            name: ex['name'] as String,
            sets: ex['sets'] as String,
            done: ex['done'] as bool,
          )),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final String name;
  final String sets;
  final bool done;
  const _ExerciseRow({required this.name, required this.sets, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: done ? greenSuccess.withOpacity(0.06) : cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done ? greenSuccess.withOpacity(0.2) : borderDark,
        ),
      ),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: done ? greenSuccess : const Color(0xFF333333), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: ApexText(name, fontSize: 13,
                color: done ? const Color(0xFF888888) : const Color(0xFFCCCCCC),
                fontWeight: done ? FontWeight.w400 : FontWeight.w500),
          ),
          ApexText(sets, fontSize: 11, color: gold),
        ],
      ),
    );
  }
}

// ── Nutrition Tab ────────────────────────────────────────────────────────────
class _NutritionTab extends StatelessWidget {
  const _NutritionTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Today\'s Nutrition', fontSize: 14),
          const SizedBox(height: 16),
          _MacroCard(label: 'Calories', actual: 2650, target: 2800,
              unit: 'kcal', color: gold),
          const SizedBox(height: 10),
          _MacroCard(label: 'Protein', actual: 162, target: 180,
              unit: 'g', color: blueInfo),
          const SizedBox(height: 10),
          _MacroCard(label: 'Carbs', actual: 310, target: 350,
              unit: 'g', color: orangeWarning),
          const SizedBox(height: 20),
          const GoldHeading('Meals', fontSize: 12),
          const SizedBox(height: 10),
          ...[ 
            {'name': 'Breakfast — Eggs & Oats', 'kcal': '620 kcal', 'done': true},
            {'name': 'Pre-Workout Shake', 'kcal': '280 kcal', 'done': true},
            {'name': 'Lunch — Chicken & Rice', 'kcal': '850 kcal', 'done': true},
            {'name': 'Post-Workout Meal', 'kcal': '700 kcal', 'done': false},
            {'name': 'Dinner', 'kcal': '350 kcal', 'done': false},
          ].map((m) => _MealRow(
            name: m['name'] as String,
            kcal: m['kcal'] as String,
            done: m['done'] as bool,
          )),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final double actual;
  final double target;
  final String unit;
  final Color color;

  const _MacroCard({
    required this.label, required this.actual, required this.target,
    required this.unit, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (actual / target * 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ApexText(label, fontSize: 12, color: const Color(0xFF888888)),
              const Spacer(),
              ApexText('${actual.round()} / ${target.round()} $unit',
                  fontSize: 10, color: const Color(0xFF555555)),
              const SizedBox(width: 6),
              ApexText('$pct%', fontSize: 11, color: color,
                  fontWeight: FontWeight.w700),
            ],
          ),
          const SizedBox(height: 8),
          ApexProgressBar(value: actual, max: target, color: color, height: 5),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final String name;
  final String kcal;
  final bool done;
  const _MealRow({required this.name, required this.kcal, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: done ? greenSuccess.withOpacity(0.05) : cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: done ? greenSuccess.withOpacity(0.15) : borderDark,
        ),
      ),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: done ? greenSuccess : const Color(0xFF333333), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: ApexText(name, fontSize: 12,
                color: done ? const Color(0xFF666666) : const Color(0xFFBBBBBB)),
          ),
          ApexText(kcal, fontSize: 10, color: const Color(0xFF555555)),
        ],
      ),
    );
  }
}

// ── Progress Tab ─────────────────────────────────────────────────────────────
class _ProgressTab extends StatelessWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Strength Progress', fontSize: 14),
          const SizedBox(height: 16),
          LineChartWidget(
            xLabels: const ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'],
            series: const [
              LineChartSeries(
                label: 'Bench', color: gold,
                values: [80, 82.5, 85, 85, 87.5, 90],
              ),
              LineChartSeries(
                label: 'Squat', color: blueInfo,
                values: [100, 105, 107.5, 110, 110, 112.5],
              ),
              LineChartSeries(
                label: 'Deadlift', color: greenSuccess,
                values: [120, 125, 130, 132.5, 135, 140],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: gold.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: gold, size: 14),
                    SizedBox(width: 6),
                    ApexText('AI Recommendation', fontSize: 11,
                        color: gold, fontWeight: FontWeight.w600),
                  ],
                ),
                SizedBox(height: 10),
                ApexText(
                  'Excellent progress! Your bench press has improved +12.5% over 6 weeks. Consider adding a deload week to prevent overtraining. Focus on leg volume — your squat is progressing but lagging behind your upper body.',
                  fontSize: 11,
                  color: Color(0xFF888888),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

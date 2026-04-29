import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/core/helpers.dart';
import 'package:gymsaas/data/mock_data.dart';
import 'package:gymsaas/providers/occupancy_provider.dart';
import 'package:gymsaas/providers/checkins_provider.dart';
import 'package:gymsaas/providers/members_provider.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/apex_card.dart';
import 'package:gymsaas/widgets/apex_badge.dart';
import 'package:gymsaas/widgets/occupancy_ring.dart';
import 'package:gymsaas/widgets/hourly_chart.dart';
import 'package:gymsaas/widgets/shimmer_placeholder.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _seedLoading = false;
  String? _seedMessage;

  Future<void> _runDemoSeed() async {
    if (!kDebugMode || _seedLoading) return;

    setState(() {
      _seedLoading = true;
      _seedMessage = null;
    });

    try {
      await seedFirestore();
      if (!mounted) return;
      setState(() {
        _seedMessage = 'Demo data seeded successfully.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _seedMessage = 'Demo seed failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _seedLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final occupancyAsync = ref.watch(occupancyStreamProvider);
    final membersAsync = ref.watch(membersProvider);
    final checkinsAsync = ref.watch(recentCheckinsProvider);

    return Scaffold(
      backgroundColor: bgDark,
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: gold)),
        error: (e, _) => Center(child: ApexText('Error: $e', color: redAlert)),
        data: (members) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              final isWide = constraints.maxWidth > 1100;

              return SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      showDebugSeed: kDebugMode && members.isEmpty,
                      seedLoading: _seedLoading,
                      seedMessage: _seedMessage,
                      onSeedPressed: _runDemoSeed,
                    ),
                    const SizedBox(height: 24),
                    _KpiRow(members: members, compact: isMobile, wide: isWide),
                    const SizedBox(height: 24),
                    if (members.isEmpty) ...[
                      _EmptyMembersState(
                        showDebugSeed: kDebugMode,
                        seedLoading: _seedLoading,
                        seedMessage: _seedMessage,
                        onSeedPressed: _runDemoSeed,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (isMobile) ...[
                      _OccupancySection(occupancyAsync: occupancyAsync),
                      const SizedBox(height: 16),
                      _WeeklyChart(),
                      const SizedBox(height: 16),
                      _HourlySection(),
                      const SizedBox(height: 16),
                      _LiveCheckins(checkins: checkinsAsync),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _OccupancySection(occupancyAsync: occupancyAsync),
                          ),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _WeeklyChart()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _HourlySection()),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _LiveCheckins(checkins: checkinsAsync)),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool showDebugSeed;
  final bool seedLoading;
  final String? seedMessage;
  final VoidCallback onSeedPressed;

  const _Header({
    required this.showDebugSeed,
    required this.seedLoading,
    required this.seedMessage,
    required this.onSeedPressed,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GoldHeading('$greeting, Admin', fontSize: 20),
                  const SizedBox(height: 4),
                  ApexText(
                    DateFormat('EEEE, d MMMM yyyy').format(now),
                    fontSize: 12,
                    color: const Color(0xFF555555),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: greenSuccess.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: greenSuccess.withOpacity(0.2)),
              ),
              child: Row(
                children: const [
                  _PulseDot(),
                  SizedBox(width: 6),
                  ApexText(
                    'Live',
                    fontSize: 11,
                    color: greenSuccess,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDebugSeed) ...[
          const SizedBox(height: 16),
          _DebugSeedBanner(
            seedLoading: seedLoading,
            seedMessage: seedMessage,
            onSeedPressed: onSeedPressed,
          ),
        ],
      ],
    );
  }
}

class _DebugSeedBanner extends StatelessWidget {
  final bool seedLoading;
  final String? seedMessage;
  final VoidCallback onSeedPressed;

  const _DebugSeedBanner({
    required this.seedLoading,
    required this.seedMessage,
    required this.onSeedPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: orangeWarning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: orangeWarning.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.developer_mode_rounded, color: orangeWarning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ApexText(
                  'Development / Demo Seeding',
                  fontSize: 12,
                  color: orangeWarning,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 4),
                ApexText(
                  seedMessage ??
                      'No members were found. Demo seeding is manual only and available in debug mode.',
                  fontSize: 11,
                  color: const Color(0xFFBBBBBB),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: seedLoading ? null : onSeedPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: orangeWarning,
              foregroundColor: Colors.black,
            ),
            child: seedLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text('Seed Demo Data'),
          ),
        ],
      ),
    );
  }
}

class _EmptyMembersState extends StatelessWidget {
  final bool showDebugSeed;
  final bool seedLoading;
  final String? seedMessage;
  final VoidCallback onSeedPressed;

  const _EmptyMembersState({
    required this.showDebugSeed,
    required this.seedLoading,
    required this.seedMessage,
    required this.onSeedPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('No Member Data Yet'),
          const SizedBox(height: 10),
          const ApexText(
            'The dashboard is connected, but no members are currently available in Firestore.',
            fontSize: 12,
            color: Color(0xFF888888),
          ),
          const SizedBox(height: 8),
          const ApexText(
            'Opening this screen no longer writes demo data automatically.',
            fontSize: 11,
            color: Color(0xFF555555),
          ),
          if (showDebugSeed) ...[
            const SizedBox(height: 14),
            _DebugSeedBanner(
              seedLoading: seedLoading,
              seedMessage: seedMessage,
              onSeedPressed: onSeedPressed,
            ),
          ],
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
        ..repeat(reverse: true);
  late final Animation<double> _anim =
      Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: greenSuccess.withOpacity(_anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String delta;
  final bool positive;
  final Color iconColor;
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
    required this.positive,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final deltaColor = positive ? greenSuccess : redAlert;
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: deltaColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ApexText(
                  delta,
                  fontSize: 10,
                  color: deltaColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GoldHeading(value, fontSize: 20),
          const SizedBox(height: 4),
          ApexText(label, fontSize: 11, color: const Color(0xFF555555)),
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final List members;
  final bool compact;
  final bool wide;
  const _KpiRow({required this.members, this.compact = false, this.wide = true});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = compact ? 2 : (wide ? 4 : 3);
    final ratio = compact ? 1.3 : 1.6;
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: ratio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _KpiCard(
          icon: Icons.people_rounded,
          label: 'Active Members',
          value: '142',
          delta: '▲ 12%',
          positive: true,
          iconColor: blueInfo,
        ),
        _KpiCard(
          icon: Icons.payments_rounded,
          label: 'Today Revenue',
          value: '4,280 EGP',
          delta: '▲ 8%',
          positive: true,
          iconColor: gold,
        ),
        _KpiCard(
          icon: Icons.fitness_center_rounded,
          label: 'Sessions Today',
          value: '34',
          delta: '▼ 5%',
          positive: false,
          iconColor: orangeWarning,
        ),
        _KpiCard(
          icon: Icons.autorenew_rounded,
          label: 'Renewals Due',
          value: '15',
          delta: '● Today',
          positive: true,
          iconColor: greenSuccess,
        ),
      ],
    );
  }
}

class _OccupancySection extends ConsumerStatefulWidget {
  final AsyncValue<double> occupancyAsync;
  const _OccupancySection({required this.occupancyAsync});
  @override
  ConsumerState<_OccupancySection> createState() => _OccupancySectionState();
}

class _OccupancySectionState extends ConsumerState<_OccupancySection> {
  @override
  Widget build(BuildContext context) {
    return ApexCard(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Live Occupancy'),
          const SizedBox(height: 20),
          widget.occupancyAsync.when(
            loading: () => const ShimmerCard(),
            error: (_, __) => const ApexText('Unavailable'),
            data: (count) {
              final pct = (count / gymCapacity * 100).clamp(0, 100).toDouble();
              return Column(
                children: [
                  OccupancyRing(current: count, capacity: gymCapacity),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: Color(0xFF444444), size: 16),
                      const SizedBox(width: 8),
                      const ApexText('Simulate', fontSize: 11),
                      const Spacer(),
                      ApexText('${count.round()}', fontSize: 11, color: gold),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Slider(
                    value: count.clamp(0, gymCapacity.toDouble()),
                    min: 0,
                    max: gymCapacity.toDouble(),
                    divisions: gymCapacity,
                    activeColor: ocColor(pct),
                    inactiveColor: borderDark,
                    onChanged: (v) => updateOccupancy(v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      _StatPill(label: 'Avg Visit', value: '48 min'),
                      SizedBox(width: 12),
                      _StatPill(label: 'Peak', value: '18:00–20:00'),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ApexText(label, fontSize: 9, color: const Color(0xFF444444), letterSpacing: 1),
            const SizedBox(height: 4),
            ApexText(
              value,
              fontSize: 13,
              color: const Color(0xFFCCCCCC),
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const values = [28.0, 34.0, 31.0, 38.0, 42.0, 36.0, 34.0];
    final today = DateTime.now().weekday - 1;
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Weekly Sessions'),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isToday = i == today;
                final norm = values[i] / values.reduce((a, b) => a > b ? a : b);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400 + i * 60),
                          curve: Curves.easeOut,
                          height: norm * 80,
                          decoration: BoxDecoration(
                            gradient: isToday ? const LinearGradient(colors: [goldLight, gold]) : null,
                            color: isToday ? null : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(4),
                            border: isToday ? Border.all(color: gold.withOpacity(0.4)) : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ApexText(days[i], fontSize: 9, color: isToday ? gold : const Color(0xFF444444)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              GoldHeading('Hourly Crowd'),
              Spacer(),
              _Legend(color: gold, label: 'Now'),
              SizedBox(width: 12),
              _Legend(color: Color(0xFF2A2A2A), label: 'Other'),
            ],
          ),
          const SizedBox(height: 12),
          const HourlyChart(),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['0', '6', '12', '18', '23']
                .map((h) => ApexText(h, fontSize: 9, color: const Color(0xFF444444)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        ApexText(label, fontSize: 10, color: const Color(0xFF555555)),
      ],
    );
  }
}

class _LiveCheckins extends StatelessWidget {
  final AsyncValue checkins;
  const _LiveCheckins({required this.checkins});
  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              GoldHeading('Live Check-ins'),
              Spacer(),
              Icon(Icons.circle, color: greenSuccess, size: 7),
            ],
          ),
          const SizedBox(height: 12),
          checkins.when(
            loading: () => Column(
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: ShimmerCard(),
                ),
              ),
            ),
            error: (_, __) => const ApexText('Error loading'),
            data: (list) => list.isEmpty
                ? const ApexText('No check-ins yet')
                : Column(
                    children: List.generate(list.length > 5 ? 5 : list.length, (i) {
                      final ci = list[i];
                      final isNewest = i == 0;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isNewest ? greenSuccess.withOpacity(0.05) : const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isNewest ? greenSuccess.withOpacity(0.2) : borderDark,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF151515),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: ApexText(
                                  ci.name.isNotEmpty ? ci.name[0].toUpperCase() : '?',
                                  fontSize: 13,
                                  color: gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ApexText(
                                    ci.name,
                                    fontSize: 12,
                                    color: const Color(0xFFCCCCCC),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      ApexBadge(
                                        text: ci.method,
                                        color: ci.method == 'NFC'
                                            ? blueInfo
                                            : ci.method == 'QR'
                                                ? greenSuccess
                                                : orangeWarning,
                                      ),
                                      const SizedBox(width: 6),
                                      ApexText(ci.plan, fontSize: 9, color: const Color(0xFF444444)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ApexText(timeAgo(ci.time), fontSize: 10, color: const Color(0xFF444444)),
                          ],
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

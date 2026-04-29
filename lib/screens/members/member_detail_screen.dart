import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/core/helpers.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/apex_card.dart';
import 'package:gymsaas/widgets/apex_badge.dart';
import 'package:gymsaas/widgets/apex_progress_bar.dart';
import 'package:gymsaas/widgets/sparkline_widget.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String id;
  const MemberDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gymMemberByIdProvider(id));

    return Scaffold(
      backgroundColor: bgDark,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: gold)),
        error: (e, _) => Center(child: ApexText('Error: $e', color: redAlert)),
        data: (member) {
          if (member == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ApexText('Member not found', color: Color(0xFF555555)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/members'),
                    child: const ApexText('← Back to Members', color: gold),
                  ),
                ],
              ),
            );
          }
          return _DetailBody(member: member);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Member member;
  const _DetailBody({required this.member});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final padding = isMobile ? 16.0 : 24.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => context.go('/members'),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, color: Color(0xFF555555), size: 16),
                    SizedBox(width: 6),
                    ApexText('Members', fontSize: 12, color: Color(0xFF555555)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Main content
              if (isMobile) ...[
                // ترتيب عمودي للجوال
                _LeftColumn(member: member),
                const SizedBox(height: 16),
                _RightColumn(member: member),
              ] else ...[
                // ترتيب جانبي للكمبيوتر
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 280, child: _LeftColumn(member: member)),
                    const SizedBox(width: 20),
                    Expanded(child: _RightColumn(member: member)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────
// العمود الأيسر (يستخدم كما هو من الكود السابق مع تعديل طفيف للمسافات)
class _LeftColumn extends StatelessWidget {
  final Member member;
  const _LeftColumn({required this.member});

  @override
  Widget build(BuildContext context) {
    final risk = churnRisk(member);
    final rc = churnColor(risk);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Column(
      children: [
        ApexCard(
          glow: true,
          child: Column(
            children: [
              Container(
                width: isMobile ? 56 : 72,
                height: isMobile ? 56 : 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [avatarColor(member.av), goldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: ApexText(member.av, fontSize: isMobile ? 18 : 24,
                      color: const Color(0xFFE8E8E8), fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(height: isMobile ? 8 : 12),
              GoldHeading(member.name, fontSize: isMobile ? 14 : 16),
              SizedBox(height: isMobile ? 6 : 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ApexBadge(
                    text: member.plan,
                    color: member.plan == 'Elite' ? gold : member.plan == 'Premium' ? blueInfo : const Color(0xFF555555),
                  ),
                  const SizedBox(width: 8),
                  ApexBadge(
                    text: '${risk[0].toUpperCase()}${risk.substring(1)} Risk',
                    color: rc,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
        // Stats
        ApexCard(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              _StatRow('Goal', member.goal.replaceAll('_', ' ').toUpperCase()),
              _StatRow('Sessions', '${member.sessions} total'),
              _StatRow('Streak', '🔥 ${member.streak} days'),
              _StatRow('Attendance', '${(member.att * 100).round()}%'),
              _StatRow('Body Fat', '${member.bf}%'),
              _StatRow('Muscle Mass', '${member.mm} kg'),
              _StatRow('Last Seen', member.last),
              _StatRow('Check-in', member.tag ?? 'Manual'),
              _StatRow('Sub. Left', '${member.subLeft} days'),
              if ((member.currentPlanName ?? '').isNotEmpty)
                _StatRow('Current Plan', member.currentPlanName!),
              if ((member.subscriptionStatus ?? '').isNotEmpty)
                _StatRow('Sub. Status', member.subscriptionStatus!),
              if (member.subscriptionEndDate != null)
                _StatRow(
                  'Sub. Ends',
                  '${member.subscriptionEndDate!.year}-${member.subscriptionEndDate!.month.toString().padLeft(2, '0')}-${member.subscriptionEndDate!.day.toString().padLeft(2, '0')}',
                ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
        if (member.injuries.isNotEmpty)
          ApexCard(
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: orangeWarning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: ApexText(
                    'Injuries: ${member.injuries.join(', ')}',
                    fontSize: 11,
                    color: orangeWarning,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: isMobile ? 10 : 12),
        ApexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GoldHeading('Nutrition', fontSize: 13),
              const SizedBox(height: 12),
              _NutBar(label: 'Calories', actual: member.nut.ca, target: member.nut.ct, unit: 'kcal', color: gold),
              const SizedBox(height: 10),
              _NutBar(label: 'Protein', actual: member.nut.pa, target: member.nut.pt, unit: 'g', color: blueInfo),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: borderDark)),
      ),
      child: Row(
        children: [
          Expanded(child: ApexText(label, fontSize: 11, color: const Color(0xFF555555))),
          ApexText(value, fontSize: 11, color: const Color(0xFFCCCCCC), fontWeight: FontWeight.w500),
        ],
      ),
    );
  }
}

class _NutBar extends StatelessWidget {
  final String label;
  final double actual;
  final double target;
  final String unit;
  final Color color;

  const _NutBar({required this.label, required this.actual, required this.target, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (actual / target * 100).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ApexText(label, fontSize: 11, color: const Color(0xFF888888)),
            const Spacer(),
            ApexText('${actual.round()} / ${target.round()} $unit', fontSize: 10, color: const Color(0xFF555555)),
            const SizedBox(width: 6),
            ApexText('$pct%', fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ],
        ),
        const SizedBox(height: 5),
        ApexProgressBar(value: actual, max: target, color: color),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────
// العمود الأيمن (تقدم القوة) – أصبح قابلاً للتكيف
class _RightColumn extends StatelessWidget {
  final Member member;
  const _RightColumn({required this.member});

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Strength Progress', fontSize: 16),
          const SizedBox(height: 4),
          const ApexText('6-week progression per lift', fontSize: 11, color: Color(0xFF555555)),
          const SizedBox(height: 20),
          if (member.lifts.isEmpty)
            const ApexText('No lift data recorded', color: Color(0xFF444444))
          else
            ...member.lifts.map((lift) => _LiftCard(lift: lift)),
        ],
      ),
    );
  }
}

class _LiftCard extends StatelessWidget {
  final dynamic lift;
  const _LiftCard({required this.lift});

  @override
  Widget build(BuildContext context) {
    final stalled = lift.isStalled as bool;
    final ws = lift.ws as List<double>;
    final start = ws.isNotEmpty ? ws.first : 0.0;
    final end = ws.isNotEmpty ? ws.last : 0.0;
    final gain = end - start;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stalled ? redAlert.withValues(alpha: 0.3) : borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ApexText(lift.ex as String, fontSize: 13,
                    color: const Color(0xFFCCCCCC), fontWeight: FontWeight.w600),
              ),
              if (stalled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: redAlert.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: redAlert.withValues(alpha: 0.3)),
                  ),
                  child: const ApexText('STALLED', fontSize: 9, color: redAlert, fontWeight: FontWeight.w700, letterSpacing: 1),
                )
              else
                ApexText(
                  gain >= 0 ? '+${gain.toStringAsFixed(1)} kg' : '${gain.toStringAsFixed(1)} kg',
                  fontSize: 11,
                  color: gain >= 0 ? greenSuccess : redAlert,
                  fontWeight: FontWeight.w600,
                ),
            ],
          ),
          const SizedBox(height: 10),
          SparklineWidget(values: ws),
          const SizedBox(height: 8),
          Row(
            children: [
              ApexText('Start: ${start.toStringAsFixed(1)} kg', fontSize: 10, color: const Color(0xFF555555)),
              const Spacer(),
              ApexText('Now: ${end.toStringAsFixed(1)} kg', fontSize: 10, color: const Color(0xFF888888)),
            ],
          ),
        ],
      ),
    );
  }
}

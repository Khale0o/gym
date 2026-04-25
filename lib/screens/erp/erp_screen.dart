import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/core/helpers.dart';
import 'package:gymsaas/providers/erp_provider.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/apex_card.dart';
import 'package:gymsaas/widgets/apex_badge.dart';
import 'package:gymsaas/widgets/shimmer_placeholder.dart';

class ErpScreen extends ConsumerWidget {
  const ErpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    final txAsync = ref.watch(transactionsProvider);
    final staffAsync = ref.watch(staffProvider);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            final padding = isMobile ? 16.0 : 24.0;
            final kpiColumns = isMobile ? 2 : 4;

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GoldHeading('Finance & Operations', fontSize: 18),
                  SizedBox(height: isMobile ? 16 : 24),

                  // KPI Cards
                  GridView.count(
                    crossAxisCount: kpiColumns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isMobile ? 1.3 : 1.6,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      _ErpKpi(
                        icon: Icons.trending_up_rounded,
                        label: 'Monthly Revenue',
                        value: '84,200 EGP',
                        delta: '▲ 18%',
                        positive: true,
                        color: greenSuccess,
                      ),
                      _ErpKpi(
                        icon: Icons.trending_down_rounded,
                        label: 'Expenses',
                        value: '32,400 EGP',
                        delta: '▼ 3%',
                        positive: true,
                        color: redAlert,
                      ),
                      _ErpKpi(
                        icon: Icons.account_balance_rounded,
                        label: 'Net Profit',
                        value: '51,800 EGP',
                        delta: '▲ 22%',
                        positive: true,
                        color: gold,
                      ),
                      _ErpKpi(
                        icon: Icons.badge_rounded,
                        label: 'Staff on Duty',
                        value: '6 of 9',
                        delta: '● Active',
                        positive: true,
                        color: blueInfo,
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 24),

                  // الأقسام الثلاثة السفلية (متجاوبة)
                  if (isMobile)
                    Column(
                      children: [
                        _buildPlansSection(plansAsync),
                        const SizedBox(height: 16),
                        _buildTreasurySection(txAsync),
                        const SizedBox(height: 16),
                        _buildStaffSection(staffAsync),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildPlansSection(plansAsync)),
                        const SizedBox(width: 16),
                        Expanded(flex: 4, child: _buildTreasurySection(txAsync)),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: _buildStaffSection(staffAsync)),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════ أقسام البناء ═══════════════════
  Widget _buildPlansSection(AsyncValue plansAsync) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Membership Plans'),
          const SizedBox(height: 16),
          plansAsync.when(
            loading: () => Column(
              children: List.generate(3,
                  (_) => const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerCard())),
            ),
            error: (_, __) => const ApexText('Error loading plans'),
            data: (plans) {
              if (plans.isEmpty) {
                return const ApexText('No plans — tap Seed Data on Dashboard',
                    color: Color(0xFF444444));
              }
              // ★ الحل: إضافة <Widget> بعد map
              final planWidgets = plans.map<Widget>((p) => _PlanCard(plan: p)).toList();
              return Column(children: planWidgets);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTreasurySection(AsyncValue txAsync) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GoldHeading('Treasury'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: greenSuccess.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: greenSuccess.withOpacity(0.2)),
                ),
                child: const ApexText('April 2025', fontSize: 10, color: greenSuccess),
              ),
            ],
          ),
          const SizedBox(height: 16),
          txAsync.when(
            loading: () => Column(
              children: List.generate(5,
                  (_) => const Padding(padding: EdgeInsets.only(bottom: 8), child: ShimmerCard())),
            ),
            error: (_, __) => const ApexText('Error loading transactions'),
            data: (txs) => txs.isEmpty
                ? const ApexText('No transactions yet', color: Color(0xFF444444))
                : Column(
                    children: txs.map<Widget>((t) => _TxRow(tx: t)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSection(AsyncValue staffAsync) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Staff'),
          const SizedBox(height: 16),
          staffAsync.when(
            loading: () => Column(
              children: List.generate(5,
                  (_) => const Padding(padding: EdgeInsets.only(bottom: 8), child: ShimmerCard())),
            ),
            error: (_, __) => const ApexText('Error loading staff'),
            data: (staff) => staff.isEmpty
                ? const ApexText('No staff data', color: Color(0xFF444444))
                : Column(
                    children: staff.map<Widget>((s) => _StaffRow(staff: s)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════ عناصر الواجهة الثانوية ═══════════════════

class _ErpKpi extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String delta;
  final bool positive;
  final Color color;

  const _ErpKpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
    required this.positive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dc = positive ? greenSuccess : redAlert;
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: dc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ApexText(delta, fontSize: 9, color: dc, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          GoldHeading(value, fontSize: 16),
          const SizedBox(height: 3),
          ApexText(label, fontSize: 10, color: const Color(0xFF555555)),
        ],
      ),
    );
  }
}

// ★★★ _PlanCard مع تعديل استخراج البيانات الآمن ★★★
class _PlanCard extends StatelessWidget {
  final dynamic plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    String name;
    double price;
    int membersCount;

    if (plan is Map) {
      name = (plan['name'] as String?) ?? 'Unknown';
      price = (plan['price'] as num?)?.toDouble() ?? 0.0;
      membersCount = (plan['membersCount'] as num?)?.toInt() ?? 0;
    } else {
      try {
        name = plan.name as String? ?? 'Unknown';
        price = (plan.price as num?)?.toDouble() ?? 0.0;
        membersCount = (plan.membersCount as num?)?.toInt() ?? 0;
      } catch (_) {
        name = 'Unknown';
        price = 0.0;
        membersCount = 0;
      }
    }

    final isElite = name == 'Elite';
    final isPremium = name == 'Premium';
    final c = isElite ? gold : isPremium ? blueInfo : const Color(0xFF555555);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.workspace_premium_rounded, color: c, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApexText(name,
                    fontSize: 13,
                    color: const Color(0xFFCCCCCC),
                    fontWeight: FontWeight.w600),
                ApexText('$membersCount members',
                    fontSize: 10, color: const Color(0xFF555555)),
              ],
            ),
          ),
          ApexText(
            '${formatCurrency(price)}/mo',
            fontSize: 13,
            color: c,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final dynamic tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == 'income';
    final c = isIncome ? greenSuccess : redAlert;
    final prefix = isIncome ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderDark),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: ApexText(tx.category as String, fontSize: 12, color: const Color(0xFF888888)),
          ),
          ApexText(
            '$prefix${formatCurrency(tx.amount as double)}',
            fontSize: 12,
            color: c,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  final dynamic staff;
  const _StaffRow({required this.staff});

  @override
  Widget build(BuildContext context) {
    final onDuty = staff.onDuty as bool;
    final initials = (staff.name as String)
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: avatarColor(initials),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: ApexText(initials, fontSize: 11, color: const Color(0xFFE8E8E8), fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApexText(staff.name as String, fontSize: 12, color: const Color(0xFFCCCCCC), fontWeight: FontWeight.w500),
                ApexText(staff.role as String, fontSize: 10, color: const Color(0xFF555555)),
              ],
            ),
          ),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: onDuty ? greenSuccess : const Color(0xFF333333),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
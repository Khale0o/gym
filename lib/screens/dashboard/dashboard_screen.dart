import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymsaas/core/helpers.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/models/dashboard_summary.dart';
import 'package:gymsaas/models/subscription.dart';
import 'package:gymsaas/models/transaction_model.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';
import 'package:gymsaas/widgets/apex_badge.dart';
import 'package:gymsaas/widgets/apex_card.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/occupancy_ring.dart';
import 'package:gymsaas/widgets/shimmer_placeholder.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(currentGymIdProvider)?.trim();
    final summaryAsync = gymId == null || gymId.isEmpty
        ? AsyncValue<DashboardSummary>.error(
            StateError('No current gym is selected.'),
            StackTrace.current,
          )
        : ref.watch(dashboardSummaryProvider);

    return Scaffold(
      backgroundColor: bgDark,
      body: summaryAsync.when(
        loading: () => const _DashboardLoading(),
        error: (error, _) => _DashboardError(error: error),
        data: (summary) => _DashboardBody(
          gymId: gymId ?? '',
          summary: summary,
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.gymId,
    required this.summary,
  });

  final String gymId;
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final isWide = constraints.maxWidth > 1100;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(gymId: gymId),
              const SizedBox(height: 24),
              _KpiGrid(summary: summary, compact: isMobile, wide: isWide),
              const SizedBox(height: 24),
              if (summary.isEmptyGym) ...[
                const _EmptyDashboardState(),
                const SizedBox(height: 16),
              ],
              if (isMobile) ...[
                _OccupancySection(summary: summary),
                const SizedBox(height: 16),
                _RecentPayments(summary: summary),
                const SizedBox(height: 16),
                _RecentCheckins(summary: summary),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _OccupancySection(summary: summary)),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: _RecentPayments(summary: summary)),
                  ],
                ),
                const SizedBox(height: 16),
                _RecentCheckins(summary: summary),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.gymId});

  final String gymId;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoldHeading('$greeting, Admin', fontSize: 20),
              const SizedBox(height: 4),
              ApexText(
                '${DateFormat('EEEE, d MMMM yyyy').format(now)} - $gymId',
                fontSize: 12,
                color: const Color(0xFF555555),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: greenSuccess.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: greenSuccess.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
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
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.summary,
    required this.compact,
    required this.wide,
  });

  final DashboardSummary summary;
  final bool compact;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = compact ? 2 : (wide ? 4 : 3);
    final ratio = compact ? 0.96 : 1.34;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: ratio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _KpiCard(
          icon: Icons.people_rounded,
          label: 'Total Members',
          value: '${summary.totalMembers}',
          detail: '${summary.activeMembers} active',
          accent: blueInfo,
          good: true,
          onTap: () => _showKpiSheet(context, _DashboardKpi.totalMembers, summary),
        ),
        _KpiCard(
          icon: Icons.verified_rounded,
          label: 'Active Subscriptions',
          value: '${summary.activeSubscriptions}',
          detail: '${summary.expiredSubscriptions} expired',
          accent: greenSuccess,
          good: summary.expiredSubscriptions == 0,
          onTap: () =>
              _showKpiSheet(context, _DashboardKpi.activeSubscriptions, summary),
        ),
        _KpiCard(
          icon: Icons.warning_amber_rounded,
          label: 'Expiring Soon',
          value: '${summary.expiringSoonSubscriptions}',
          detail: 'Next 7 days',
          accent: orangeWarning,
          good: summary.expiringSoonSubscriptions == 0,
          onTap: () => _showKpiSheet(context, _DashboardKpi.expiringSoon, summary),
        ),
        _KpiCard(
          icon: Icons.login_rounded,
          label: 'Today Check-ins',
          value: '${summary.todayCheckins}',
          detail: 'Since midnight',
          accent: blueInfo,
          good: true,
          onTap: () => _showKpiSheet(context, _DashboardKpi.todayCheckins, summary),
        ),
        _KpiCard(
          icon: Icons.payments_rounded,
          label: 'Today Revenue',
          value: _money(summary.todayRevenue),
          detail: 'Paid/partial',
          accent: gold,
          good: true,
          onTap: () => _showKpiSheet(context, _DashboardKpi.todayRevenue, summary),
        ),
        _KpiCard(
          icon: Icons.calendar_month_rounded,
          label: 'Month Revenue',
          value: _money(summary.monthRevenue),
          detail: 'Current month',
          accent: greenSuccess,
          good: true,
          onTap: () => _showKpiSheet(context, _DashboardKpi.monthRevenue, summary),
        ),
        _KpiCard(
          icon: Icons.cancel_rounded,
          label: 'Expired Subscriptions',
          value: '${summary.expiredSubscriptions}',
          detail: 'End date passed',
          accent: redAlert,
          good: summary.expiredSubscriptions == 0,
          onTap: () =>
              _showKpiSheet(context, _DashboardKpi.expiredSubscriptions, summary),
        ),
        _KpiCard(
          icon: Icons.sensor_occupied_rounded,
          label: 'Current Occupancy',
          value: '${summary.occupancyCount}',
          detail: summary.occupancyCapacity > 0
              ? '/ ${summary.occupancyCapacity}'
              : 'No capacity',
          accent: orangeWarning,
          good: true,
          onTap: () => _showKpiSheet(context, _DashboardKpi.occupancy, summary),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.accent,
    required this.good,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color accent;
  final bool good;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detailColor = good ? greenSuccess : redAlert;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ApexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accent, size: 18),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: Color(0xFF555555),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GoldHeading(value, fontSize: 21),
              const SizedBox(height: 5),
              ApexText(
                label,
                fontSize: 12,
                color: const Color(0xFFB8B8B8),
                fontWeight: FontWeight.w600,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: detailColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ApexText(
                      detail,
                      fontSize: 10.5,
                      color: detailColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const ApexText(
                    'Tap for details',
                    fontSize: 10,
                    color: Color(0xFF777777),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DashboardKpi {
  totalMembers,
  activeSubscriptions,
  expiringSoon,
  todayCheckins,
  todayRevenue,
  monthRevenue,
  expiredSubscriptions,
  occupancy,
}

void _showKpiSheet(
  BuildContext context,
  _DashboardKpi kpi,
  DashboardSummary summary,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _KpiDetailSheet(kpi: kpi, summary: summary),
  );
}

class _KpiDetailSheet extends StatelessWidget {
  const _KpiDetailSheet({
    required this.kpi,
    required this.summary,
  });

  final _DashboardKpi kpi;
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final title = _title;
    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.35,
      maxChildSize: 0.88,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: borderDark)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF444444),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: GoldHeading(title, fontSize: 18)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFF888888),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._content(context),
          ],
        ),
      ),
    );
  }

  String get _title {
    switch (kpi) {
      case _DashboardKpi.totalMembers:
        return 'Total Members';
      case _DashboardKpi.activeSubscriptions:
        return 'Active Subscriptions';
      case _DashboardKpi.expiringSoon:
        return 'Expiring Soon';
      case _DashboardKpi.todayCheckins:
        return 'Today Check-ins';
      case _DashboardKpi.todayRevenue:
        return 'Today Revenue';
      case _DashboardKpi.monthRevenue:
        return 'Month Revenue';
      case _DashboardKpi.expiredSubscriptions:
        return 'Expired Subscriptions';
      case _DashboardKpi.occupancy:
        return 'Current Occupancy';
    }
  }

  List<Widget> _content(BuildContext context) {
    switch (kpi) {
      case _DashboardKpi.totalMembers:
        final inactive = summary.totalMembers - summary.activeMembers;
        return [
          _SheetMetricGrid(
            rows: [
              _SheetMetric('Total', '${summary.totalMembers}'),
              _SheetMetric('Active', '${summary.activeMembers}'),
              _SheetMetric('Inactive', '${inactive < 0 ? 0 : inactive}'),
            ],
          ),
          const SizedBox(height: 14),
          _SheetButton(
            label: 'View Members',
            icon: Icons.groups_2_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/members');
            },
          ),
        ];
      case _DashboardKpi.activeSubscriptions:
        return [
          _SheetMetricGrid(
            rows: [
              _SheetMetric('Active', '${summary.activeSubscriptions}'),
              _SheetMetric('Partial', '${summary.partialSubscriptions}'),
              _SheetMetric('Expiring Soon', '${summary.expiringSoonSubscriptions}'),
              _SheetMetric('Expired', '${summary.expiredSubscriptions}'),
            ],
          ),
        ];
      case _DashboardKpi.expiringSoon:
        return [
          _SheetMetricGrid(
            rows: [_SheetMetric('Expiring Soon', '${summary.expiringSoonSubscriptions}')],
          ),
          const SizedBox(height: 12),
          _SubscriptionList(
            items: summary.expiringSoonItems,
            emptyText: 'No subscriptions are expiring soon.',
          ),
          const SizedBox(height: 12),
          _SheetButton(
            label: 'Open Payments / Renew',
            icon: Icons.receipt_long_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/payments');
            },
          ),
        ];
      case _DashboardKpi.todayCheckins:
        return [
          _SheetMetricGrid(
            rows: [_SheetMetric('Today', '${summary.todayCheckins}')],
          ),
          const SizedBox(height: 12),
          _CheckinList(
            items: summary.todayCheckinItems,
            emptyText: 'No check-ins today.',
          ),
        ];
      case _DashboardKpi.todayRevenue:
        return [
          _SheetMetricGrid(
            rows: [_SheetMetric('Today Revenue', _money(summary.todayRevenue))],
          ),
          const SizedBox(height: 12),
          _TransactionList(
            items: summary.todayTransactions,
            emptyText: 'No paid or partial transactions today.',
          ),
        ];
      case _DashboardKpi.monthRevenue:
        return [
          _SheetMetricGrid(
            rows: [
              _SheetMetric('Month Revenue', _money(summary.monthRevenue)),
              _SheetMetric('Transactions', '${summary.monthTransactions.length}'),
            ],
          ),
          const SizedBox(height: 10),
          const ApexText(
            'Includes paid and partial transactions from the current month.',
            color: Color(0xFF999999),
            fontSize: 12,
          ),
          const SizedBox(height: 12),
          _TransactionList(
            items: summary.monthTransactions,
            emptyText: 'No paid or partial transactions this month.',
          ),
        ];
      case _DashboardKpi.expiredSubscriptions:
        return [
          _SheetMetricGrid(
            rows: [_SheetMetric('Expired', '${summary.expiredSubscriptions}')],
          ),
          const SizedBox(height: 12),
          _SubscriptionList(
            items: summary.expiredItems,
            emptyText: 'No expired subscriptions.',
          ),
        ];
      case _DashboardKpi.occupancy:
        final capacity = summary.occupancyCapacity;
        final pct = capacity > 0
            ? (summary.occupancyCount / capacity * 100).clamp(0, 100).round()
            : 0;
        final label = capacity <= 0
            ? 'Capacity not set'
            : pct >= 90
                ? 'High'
                : pct >= 70
                    ? 'Busy'
                    : 'Comfortable';
        return [
          _SheetMetricGrid(
            rows: [
              _SheetMetric('Current Count', '${summary.occupancyCount}'),
              _SheetMetric('Capacity', capacity > 0 ? '$capacity' : 'Not set'),
              _SheetMetric('Usage', capacity > 0 ? '$pct%' : '0%'),
              _SheetMetric('Status', label),
            ],
          ),
          const SizedBox(height: 12),
          _CheckinList(
            items: summary.recentCheckins,
            emptyText: 'No recent check-ins.',
          ),
        ];
    }
  }
}

class _SheetMetricGrid extends StatelessWidget {
  const _SheetMetricGrid({required this.rows});

  final List<_SheetMetric> rows;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: rows
          .map(
            (row) => Container(
              width: MediaQuery.of(context).size.width < 430
                  ? (MediaQuery.of(context).size.width - 50) / 2
                  : 170,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ApexText(
                    row.label,
                    fontSize: 11,
                    color: const Color(0xFF888888),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  ApexText(
                    row.value,
                    fontSize: 17,
                    color: const Color(0xFFE8E8E8),
                    fontWeight: FontWeight.w800,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SheetMetric {
  const _SheetMetric(this.label, this.value);

  final String label;
  final String value;
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: FilledButton.styleFrom(backgroundColor: gold),
    );
  }
}

class _SubscriptionList extends StatelessWidget {
  const _SubscriptionList({
    required this.items,
    required this.emptyText,
  });

  final List<GymSubscription> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _SheetEmpty(emptyText);
    return Column(
      children: items
          .map(
            (sub) => _SheetRow(
              icon: Icons.card_membership_rounded,
              title: sub.memberName.isEmpty ? 'Unknown member' : sub.memberName,
              subtitle: '${sub.planName} - ends ${_formatDate(sub.endDate)}',
              trailing: sub.paymentStatus,
            ),
          )
          .toList(),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.items,
    required this.emptyText,
  });

  final List<GymTransaction> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _SheetEmpty(emptyText);
    return Column(
      children: items
          .map(
            (tx) => _SheetRow(
              icon: Icons.receipt_long_rounded,
              title: tx.receiptNumber,
              subtitle:
                  '${tx.memberName.isEmpty ? 'Unknown member' : tx.memberName} - ${tx.amount.toStringAsFixed(0)} ${tx.currency}',
              trailing: '${tx.paymentMethod} / ${tx.paymentStatus}',
            ),
          )
          .toList(),
    );
  }
}

class _CheckinList extends StatelessWidget {
  const _CheckinList({
    required this.items,
    required this.emptyText,
  });

  final List<dynamic> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _SheetEmpty(emptyText);
    return Column(
      children: items
          .map(
            (ci) => _SheetRow(
              icon: Icons.login_rounded,
              title: (ci.name as String).isEmpty ? 'Unknown member' : ci.name,
              subtitle: '${ci.method} - ${_formatDateTime(ci.time)}',
              trailing: ci.plan,
            ),
          )
          .toList(),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderDark),
      ),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApexText(
                  title,
                  color: const Color(0xFFE0E0E0),
                  fontWeight: FontWeight.w700,
                  maxLines: 2,
                ),
                const SizedBox(height: 3),
                ApexText(
                  subtitle,
                  fontSize: 11,
                  color: const Color(0xFF888888),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ApexText(
              trailing,
              fontSize: 10,
              color: const Color(0xFF777777),
              textAlign: TextAlign.right,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetEmpty extends StatelessWidget {
  const _SheetEmpty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderDark),
      ),
      child: ApexText(text, color: const Color(0xFF888888)),
    );
  }
}

class _OccupancySection extends StatelessWidget {
  const _OccupancySection({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final capacity = summary.occupancyCapacity;
    final occupancy = summary.occupancyCount.toDouble();
    final percent = capacity > 0 ? (occupancy / capacity * 100) : 0.0;

    return ApexCard(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Live Occupancy'),
          const SizedBox(height: 20),
          OccupancyRing(current: occupancy, capacity: capacity),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatPill(
                label: 'Count',
                value: '${summary.occupancyCount}',
              ),
              const SizedBox(width: 12),
              _StatPill(
                label: 'Capacity',
                value: capacity > 0 ? '$capacity' : 'Not set',
              ),
              const SizedBox(width: 12),
              _StatPill(
                label: 'Usage',
                value: capacity > 0 ? '${percent.round()}%' : '0%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentPayments extends StatelessWidget {
  const _RecentPayments({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Recent Payments / Receipts'),
          const SizedBox(height: 14),
          if (summary.recentTransactions.isEmpty)
            const ApexText('No payments recorded yet.', color: Color(0xFF555555))
          else
            Column(
              children: summary.recentTransactions
                  .take(10)
                  .map((tx) => _PaymentRow(transaction: tx))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.transaction});

  final GymTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isPaid = transaction.paymentStatus == TransactionPaymentStatus.paid;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderDark),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApexText(
                  transaction.memberName.isEmpty
                      ? transaction.receiptNumber
                      : transaction.memberName,
                  color: const Color(0xFFE2E2E2),
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 3),
                ApexText(
                  '${transaction.receiptNumber} - ${_formatDateTime(transaction.date)}',
                  fontSize: 10,
                  color: const Color(0xFF666666),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ApexText(
                '${transaction.amount.toStringAsFixed(0)} ${transaction.currency}',
                color: greenSuccess,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 4),
              ApexBadge(
                text: '${transaction.paymentMethod} / ${transaction.paymentStatus}',
                color: isPaid ? greenSuccess : orangeWarning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentCheckins extends StatelessWidget {
  const _RecentCheckins({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              GoldHeading('Recent Check-ins'),
              Spacer(),
              Icon(Icons.circle, color: greenSuccess, size: 7),
            ],
          ),
          const SizedBox(height: 12),
          if (summary.recentCheckins.isEmpty)
            const ApexText('No check-ins yet.', color: Color(0xFF555555))
          else
            Column(
              children: summary.recentCheckins
                  .take(10)
                  .map(
                    (ci) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderDark),
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
                                  ci.name.isEmpty ? 'Unknown member' : ci.name,
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
                                    Expanded(
                                      child: ApexText(
                                        ci.plan,
                                        fontSize: 9,
                                        color: const Color(0xFF444444),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ApexText(
                            timeAgo(ci.time),
                            fontSize: 10,
                            color: const Color(0xFF444444),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
            ApexText(
              label,
              fontSize: 9,
              color: const Color(0xFF444444),
              letterSpacing: 1,
            ),
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

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);
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
          color: greenSuccess.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState();

  @override
  Widget build(BuildContext context) {
    return const ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldHeading('No Gym Data Yet'),
          SizedBox(height: 10),
          ApexText(
            'This gym has no members, subscriptions, receipts, or check-ins yet.',
            fontSize: 12,
            color: Color(0xFF888888),
          ),
          SizedBox(height: 8),
          ApexText(
            'Dashboard metrics update from gym-scoped Firestore data as operations happen.',
            fontSize: 11,
            color: Color(0xFF555555),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          ShimmerCard(),
          SizedBox(height: 12),
          ShimmerCard(),
          SizedBox(height: 12),
          ShimmerCard(),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ApexCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GoldHeading('Dashboard unavailable'),
              const SizedBox(height: 10),
              ApexText(
                _friendlyDashboardError(error),
                color: orangeWarning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _friendlyDashboardError(Object error) {
  final message = error.toString();
  if (message.contains('No current gym')) {
    return 'No current gym is selected. users/{uid}.defaultGymId is required.';
  }
  if (message.toLowerCase().contains('index')) {
    return 'This dashboard query needs a Firestore index. Check the console link in debug logs.';
  }
  if (message.toLowerCase().contains('permission')) {
    return 'You do not have permission to load this gym dashboard.';
  }
  return 'Could not load dashboard data: $message';
}

String _formatDateTime(DateTime date) {
  final ymd =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final hm = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  return '$ymd $hm';
}

String _formatDate(DateTime? date) {
  if (date == null) return 'not set';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _money(double amount) {
  return '${amount.toStringAsFixed(0)} EGP';
}

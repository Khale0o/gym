import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymsaas/core/helpers.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/models/attendance_session.dart';
import 'package:gymsaas/models/dashboard_summary.dart';
import 'package:gymsaas/models/member.dart';
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
          activeSessionsAsync: ref.watch(activeAttendanceSessionsProvider),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.gymId,
    required this.summary,
    required this.activeSessionsAsync,
  });

  final String gymId;
  final DashboardSummary summary;
  final AsyncValue<List<AttendanceSession>> activeSessionsAsync;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final isWide = constraints.maxWidth > 1180;
        final horizontalPadding = isMobile ? 16.0 : 32.0;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isMobile ? 20 : 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(gymId: gymId),
                  const SizedBox(height: 30),
                  const _SectionHeader(
                    title: 'Key Metrics',
                    subtitle: 'Tap any card for records and operational detail.',
                  ),
                  const SizedBox(height: 14),
                  _KpiGrid(
                    summary: summary,
                    compact: isMobile,
                    wide: isWide,
                    activeSessionsAsync: activeSessionsAsync,
                  ),
                  const SizedBox(height: 30),
                  if (summary.isEmptyGym) ...[
                    const _EmptyDashboardState(),
                    const SizedBox(height: 24),
                  ],
                  const _SectionHeader(
                    title: 'Operations',
                    subtitle: 'Live occupancy, recent receipts, and attendance activity.',
                  ),
                  const SizedBox(height: 14),
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
                        Expanded(
                          flex: isWide ? 4 : 5,
                          child: _OccupancySection(summary: summary),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: isWide ? 7 : 6,
                          child: _RecentPayments(summary: summary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _RecentCheckins(summary: summary),
                  ],
                ],
              ),
            ),
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

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: ApexDecorations.card(
        color: ApexColors.surface,
        borderColor: ApexColors.border,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoldHeading('$greeting, Admin', fontSize: 22),
                const SizedBox(height: 8),
                ApexText(
                  '${DateFormat('EEEE, d MMMM yyyy').format(now)} - $gymId',
                  fontSize: 13,
                  color: ApexColors.textMuted,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: ApexDecorations.badge(greenSuccess),
            child: const Row(
              children: [
                _PulseDot(),
                SizedBox(width: 7),
                ApexText(
                  'Live',
                  fontSize: 12,
                  color: greenSuccess,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ApexText(
          title,
          fontSize: 16,
          color: ApexColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        const SizedBox(height: 5),
        ApexText(
          subtitle,
          fontSize: 13,
          color: ApexColors.textMuted,
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
    required this.activeSessionsAsync,
  });

  final DashboardSummary summary;
  final bool compact;
  final bool wide;
  final AsyncValue<List<AttendanceSession>> activeSessionsAsync;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = compact ? 1 : (wide ? 3 : 2);
    final ratio = compact ? 2.45 : (wide ? 1.95 : 1.78);
    final inactiveMembers = summary.totalMembers - summary.activeMembers;
    final cards = [
      _KpiCard(
        icon: Icons.people_rounded,
        label: 'Total Members',
        value: '${summary.totalMembers}',
        detail: '${summary.activeMembers} active',
        accent: blueInfo,
        good: true,
        compact: compact,
        onTap: () => _showKpiDetails(
          context,
          _DashboardKpi.totalMembers,
          summary,
          activeSessionsAsync,
        ),
      ),
      _KpiCard(
        icon: Icons.how_to_reg_rounded,
        label: 'Active Members',
        value: '${summary.activeMembers}',
        detail: '${inactiveMembers < 0 ? 0 : inactiveMembers} inactive',
        accent: greenSuccess,
        good: true,
        compact: compact,
        onTap: () => _showKpiDetails(
          context,
          _DashboardKpi.activeMembers,
          summary,
          activeSessionsAsync,
        ),
      ),
      _KpiCard(
        icon: Icons.verified_rounded,
        label: 'Active Subscriptions',
        value: '${summary.activeSubscriptions}',
        detail: '${summary.expiredSubscriptions} expired',
        accent: greenSuccess,
        good: summary.expiredSubscriptions == 0,
        compact: compact,
        onTap: () => _showKpiDetails(
          context,
          _DashboardKpi.activeSubscriptions,
          summary,
          activeSessionsAsync,
        ),
      ),
      _KpiCard(
        icon: Icons.warning_amber_rounded,
        label: 'Expiring Soon',
        value: '${summary.expiringSoonSubscriptions}',
        detail: 'Next 7 days',
        accent: orangeWarning,
        good: summary.expiringSoonSubscriptions == 0,
        compact: compact,
        onTap: () => _showKpiDetails(
          context,
          _DashboardKpi.expiringSoon,
          summary,
          activeSessionsAsync,
        ),
      ),
      _KpiCard(
        icon: Icons.login_rounded,
        label: 'Today Check-ins',
        value: '${summary.todayCheckins}',
        detail: 'Since midnight',
        accent: blueInfo,
        good: true,
        compact: compact,
        onTap: () => _showKpiDetails(
          context,
          _DashboardKpi.todayCheckins,
          summary,
          activeSessionsAsync,
        ),
      ),
      _KpiCard(
        icon: Icons.payments_rounded,
        label: 'Today Revenue',
        value: _money(summary.todayRevenue),
        detail: 'Paid/partial',
        accent: gold,
        good: true,
        compact: compact,
        onTap: () => _showKpiDetails(
          context,
          _DashboardKpi.todayRevenue,
          summary,
          activeSessionsAsync,
        ),
      ),
      _KpiCard(
        icon: Icons.calendar_month_rounded,
        label: 'Month Revenue',
        value: _money(summary.monthRevenue),
        detail: 'Current month',
        accent: greenSuccess,
        good: true,
        compact: compact,
        onTap: () => _showKpiDetails(
          context,
          _DashboardKpi.monthRevenue,
          summary,
          activeSessionsAsync,
        ),
      ),
      _KpiCard(
        icon: Icons.cancel_rounded,
        label: 'Expired Subscriptions',
        value: '${summary.expiredSubscriptions}',
        detail: 'End date passed',
        accent: redAlert,
        good: summary.expiredSubscriptions == 0,
        compact: compact,
        onTap: () => _showKpiDetails(
          context,
          _DashboardKpi.expiredSubscriptions,
          summary,
          activeSessionsAsync,
        ),
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
        compact: compact,
        onTap: () => _showKpiDetails(
          context,
          _DashboardKpi.occupancy,
          summary,
          activeSessionsAsync,
        ),
      ),
    ];

    if (compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 320 ? 2 : 1;
          return GridView.count(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 2 ? 0.98 : 2.45,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cards,
          );
        },
      );
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: ratio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
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
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color accent;
  final bool good;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detailColor = good ? greenSuccess : redAlert;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: ApexRadius.card,
        child: ApexCard(
          padding: EdgeInsets.all(compact ? 12 : 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 28 : 34,
                    height: compact ? 28 : 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(ApexRadius.md),
                    ),
                    child: Icon(icon, color: accent, size: compact ? 16 : 18),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: ApexColors.textMuted,
                  ),
                ],
              ),
              SizedBox(height: compact ? 11 : 18),
              GoldHeading(value, fontSize: compact ? 18 : 21),
              SizedBox(height: compact ? 3 : 5),
              ApexText(
                label,
                fontSize: compact ? 11.5 : 13,
                color: ApexColors.textPrimary,
                fontWeight: FontWeight.w700,
                maxLines: 2,
              ),
              SizedBox(height: compact ? 8 : 10),
              Wrap(
                spacing: compact ? 6 : 10,
                runSpacing: compact ? 5 : 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 7 : 8,
                      vertical: compact ? 3 : 4,
                    ),
                    decoration: ApexDecorations.badge(detailColor),
                    child: ApexText(
                      detail,
                      fontSize: compact ? 9.5 : 11,
                      color: detailColor,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!compact)
                    const ApexText(
                      'Details',
                      fontSize: 11,
                      color: ApexColors.textMuted,
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
  activeMembers,
  activeSubscriptions,
  expiringSoon,
  todayCheckins,
  todayRevenue,
  monthRevenue,
  expiredSubscriptions,
  occupancy,
}

void _showKpiDetails(
  BuildContext context,
  _DashboardKpi kpi,
  DashboardSummary summary,
  AsyncValue<List<AttendanceSession>> activeSessionsAsync,
) {
  final content = _KpiDetailPanel(
    kpi: kpi,
    summary: summary,
    activeSessionsAsync: activeSessionsAsync,
  );

  if (MediaQuery.of(context).size.width >= 900) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
          child: content,
        ),
      ),
    );
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, controller) => _KpiDetailSheetFrame(
        controller: controller,
        child: content,
      ),
    ),
  );
}

class _KpiDetailSheetFrame extends StatelessWidget {
  const _KpiDetailSheetFrame({
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ApexColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: ApexColors.border)),
      ),
      child: PrimaryScrollController(
        controller: controller,
        child: child,
      ),
    );
  }
}

class _KpiDetailPanel extends StatelessWidget {
  const _KpiDetailPanel({
    required this.kpi,
    required this.summary,
    required this.activeSessionsAsync,
  });

  final _DashboardKpi kpi;
  final DashboardSummary summary;
  final AsyncValue<List<AttendanceSession>> activeSessionsAsync;

  @override
  Widget build(BuildContext context) {
    final title = _title;
    return Container(
      decoration: BoxDecoration(
        color: ApexColors.surface,
        borderRadius: BorderRadius.circular(ApexRadius.xl),
        border: Border.all(color: ApexColors.border),
      ),
      child: ListView(
        controller: PrimaryScrollController.maybeOf(context),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: ApexColors.border,
                borderRadius: BorderRadius.circular(ApexRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: GoldHeading(title, fontSize: 19)),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: ApexColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ApexText(_subtitle, fontSize: 13, color: ApexColors.textMuted),
          const SizedBox(height: 18),
          ..._content(context),
        ],
      ),
    );
  }

  String get _title {
    switch (kpi) {
      case _DashboardKpi.totalMembers:
        return 'Total Members';
      case _DashboardKpi.activeMembers:
        return 'Active Members';
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

  String get _subtitle {
    switch (kpi) {
      case _DashboardKpi.totalMembers:
        return 'Complete member directory snapshot from the current gym.';
      case _DashboardKpi.activeMembers:
        return 'Members marked active with an active account state.';
      case _DashboardKpi.activeSubscriptions:
        return 'Current active, partial, and expiring-soon subscriptions.';
      case _DashboardKpi.expiringSoon:
        return 'Subscriptions that need renewal attention soon.';
      case _DashboardKpi.todayCheckins:
        return 'Attendance records created today.';
      case _DashboardKpi.todayRevenue:
        return 'Paid and partial transactions recorded today.';
      case _DashboardKpi.monthRevenue:
        return 'Paid and partial transactions in the current month.';
      case _DashboardKpi.expiredSubscriptions:
        return 'Members affected by expired subscription records.';
      case _DashboardKpi.occupancy:
        return 'Current occupancy with live attendance sessions when available.';
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
          _MemberList(
            items: summary.memberItems,
            emptyText: 'No members have been created yet.',
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
      case _DashboardKpi.activeMembers:
        return [
          _SheetMetricGrid(
            rows: [
              _SheetMetric('Active', '${summary.activeMembers}'),
              _SheetMetric('Total Members', '${summary.totalMembers}'),
            ],
          ),
          const SizedBox(height: 14),
          _MemberList(
            items: summary.activeMemberItems,
            emptyText: 'No active members found.',
          ),
          const SizedBox(height: 14),
          _SheetButton(
            label: 'Open Members',
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
          const SizedBox(height: 14),
          _SubscriptionList(
            items: summary.activeSubscriptionItems,
            emptyText: 'No active subscriptions found.',
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
        final sessions = activeSessionsAsync.valueOrNull ?? const <AttendanceSession>[];
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
              _SheetMetric('Active Sessions', '${sessions.length}'),
              _SheetMetric('Status', label),
            ],
          ),
          const SizedBox(height: 12),
          activeSessionsAsync.when(
            data: (items) => _AttendanceSessionList(
              items: items,
              emptyText: 'No active attendance sessions right now.',
            ),
            loading: () => const ShimmerCard(),
            error: (_, __) => _CheckinList(
              items: summary.recentCheckins,
              emptyText: 'No recent check-ins.',
            ),
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
              decoration: ApexDecorations.card(
                color: ApexColors.card,
                borderColor: ApexColors.border,
                radius: ApexRadius.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ApexText(
                    row.label,
                    fontSize: 11,
                    color: ApexColors.textMuted,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  ApexText(
                    row.value,
                    fontSize: 17,
                    color: ApexColors.textPrimary,
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

class _MemberList extends StatelessWidget {
  const _MemberList({
    required this.items,
    required this.emptyText,
  });

  final List<Member> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _SheetEmpty(emptyText);
    return Column(
      children: items
          .map(
            (member) => _SheetRow(
              icon: Icons.person_rounded,
              title: member.name.isEmpty ? 'Unnamed member' : member.name,
              subtitle:
                  '${member.plan} - ${member.phone?.isNotEmpty == true ? member.phone : 'No phone'}',
              trailing: member.status,
            ),
          )
          .toList(),
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

class _AttendanceSessionList extends StatelessWidget {
  const _AttendanceSessionList({
    required this.items,
    required this.emptyText,
  });

  final List<AttendanceSession> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _SheetEmpty(emptyText);
    return Column(
      children: items
          .map(
            (session) => _SheetRow(
              icon: Icons.sensor_occupied_rounded,
              title: session.memberName.isEmpty
                  ? 'Unknown member'
                  : session.memberName,
              subtitle:
                  '${session.planName ?? 'No plan'} - checked in ${timeAgo(session.checkInAt)}',
              trailing: session.checkInMethod,
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
      decoration: ApexDecorations.card(
        color: ApexColors.card,
        borderColor: ApexColors.border,
        radius: ApexRadius.md,
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
                  color: ApexColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  maxLines: 2,
                ),
                const SizedBox(height: 3),
                ApexText(
                  subtitle,
                  fontSize: 11,
                  color: ApexColors.textMuted,
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
              color: ApexColors.textMuted,
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
      decoration: ApexDecorations.card(
        color: ApexColors.card,
        borderColor: ApexColors.border,
        radius: ApexRadius.md,
      ),
      child: ApexText(text, color: ApexColors.textSecondary),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.sensor_occupied_rounded,
            title: 'Live Occupancy',
            subtitle: 'Current floor usage',
          ),
          const SizedBox(height: 22),
          OccupancyRing(current: occupancy, capacity: capacity),
          const SizedBox(height: 22),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.receipt_long_rounded,
            title: 'Recent Payments',
            subtitle: 'Latest receipts and payment status',
          ),
          const SizedBox(height: 16),
          if (summary.recentTransactions.isEmpty)
            const _InlineEmpty('No payments recorded yet.')
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

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: ApexDecorations.badge(gold),
          child: Icon(icon, color: gold, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApexText(
                title,
                color: ApexColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
              const SizedBox(height: 3),
              ApexText(
                subtitle,
                color: ApexColors.textMuted,
                fontSize: 12,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ApexSpacing.emptyState,
      decoration: ApexDecorations.card(
        color: ApexColors.surface,
        borderColor: ApexColors.border,
        radius: ApexRadius.md,
      ),
      child: Center(
        child: ApexText(
          text,
          color: ApexColors.textMuted,
          fontSize: 13,
        ),
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
      decoration: ApexDecorations.card(
        color: ApexColors.surface,
        borderColor: ApexColors.border,
        radius: ApexRadius.md,
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
                  color: ApexColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 3),
                ApexText(
                  '${transaction.receiptNumber} - ${_formatDateTime(transaction.date)}',
                  fontSize: 11,
                  color: ApexColors.textMuted,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.login_rounded,
            title: 'Recent Check-ins',
            subtitle: 'Latest attendance activity',
            trailing: Icon(Icons.circle, color: greenSuccess, size: 7),
          ),
          const SizedBox(height: 16),
          if (summary.recentCheckins.isEmpty)
            const _InlineEmpty('No check-ins yet.')
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
                        color: ApexColors.surface,
                        borderRadius: BorderRadius.circular(ApexRadius.md),
                        border: Border.all(color: ApexColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF151515),
                              borderRadius: BorderRadius.circular(ApexRadius.sm),
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
                                  fontSize: 13,
                                  color: ApexColors.textPrimary,
                                  fontWeight: FontWeight.w600,
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
                                        fontSize: 11,
                                        color: ApexColors.textMuted,
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
                            fontSize: 11,
                            color: ApexColors.textMuted,
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
      decoration: ApexDecorations.card(
        color: ApexColors.surface,
        borderColor: ApexColors.border,
        radius: ApexRadius.md,
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ApexText(
              label,
              fontSize: 11,
              color: ApexColors.textMuted,
            ),
            const SizedBox(height: 4),
            ApexText(
              value,
              fontSize: 13,
              color: ApexColors.textPrimary,
              fontWeight: FontWeight.w700,
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
      padding: ApexSpacing.emptyState,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldHeading('No Gym Data Yet'),
          SizedBox(height: 10),
          ApexText(
            'This gym has no members, subscriptions, receipts, or check-ins yet.',
            fontSize: 12,
            color: ApexColors.textSecondary,
          ),
          SizedBox(height: 8),
          ApexText(
            'Dashboard metrics update from gym-scoped Firestore data as operations happen.',
            fontSize: 11,
            color: ApexColors.textMuted,
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              ShimmerCard(),
              SizedBox(height: 16),
              ShimmerCard(),
              SizedBox(height: 16),
              ShimmerCard(),
            ],
          ),
        ),
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

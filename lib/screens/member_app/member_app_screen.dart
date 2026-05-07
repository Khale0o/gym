import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/l10n/app_localizations.dart';
import 'package:gymsaas/models/attendance_session.dart';
import 'package:gymsaas/models/effective_subscription_status.dart';
import 'package:gymsaas/models/gym_settings.dart';
import 'package:gymsaas/models/member_access_eligibility.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/models/transaction_model.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';
import 'package:gymsaas/widgets/apex_badge.dart';
import 'package:gymsaas/widgets/apex_card.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:qr_flutter/qr_flutter.dart';

final _memberGymDisplayProvider =
    StreamProvider.family<_MemberGymDisplay, String>((ref, gymId) {
  return ref
      .watch(firestoreProvider)
      .collection('gyms')
      .doc(gymId)
      .snapshots()
      .map((doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return _MemberGymDisplay(
      name: ((data['name'] as String?) ??
              (data['gymName'] as String?) ??
              (data['displayName'] as String?) ??
              'Your Gym')
          .trim(),
    );
  });
});

class _MemberGymDisplay {
  const _MemberGymDisplay({required this.name});

  final String name;
}

class MemberAppScreen extends ConsumerStatefulWidget {
  const MemberAppScreen({super.key});

  @override
  ConsumerState<MemberAppScreen> createState() => _MemberAppScreenState();
}

class _MemberAppScreenState extends ConsumerState<MemberAppScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: bgDark,
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: gold)),
        error: (error, _) => _FullScreenMessage(
          _friendlyFirestoreError(error),
          color: redAlert,
        ),
        data: (profile) {
          final gymId = profile?.defaultGymId?.trim() ?? '';
          final linkedMemberId = profile?.linkedMemberId?.trim() ?? '';

          if (profile == null || gymId.isEmpty) {
            return _FullScreenMessage(
              context.t(L10nKeys.memberProfileIncomplete),
            );
          }
          if (linkedMemberId.isEmpty) {
            return _FullScreenMessage(
              context.t(L10nKeys.memberProfileNotLinked),
            );
          }

          final memberAsync = ref.watch(gymMemberByIdProvider(linkedMemberId));
          final attendanceAsync =
              ref.watch(memberAttendanceSessionsProvider(linkedMemberId));
          final transactionsAsync =
              ref.watch(memberTransactionsProvider(linkedMemberId));
          final gymDisplayAsync = ref.watch(_memberGymDisplayProvider(gymId));
          final occupancyAsync = ref.watch(occupancySettingsProvider);

          return memberAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: gold)),
            error: (error, _) => _FullScreenMessage(
              _friendlyFirestoreError(error),
              color: redAlert,
            ),
            data: (member) {
              if (member == null) {
                return _FullScreenMessage(
                  context.t(L10nKeys.memberProfileNotFound),
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF080808),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: const Color(0xFF2A2A2A),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Column(
                          children: [
                            const _PhoneNotch(),
                            Expanded(
                              child: IndexedStack(
                                index: _tab,
                                children: [
                                  _MemberHomeTab(
                                    member: member,
                                    attendanceAsync: attendanceAsync,
                                    occupancyAsync: occupancyAsync,
                                  ),
                                  _AttendanceTab(async: attendanceAsync),
                                  _PaymentsTab(async: transactionsAsync),
                                  _AccessTab(
                                    member: member,
                                    gymDisplayAsync: gymDisplayAsync,
                                  ),
                                ],
                              ),
                            ),
                            _BottomNav(
                              current: _tab,
                              onChanged: (index) {
                                setState(() => _tab = index);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PhoneNotch extends StatelessWidget {
  const _PhoneNotch();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      color: const Color(0xFF050505),
      child: Center(
        child: Container(
          width: 96,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.current,
    required this.onChanged,
  });

  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E0E0E),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AppNavItem(
            icon: Icons.home_rounded,
            label: context.t(L10nKeys.home),
            index: 0,
            current: current,
            onTap: onChanged,
          ),
          _AppNavItem(
            icon: Icons.login_rounded,
            label: context.t(L10nKeys.attendance),
            index: 1,
            current: current,
            onTap: onChanged,
          ),
          _AppNavItem(
            icon: Icons.receipt_long_rounded,
            label: context.t(L10nKeys.payments),
            index: 2,
            current: current,
            onTap: onChanged,
          ),
          _AppNavItem(
            icon: Icons.qr_code_rounded,
            label: context.t(L10nKeys.access),
            index: 3,
            current: current,
            onTap: onChanged,
          ),
        ],
      ),
    );
  }
}

class _AppNavItem extends StatelessWidget {
  const _AppNavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? gold : const Color(0xFF444444), size: 20),
          const SizedBox(height: 3),
          ApexText(
            label,
            fontSize: 9,
            color: active ? gold : const Color(0xFF444444),
          ),
        ],
      ),
    );
  }
}

class _MemberHomeTab extends StatelessWidget {
  const _MemberHomeTab({
    required this.member,
    required this.attendanceAsync,
    required this.occupancyAsync,
  });

  final Member member;
  final AsyncValue<List<AttendanceSession>> attendanceAsync;
  final AsyncValue<OccupancySettings> occupancyAsync;

  @override
  Widget build(BuildContext context) {
    final subscription = EffectiveSubscriptionState.fromMember(member);

    return _PhoneScroll(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ApexText(context.t(L10nKeys.memberAppTitle), fontSize: 11),
                  GoldHeading(member.fullName, fontSize: 16),
                  const SizedBox(height: 6),
                  ApexText(
                    _emptyDash(member.phone),
                    fontSize: 11,
                    color: const Color(0xFF777777),
                  ),
                  if ((member.email ?? '').trim().isNotEmpty)
                    ApexText(
                      member.email!.trim(),
                      fontSize: 11,
                      color: const Color(0xFF777777),
                    ),
                ],
              ),
            ),
            _InitialsBadge(member.av.isEmpty ? _initials(member.fullName) : member.av),
          ],
        ),
        const SizedBox(height: 14),
        _InfoCard(
          title: 'Profile',
          children: [
            _InfoLine('Member Status', member.status),
            _InfoLine('Account Status', member.accountStatus ?? 'active'),
            _InfoLine('Access Status', member.accessStatus ?? 'active'),
          ],
        ),
        const SizedBox(height: 12),
        _SubscriptionCard(member: member, subscription: subscription),
        const SizedBox(height: 12),
        _AttendanceStatusSummary(async: attendanceAsync),
        const SizedBox(height: 12),
        _LiveOccupancyCard(async: occupancyAsync),
      ],
    );
  }
}

class _LiveOccupancyCard extends StatelessWidget {
  const _LiveOccupancyCard({required this.async});

  final AsyncValue<OccupancySettings> async;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Live Occupancy',
      children: [
        async.when(
          loading: () => const ApexText('Loading occupancy...', fontSize: 12),
          error: (error, _) => ApexText(
            _friendlyFirestoreError(error),
            fontSize: 12,
            color: orangeWarning,
          ),
          data: (settings) {
            final count = settings.count < 0 ? 0 : settings.count;
            final capacity = settings.capacity > 0
                ? settings.capacity
                : settings.maxCapacity;
            final hasCapacity = capacity > 0;
            final percent = hasCapacity
                ? (count / capacity * 100).clamp(0, 100).round()
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(
                  'Current',
                  hasCapacity ? '$count / $capacity' : '$count inside',
                ),
                _InfoLine('Status', _occupancyStatus(percent)),
                if (percent != null) _InfoLine('Usage', '$percent%'),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.member,
    required this.subscription,
  });

  final Member member;
  final EffectiveSubscriptionState subscription;

  @override
  Widget build(BuildContext context) {
    final hasSummary = (member.currentPlanName ?? '').trim().isNotEmpty ||
        (member.subscriptionStatus ?? '').trim().isNotEmpty ||
        member.subscriptionEndDate != null ||
        (member.paymentStatus ?? '').trim().isNotEmpty;

    return _InfoCard(
      title: 'Current Subscription',
      trailing: ApexBadge(text: subscription.label, color: subscription.color),
      children: hasSummary
          ? [
              _InfoLine('Plan', member.currentPlanName ?? member.plan),
              _InfoLine('Subscription', member.subscriptionStatus ?? 'active'),
              _InfoLine('Ends', _formatDate(member.subscriptionEndDate)),
              _InfoLine('Payment', member.paymentStatus ?? 'paid'),
            ]
          : const [
              ApexText(
                'No active subscription found.',
                fontSize: 12,
                color: Color(0xFF777777),
              ),
            ],
    );
  }
}

class _AttendanceStatusSummary extends StatelessWidget {
  const _AttendanceStatusSummary({required this.async});

  final AsyncValue<List<AttendanceSession>> async;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Attendance',
      children: [
        async.when(
          loading: () => const ApexText('Loading attendance...', fontSize: 12),
          error: (error, _) => ApexText(
            _friendlyFirestoreError(error),
            fontSize: 12,
            color: orangeWarning,
          ),
          data: (sessions) {
            final active = _activeSession(sessions);
            if (active != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ApexText(
                    'Currently inside',
                    color: greenSuccess,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 8),
                  _InfoLine('Checked in', _formatDateTime(active.checkInAt)),
                  _InfoLine('Duration', _durationLabel(active)),
                ],
              );
            }

            final last = _lastCompletedSession(sessions);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ApexText(
                  'Not currently inside',
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 8),
                _InfoLine(
                  'Latest checkout',
                  last?.checkOutAt == null
                      ? 'No completed visits'
                      : _formatDateTime(last!.checkOutAt),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({required this.async});

  final AsyncValue<List<AttendanceSession>> async;

  @override
  Widget build(BuildContext context) {
    return _PhoneScroll(
      children: [
        GoldHeading(context.t(L10nKeys.checkInTitle), fontSize: 16),
        const SizedBox(height: 12),
        async.when(
          loading: () => const _InlineLoading(),
          error: (error, _) => _InlineError(_friendlyFirestoreError(error)),
          data: (sessions) {
            final rows = sessions.take(10).toList();
            if (rows.isEmpty) {
              return const _EmptyState('No visits yet.');
            }
            return Column(
              children:
                  rows.map((session) => _AttendanceRow(session: session)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context) {
    return _MiniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ApexBadge(
                text: session.status,
                color: _sessionStatusColor(session.status),
              ),
              const Spacer(),
              ApexText(
                _durationLabel(session),
                fontSize: 11,
                color: gold,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoLine('Date', _formatDate(session.checkInAt)),
          _InfoLine('Check-in', _timeOnly(session.checkInAt)),
          _InfoLine(
            'Check-out',
            session.checkOutAt == null ? 'Still inside' : _timeOnly(session.checkOutAt),
          ),
        ],
      ),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({required this.async});

  final AsyncValue<List<GymTransaction>> async;

  @override
  Widget build(BuildContext context) {
    return _PhoneScroll(
      children: [
        GoldHeading(context.t(L10nKeys.payments), fontSize: 16),
        const SizedBox(height: 12),
        async.when(
          loading: () => const _InlineLoading(),
          error: (error, _) => _InlineError(_friendlyFirestoreError(error)),
          data: (transactions) {
            final rows = transactions.take(10).toList();
            if (rows.isEmpty) {
              return _EmptyState(context.t(L10nKeys.noPaymentsYet));
            }
            return Column(
              children: rows.map((tx) => _PaymentRow(tx: tx)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.tx});

  final GymTransaction tx;

  @override
  Widget build(BuildContext context) {
    return _MiniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ApexText(
                  tx.receiptNumber,
                  color: const Color(0xFFE0E0E0),
                  fontWeight: FontWeight.w700,
                ),
              ),
              ApexBadge(text: tx.paymentStatus, color: _paymentColor(tx.paymentStatus)),
            ],
          ),
          const SizedBox(height: 8),
          _InfoLine('Amount', '${tx.amount.toStringAsFixed(0)} ${tx.currency}'),
          _InfoLine('Method', tx.paymentMethod),
          _InfoLine('Date', _formatDateTime(tx.createdAt)),
          if ((tx.notes ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ApexText(
                tx.notes!.trim(),
                fontSize: 11,
                color: const Color(0xFF999999),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccessTab extends StatelessWidget {
  const _AccessTab({
    required this.member,
    required this.gymDisplayAsync,
  });

  final Member member;
  final AsyncValue<_MemberGymDisplay> gymDisplayAsync;

  @override
  Widget build(BuildContext context) {
    final qrPayload = _qrPayloadFor(member);
    final eligibility = evaluateMemberAccessEligibility(member);
    final gymName = gymDisplayAsync.valueOrNull?.name.trim().isNotEmpty == true
        ? gymDisplayAsync.valueOrNull!.name
        : 'Your Gym';
    final subscription = eligibility.subscriptionState;

    return _PhoneScroll(
      children: [
        GoldHeading(context.t(L10nKeys.memberAppTitle), fontSize: 16),
        const SizedBox(height: 12),
        _DigitalCard(
          gymName: gymName,
          member: member,
          eligibility: eligibility,
          qrPayload: qrPayload,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Card Details',
          trailing: ApexBadge(
            text: eligibility.allowed
                ? context.t(L10nKeys.accessAllowed)
                : context.t(L10nKeys.accessBlocked),
            color: eligibility.allowed ? greenSuccess : redAlert,
          ),
          children: [
            _InfoLine('Plan', member.currentPlanName ?? member.plan),
            _InfoLine('Subscription', subscription.label),
            _InfoLine('Ends', _formatDate(member.subscriptionEndDate)),
            _InfoLine('Payment', member.paymentStatus ?? 'unknown'),
            _InfoLine('Access Status', member.accessStatus ?? 'active'),
            if (eligibility.reasons.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...eligibility.reasons.map(
                (reason) => ApexText(
                  _cardReasonLabel(reason),
                  fontSize: 11,
                  color: eligibility.allowed ? orangeWarning : redAlert,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DigitalCard extends StatelessWidget {
  const _DigitalCard({
    required this.gymName,
    required this.member,
    required this.eligibility,
    required this.qrPayload,
  });

  final String gymName;
  final Member member;
  final MemberAccessEligibility eligibility;
  final String? qrPayload;

  @override
  Widget build(BuildContext context) {
    final statusColor = eligibility.allowed ? greenSuccess : redAlert;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ApexText(
            gymName,
            color: gold,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          GoldHeading(member.fullName, fontSize: 18),
          const SizedBox(height: 4),
          ApexText(
            [
              if ((member.phone ?? '').trim().isNotEmpty) member.phone!.trim(),
              if ((member.email ?? '').trim().isNotEmpty) member.email!.trim(),
            ].join(' • '),
            fontSize: 11,
            color: const Color(0xFF888888),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ApexBadge(
            text: eligibility.allowed
                ? context.t(L10nKeys.accessAllowed)
                : context.t(L10nKeys.accessBlocked),
            color: statusColor,
          ),
          if (eligibility.severity == MemberAccessSeverity.warning) ...[
            const SizedBox(height: 8),
            ApexText(
              _cardReasonLabel(eligibility.message),
              color: orangeWarning,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          if (qrPayload == null)
            const _NoQrMessage()
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: QrImageView(
                data: qrPayload!,
                version: QrVersions.auto,
                size: 190,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ApexText(
              _maskedAccessValue(qrPayload!),
              fontSize: 12,
              color: const Color(0xFFCCCCCC),
              fontWeight: FontWeight.w700,
            ),
          ],
        ],
      ),
    );
  }
}

class _NoQrMessage extends StatelessWidget {
  const _NoQrMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderDark),
      ),
      child: ApexText(
        context.t(L10nKeys.noAccessCredential),
        fontSize: 12,
        color: orangeWarning,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PhoneScroll extends StatelessWidget {
  const _PhoneScroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: GoldHeading(title, fontSize: 13)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderDark),
      ),
      child: child,
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ApexText(
              label,
              fontSize: 11,
              color: const Color(0xFF777777),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: ApexText(
              _emptyDash(value),
              fontSize: 11,
              color: const Color(0xFFD0D0D0),
              textAlign: TextAlign.right,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsBadge extends StatelessWidget {
  const _InitialsBadge(this.initials);

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: goldDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: ApexText(
          initials,
          color: const Color(0xFFE8E8E8),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(color: gold),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return _EmptyState(message, color: orangeWarning);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message, {this.color = const Color(0xFF777777)});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ApexText(message, color: color, textAlign: TextAlign.center);
  }
}

class _FullScreenMessage extends StatelessWidget {
  const _FullScreenMessage(
    this.message, {
    this.color = const Color(0xFF888888),
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ApexText(message, color: color, textAlign: TextAlign.center),
      ),
    );
  }
}

AttendanceSession? _activeSession(List<AttendanceSession> sessions) {
  for (final session in sessions) {
    if (session.status.trim().toLowerCase() == AttendanceSessionStatus.active) {
      return session;
    }
  }
  return null;
}

AttendanceSession? _lastCompletedSession(List<AttendanceSession> sessions) {
  final completed = sessions
      .where((session) =>
          session.status.trim().toLowerCase() ==
              AttendanceSessionStatus.completed &&
          session.checkOutAt != null)
      .toList();
  if (completed.isEmpty) return null;
  completed.sort((a, b) => b.checkOutAt!.compareTo(a.checkOutAt!));
  return completed.first;
}

String _durationLabel(AttendanceSession session) {
  final end = session.checkOutAt ??
      (session.status.trim().toLowerCase() == AttendanceSessionStatus.active
          ? DateTime.now()
          : null);
  final minutes = session.checkOutAt != null
      ? session.durationMinutes ?? end?.difference(session.checkInAt).inMinutes
      : end?.difference(session.checkInAt).inMinutes;
  if (minutes == null) return 'Unknown';
  final safe = minutes.clamp(0, 1 << 30);
  if (safe < 60) return '${safe}m';
  return '${safe ~/ 60}h ${safe % 60}m';
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Unknown';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatDateTime(DateTime? date) {
  if (date == null) return 'Unknown';
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_formatDate(date)} $hour:$minute';
}

String _timeOnly(DateTime? date) {
  if (date == null) return 'Unknown';
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _emptyDash(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? '-' : trimmed;
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '';
  final first = parts.first[0];
  final second = parts.length > 1 ? parts[1][0] : '';
  return '$first$second'.toUpperCase();
}

Color _sessionStatusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case AttendanceSessionStatus.active:
      return greenSuccess;
    case AttendanceSessionStatus.completed:
      return blueInfo;
    case AttendanceSessionStatus.cancelled:
      return orangeWarning;
    default:
      return const Color(0xFF666666);
  }
}

Color _paymentColor(String status) {
  switch (status.trim().toLowerCase()) {
    case TransactionPaymentStatus.paid:
      return greenSuccess;
    case TransactionPaymentStatus.partial:
      return orangeWarning;
    case TransactionPaymentStatus.unpaid:
      return redAlert;
    default:
      return const Color(0xFF666666);
  }
}

String? _qrPayloadFor(Member member) {
  final qrCode = member.qrCode?.trim();
  if (qrCode != null && qrCode.isNotEmpty) return qrCode;

  final accessCode = member.accessCode?.trim();
  if (accessCode != null && accessCode.isNotEmpty) return accessCode;

  final nfcTagId = member.nfcTagId?.trim();
  if (nfcTagId != null && nfcTagId.isNotEmpty) return nfcTagId;

  return null;
}

String _maskedAccessValue(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 4) return trimmed;
  if (trimmed.length <= 8) {
    return '${trimmed.substring(0, 2)}••${trimmed.substring(trimmed.length - 2)}';
  }
  return '${trimmed.substring(0, 4)}••••${trimmed.substring(trimmed.length - 4)}';
}

String _occupancyStatus(int? percent) {
  if (percent == null) return 'Count only';
  if (percent >= 90) return 'Full';
  if (percent >= 75) return 'Busy';
  if (percent >= 50) return 'Moderate';
  return 'Quiet';
}

String _cardReasonLabel(String reason) {
  switch (reason) {
    case 'This member has been archived.':
      return 'This member has been archived';
    case 'Member profile is inactive.':
      return 'Member inactive';
    case 'Member account is inactive.':
      return 'Member account inactive';
    case 'Access credential is disabled.':
      return 'Access disabled';
    case 'Access credential was reported lost.':
      return 'Access lost';
    case 'Access credential was replaced.':
      return 'Access replaced';
    case 'Subscription expired.':
      return 'Subscription expired';
    case 'Subscription is unpaid.':
      return 'Subscription unpaid';
    case 'No active subscription found.':
      return 'No active subscription';
    case 'Subscription is expiring soon.':
      return 'Subscription expiring soon';
    case 'Subscription has a partial payment.':
      return 'Partial payment';
    default:
      return reason;
  }
}

String _friendlyFirestoreError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'This data is not available for your account.';
      case 'failed-precondition':
        return 'This data needs a Firestore index before it can load.';
      case 'unavailable':
        return 'Firestore is unavailable right now. Please try again.';
      default:
        return error.message ?? 'Could not load this data.';
    }
  }
  return 'Could not load this data.';
}

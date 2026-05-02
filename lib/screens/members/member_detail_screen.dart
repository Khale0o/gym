import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/core/helpers.dart';
import 'package:gymsaas/models/effective_subscription_status.dart';
import 'package:gymsaas/models/checkin.dart';
import 'package:gymsaas/models/member_access_eligibility.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/models/subscription.dart';
import 'package:gymsaas/models/transaction_model.dart';
import 'package:gymsaas/navigation/role_capabilities.dart';
import 'package:gymsaas/providers/auth_provider.dart';
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

class _DetailBody extends ConsumerWidget {
  final Member member;
  const _DetailBody({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(memberSubscriptionsProvider(member.id));
    final transactionsAsync = ref.watch(memberTransactionsProvider(member.id));
    final checkinsAsync = ref.watch(memberCheckinsProvider(member.id));

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
                _RightColumn(
                  member: member,
                  subscriptionsAsync: subscriptionsAsync,
                  transactionsAsync: transactionsAsync,
                  checkinsAsync: checkinsAsync,
                ),
              ] else ...[
                // ترتيب جانبي للكمبيوتر
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 280, child: _LeftColumn(member: member)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _RightColumn(
                        member: member,
                        subscriptionsAsync: subscriptionsAsync,
                        transactionsAsync: transactionsAsync,
                        checkinsAsync: checkinsAsync,
                      ),
                    ),
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
    final isMobile = MediaQuery.of(context).size.width < 700;
    final subscriptionState = EffectiveSubscriptionState.fromMember(member);
    final planName = (member.currentPlanName ?? '').trim().isEmpty
        ? member.plan
        : member.currentPlanName!.trim();
    final eligibility = evaluateMemberAccessEligibility(member);
    final hasSubscriptionSummary = (member.currentPlanName ?? '').trim().isNotEmpty ||
        (member.subscriptionStatus ?? '').trim().isNotEmpty ||
        member.subscriptionEndDate != null ||
        (member.paymentStatus ?? '').trim().isNotEmpty;

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
                    text: planName,
                    color: planName == 'Elite'
                        ? gold
                        : planName == 'Premium'
                            ? blueInfo
                            : const Color(0xFF555555),
                  ),
                  const SizedBox(width: 8),
                  ApexBadge(
                    text: subscriptionState.label,
                    color: subscriptionState.color,
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 10 : 12),
              _HeaderLine(
                icon: Icons.phone_rounded,
                text: (member.phone ?? '').trim().isEmpty
                    ? 'No phone'
                    : member.phone!.trim(),
              ),
              if ((member.email ?? '').trim().isNotEmpty)
                _HeaderLine(
                  icon: Icons.email_rounded,
                  text: member.email!.trim(),
                ),
              _HeaderLine(
                icon: Icons.verified_user_rounded,
                text:
                    'Member ${member.status} / Account ${member.accountStatus ?? 'not linked'}',
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
        _AccessEligibilityPanel(eligibility: eligibility),
        SizedBox(height: isMobile ? 10 : 12),
        ApexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GoldHeading('Subscription', fontSize: 13),
              const SizedBox(height: 10),
              Row(
                children: [
                  ApexBadge(
                    text: subscriptionState.label,
                    color: subscriptionState.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ApexText(
                      subscriptionState.description,
                      fontSize: 11,
                      color: const Color(0xFF777777),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _StatRow('Current Plan', hasSubscriptionSummary ? planName : 'None'),
              _StatRow(
                'Sub. Ends',
                member.subscriptionEndDate == null
                    ? 'Not set'
                    : _formatDate(member.subscriptionEndDate!),
              ),
              _StatRow(
                'Payment',
                (member.paymentStatus ?? '').trim().isEmpty
                    ? 'Not set'
                    : member.paymentStatus!,
              ),
              if (!hasSubscriptionSummary)
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: ApexText(
                    'No active/current subscription summary is available.',
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
              const GoldHeading('Access Identifier', fontSize: 13),
              const SizedBox(height: 10),
              _StatRow('NFC Tag ID', _emptyDash(member.nfcTagId)),
              _StatRow(
                'QR / Access Code',
                _emptyDash(member.qrCode ?? member.accessCode),
              ),
              _StatRow(
                'Access Status',
                _emptyDash(member.accessStatus ?? 'active'),
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
              _StatRow('Sub. Status', subscriptionState.label),
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

class _HeaderLine extends StatelessWidget {
  const _HeaderLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF666666)),
          const SizedBox(width: 7),
          Expanded(
            child: ApexText(
              text,
              fontSize: 11,
              color: const Color(0xFF888888),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessEligibilityPanel extends StatelessWidget {
  const _AccessEligibilityPanel({required this.eligibility});

  final MemberAccessEligibility eligibility;

  @override
  Widget build(BuildContext context) {
    final color = eligibility.color;

    return ApexCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            eligibility.allowed
                ? Icons.verified_rounded
                : Icons.block_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApexText(
                  eligibility.title,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 4),
                ApexText(
                  eligibility.message,
                  fontSize: 11,
                  color: const Color(0xFF999999),
                ),
                if (eligibility.reasons.length > 1) ...[
                  const SizedBox(height: 6),
                  ...eligibility.reasons.skip(1).map(
                        (reason) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: ApexText(
                            reason,
                            fontSize: 10,
                            color: const Color(0xFF777777),
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
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
  final AsyncValue<List<GymSubscription>> subscriptionsAsync;
  final AsyncValue<List<GymTransaction>> transactionsAsync;
  final AsyncValue<List<CheckIn>> checkinsAsync;

  const _RightColumn({
    required this.member,
    required this.subscriptionsAsync,
    required this.transactionsAsync,
    required this.checkinsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuickActions(member: member),
        const SizedBox(height: 12),
        _CurrentSubscriptionCard(
          member: member,
          subscriptionsAsync: subscriptionsAsync,
        ),
        const SizedBox(height: 12),
        _PaymentsHistoryCard(async: transactionsAsync),
        const SizedBox(height: 12),
        _SubscriptionHistoryCard(async: subscriptionsAsync),
        const SizedBox(height: 12),
        _CheckInHistoryCard(async: checkinsAsync),
        const SizedBox(height: 12),
        ApexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GoldHeading('Strength Progress', fontSize: 16),
              const SizedBox(height: 4),
              const ApexText(
                '6-week progression per lift',
                fontSize: 11,
                color: Color(0xFF555555),
              ),
              const SizedBox(height: 20),
              if (member.lifts.isEmpty)
                const ApexText('No lift data recorded', color: Color(0xFF444444))
              else
                ...member.lifts.map((lift) => _LiftCard(lift: lift)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final gymId = ref.watch(currentGymIdProvider)?.trim();
    final activeProfile = profile != null &&
        profile.status.trim().toLowerCase() == 'active' &&
        gymId != null &&
        gymId.isNotEmpty;
    final canEditMember =
        activeProfile && RoleCapabilities.canEditMember(profile.role);
    final canManageMemberAccess =
        activeProfile && RoleCapabilities.canManageMemberAccess(profile.role);
    final canOpenEditor = canEditMember || canManageMemberAccess;

    return ApexCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const GoldHeading('Member Timeline', fontSize: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/members'),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Members'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFCCCCCC),
                  side: const BorderSide(color: borderDark),
                ),
              ),
              FilledButton.icon(
                // TODO(phase-2j): preselect this member when Payments supports route params.
                onPressed: () => context.go('/payments'),
                icon: const Icon(Icons.receipt_long_rounded, size: 16),
                label: const Text('Record Payment / Renew'),
                style: FilledButton.styleFrom(backgroundColor: gold),
              ),
              if (canOpenEditor)
                FilledButton.icon(
                  onPressed: () => _showEditMemberSheet(
                    context: context,
                    ref: ref,
                    gymId: gymId,
                    member: member,
                    canEditMember: canEditMember,
                    canManageMemberAccess: canManageMemberAccess,
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit Member'),
                  style: FilledButton.styleFrom(
                    backgroundColor: card2Dark,
                    foregroundColor: gold,
                    side: const BorderSide(color: borderDark),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditMemberSheet({
    required BuildContext context,
    required WidgetRef ref,
    required String gymId,
    required Member member,
    required bool canEditMember,
    required bool canManageMemberAccess,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditMemberSheet(
        gymId: gymId,
        member: member,
        canEditMember: canEditMember,
        canManageMemberAccess: canManageMemberAccess,
      ),
    ).then((_) {
      ref.invalidate(gymMemberByIdProvider(member.id));
    });
  }
}

class _EditMemberSheet extends ConsumerStatefulWidget {
  const _EditMemberSheet({
    required this.gymId,
    required this.member,
    required this.canEditMember,
    required this.canManageMemberAccess,
  });

  final String gymId;
  final Member member;
  final bool canEditMember;
  final bool canManageMemberAccess;

  @override
  ConsumerState<_EditMemberSheet> createState() => _EditMemberSheetState();
}

class _EditMemberSheetState extends ConsumerState<_EditMemberSheet> {
  static const _accessStatusOptions = [
    'active',
    'disabled',
    'lost',
    'replaced',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _statusController;
  late final TextEditingController _notesController;
  late final TextEditingController _nfcTagIdController;
  late final TextEditingController _qrCodeController;
  late final TextEditingController _accessCodeController;
  late String _accessStatus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _fullNameController = TextEditingController(text: member.fullName);
    _phoneController = TextEditingController(text: member.phone ?? '');
    _emailController = TextEditingController(text: member.email ?? '');
    _statusController = TextEditingController(text: member.status);
    _notesController = TextEditingController(text: member.notes ?? '');
    _nfcTagIdController = TextEditingController(text: member.nfcTagId ?? '');
    _qrCodeController = TextEditingController(text: member.qrCode ?? '');
    _accessCodeController = TextEditingController(text: member.accessCode ?? '');
    final currentAccessStatus =
        (member.accessStatus ?? 'active').trim().toLowerCase();
    _accessStatus = _accessStatusOptions.contains(currentAccessStatus)
        ? currentAccessStatus
        : 'active';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _statusController.dispose();
    _notesController.dispose();
    _nfcTagIdController.dispose();
    _qrCodeController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FractionallySizedBox(
          heightFactor: isMobile ? 0.92 : 0.86,
          child: Container(
            decoration: const BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(top: BorderSide(color: borderDark)),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  14,
                  isMobile ? 16 : 24,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: GoldHeading('Edit Member', fontSize: 18),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: const Color(0xFF888888),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _EditMemberTextField(
                          controller: _fullNameController,
                          label: 'Full name',
                          requiredField: true,
                          enabled: widget.canEditMember && !_saving,
                          validator: _requiredValidator(
                            'Full name is required.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _EditMemberTextField(
                          controller: _phoneController,
                          label: 'Phone',
                          requiredField: true,
                          enabled: widget.canEditMember && !_saving,
                          keyboardType: TextInputType.phone,
                          validator: _requiredValidator('Phone is required.'),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _EditFieldSlot(
                              child: _EditMemberTextField(
                                controller: _emailController,
                                label: 'Email',
                                enabled: widget.canEditMember && !_saving,
                                keyboardType: TextInputType.emailAddress,
                                validator: _emailValidator,
                              ),
                            ),
                            _EditFieldSlot(
                              child: _EditMemberTextField(
                                controller: _statusController,
                                label: 'Status',
                                enabled: widget.canEditMember && !_saving,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _EditMemberTextField(
                          controller: _notesController,
                          label: 'Notes',
                          enabled: widget.canEditMember && !_saving,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 18),
                        const GoldHeading('Access', fontSize: 13),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _EditFieldSlot(
                              child: _EditMemberTextField(
                                controller: _nfcTagIdController,
                                label: 'NFC Tag ID',
                                enabled:
                                    widget.canManageMemberAccess && !_saving,
                              ),
                            ),
                            _EditFieldSlot(
                              child: _EditAccessStatusDropdown(
                                value: _accessStatus,
                                enabled:
                                    widget.canManageMemberAccess && !_saving,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _accessStatus = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _EditFieldSlot(
                              child: _EditMemberTextField(
                                controller: _qrCodeController,
                                label: 'QR code',
                                enabled:
                                    widget.canManageMemberAccess && !_saving,
                              ),
                            ),
                            _EditFieldSlot(
                              child: _EditMemberTextField(
                                controller: _accessCodeController,
                                label: 'Access code',
                                enabled:
                                    widget.canManageMemberAccess && !_saving,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFCCCCCC),
                                  side: const BorderSide(color: borderDark),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _saving ? null : _save,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF111111),
                                        ),
                                      )
                                    : const Icon(Icons.save_rounded, size: 16),
                                label: Text(_saving ? 'Saving...' : 'Save'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: gold,
                                  foregroundColor: const Color(0xFF111111),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref.read(memberRepositoryProvider).updateMemberProfileAndAccess(
            gymId: widget.gymId,
            memberId: widget.member.id,
            fullName: _fullNameController.text,
            phone: _phoneController.text,
            email: _emailController.text,
            status: _statusController.text,
            notes: _notesController.text,
            nfcTagId: _nfcTagIdController.text,
            qrCode: _qrCodeController.text,
            accessCode: _accessCodeController.text,
            accessStatus: _accessStatus,
          );

      ref.invalidate(gymMemberByIdProvider(widget.member.id));
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Member updated successfully.'),
          backgroundColor: greenSuccess,
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(_stateErrorMessage(error)),
          backgroundColor: redAlert,
        ),
      );
      setState(() => _saving = false);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(_friendlyFirestoreError(error)),
          backgroundColor: redAlert,
        ),
      );
      setState(() => _saving = false);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not update member: $error'),
          backgroundColor: redAlert,
        ),
      );
      setState(() => _saving = false);
    }
  }

  String? Function(String?) _requiredValidator(String message) {
    return (value) {
      if ((value ?? '').trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  String? _emailValidator(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final validEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
    return validEmail ? null : 'Enter a valid email address or leave empty.';
  }

  String _stateErrorMessage(StateError error) {
    final message = error.toString();
    const prefix = 'Bad state: ';
    if (message.startsWith(prefix)) {
      return message.substring(prefix.length);
    }
    return message;
  }

  String _friendlyFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to update this member.';
      case 'unavailable':
        return 'Firestore is unavailable right now. Please try again.';
      case 'not-found':
        return 'This member could not be found.';
      default:
        return error.message ?? 'Could not update member in Firestore.';
    }
  }
}

class _EditFieldSlot extends StatelessWidget {
  const _EditFieldSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width < 700 ? double.infinity : 320,
      child: child,
    );
  }
}

class _EditMemberTextField extends StatelessWidget {
  const _EditMemberTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.requiredField = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final bool requiredField;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 13),
      decoration: _editFieldDecoration(requiredField ? '$label *' : label),
    );
  }
}

class _EditAccessStatusDropdown extends StatelessWidget {
  const _EditAccessStatusDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: enabled ? onChanged : null,
      dropdownColor: card2Dark,
      style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 13),
      decoration: _editFieldDecoration('Access status'),
      items: const [
        DropdownMenuItem(value: 'active', child: Text('active')),
        DropdownMenuItem(value: 'disabled', child: Text('disabled')),
        DropdownMenuItem(value: 'lost', child: Text('lost')),
        DropdownMenuItem(value: 'replaced', child: Text('replaced')),
      ],
    );
  }
}

InputDecoration _editFieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF777777), fontSize: 12),
    errorStyle: const TextStyle(color: redAlert, fontSize: 11),
    filled: true,
    fillColor: card2Dark,
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: borderDark),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: borderDark),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: borderDark),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: gold),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: redAlert),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: redAlert),
    ),
  );
}

class _CurrentSubscriptionCard extends StatelessWidget {
  const _CurrentSubscriptionCard({
    required this.member,
    required this.subscriptionsAsync,
  });

  final Member member;
  final AsyncValue<List<GymSubscription>> subscriptionsAsync;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Current Subscription', fontSize: 16),
          const SizedBox(height: 14),
          subscriptionsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: gold),
              ),
            ),
            error: (error, _) => _HistoryError(error: error),
            data: (subscriptions) {
              final latest = _latestSubscription(subscriptions);
              final effective = latest == null
                  ? EffectiveSubscriptionState.fromMember(member)
                  : resolveEffectiveSubscriptionStatus(
                      subscriptionStatus: latest.status,
                      subscriptionEndDate: latest.endDate,
                      paymentStatus: latest.paymentStatus,
                    );
              final planName = latest?.planName ??
                  ((member.currentPlanName ?? '').trim().isEmpty
                      ? 'No current plan'
                      : member.currentPlanName!.trim());
              final startDate = latest?.startDate;
              final endDate = latest?.endDate ?? member.subscriptionEndDate;
              final paymentStatus = latest?.paymentStatus ?? member.paymentStatus;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ApexBadge(text: effective.label, color: effective.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ApexText(
                          planName,
                          color: const Color(0xFFE8E8E8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoGrid(
                    rows: [
                      _InfoRow('Payment', _emptyDash(paymentStatus)),
                      _InfoRow('Start', _formatOptionalDate(startDate)),
                      _InfoRow('End', _formatOptionalDate(endDate)),
                      _InfoRow('Remaining', _remainingLabel(endDate)),
                      _InfoRow(
                        'Amount',
                        latest == null
                            ? '-'
                            : '${latest.amount.toStringAsFixed(0)} ${latest.currency}',
                      ),
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

  static GymSubscription? _latestSubscription(List<GymSubscription> rows) {
    if (rows.isEmpty) return null;
    final copy = [...rows];
    copy.sort((a, b) {
      final aDate = a.startDate ?? a.createdAt ?? DateTime(1900);
      final bDate = b.startDate ?? b.createdAt ?? DateTime(1900);
      return bDate.compareTo(aDate);
    });
    return copy.first;
  }
}

class _PaymentsHistoryCard extends StatelessWidget {
  const _PaymentsHistoryCard({required this.async});

  final AsyncValue<List<GymTransaction>> async;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Payments / Receipts', fontSize: 16),
          const SizedBox(height: 14),
          async.when(
            loading: () => const _HistoryLoading(),
            error: (error, _) => _HistoryError(error: error),
            data: (transactions) {
              final rows = transactions.take(10).toList();
              if (rows.isEmpty) {
                return const _EmptyHistory('No payments recorded yet.');
              }
              return Column(
                children: rows
                    .map(
                      (tx) => _TimelineRow(
                        icon: Icons.receipt_long_rounded,
                        title: tx.receiptNumber,
                        subtitle:
                            '${tx.amount.toStringAsFixed(0)} ${tx.currency} - ${tx.paymentMethod} - ${tx.paymentStatus}',
                        trailing: _formatOptionalDateTime(tx.createdAt),
                        note: tx.notes,
                        color: tx.paymentStatus == TransactionPaymentStatus.paid
                            ? greenSuccess
                            : orangeWarning,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SubscriptionHistoryCard extends StatelessWidget {
  const _SubscriptionHistoryCard({required this.async});

  final AsyncValue<List<GymSubscription>> async;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Subscription History', fontSize: 16),
          const SizedBox(height: 14),
          async.when(
            loading: () => const _HistoryLoading(),
            error: (error, _) => _HistoryError(error: error),
            data: (subscriptions) {
              final rows = subscriptions.take(10).toList();
              if (rows.isEmpty) {
                return const _EmptyHistory('No subscription history yet.');
              }
              return Column(
                children: rows
                    .map(
                      (sub) => _TimelineRow(
                        icon: Icons.card_membership_rounded,
                        title: sub.planName,
                        subtitle:
                            '${sub.status} - ${sub.paymentStatus} - ${sub.amount.toStringAsFixed(0)} ${sub.currency}',
                        trailing:
                            '${_formatOptionalDate(sub.startDate)} to ${_formatOptionalDate(sub.endDate)}',
                        color: sub.paymentStatus == SubscriptionPaymentStatus.unpaid
                            ? redAlert
                            : blueInfo,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CheckInHistoryCard extends StatelessWidget {
  const _CheckInHistoryCard({required this.async});

  final AsyncValue<List<CheckIn>> async;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Check-in History', fontSize: 16),
          const SizedBox(height: 14),
          async.when(
            loading: () => const _HistoryLoading(),
            error: (error, _) => _HistoryError(error: error),
            data: (checkins) {
              final rows = checkins.take(10).toList();
              if (rows.isEmpty) {
                return const _EmptyHistory('No check-ins yet.');
              }
              return Column(
                children: rows
                    .map(
                      (checkin) => _TimelineRow(
                        icon: Icons.login_rounded,
                        title: _formatOptionalDateTime(checkin.time),
                        subtitle: '${checkin.method} - ${checkin.plan}',
                        color: greenSuccess,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows
          .map((row) => _StatRow(row.label, row.value))
          .toList(),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
    this.note,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final String? note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApexText(
                  title,
                  color: const Color(0xFFE2E2E2),
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 3),
                ApexText(
                  subtitle,
                  fontSize: 11,
                  color: const Color(0xFF777777),
                ),
                if ((note ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ApexText(
                    note!.trim(),
                    fontSize: 11,
                    color: const Color(0xFF999999),
                  ),
                ],
              ],
            ),
          ),
          if ((trailing ?? '').isNotEmpty) ...[
            const SizedBox(width: 8),
            ApexText(
              trailing!,
              fontSize: 10,
              color: const Color(0xFF666666),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: Center(child: CircularProgressIndicator(color: gold)),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return ApexText(
      _friendlyHistoryError(error),
      color: orangeWarning,
      fontSize: 12,
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return ApexText(message, color: const Color(0xFF555555));
  }
}

String _formatOptionalDate(DateTime? date) {
  if (date == null) return '-';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatOptionalDateTime(DateTime? date) {
  if (date == null) return '-';
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_formatOptionalDate(date)} $hour:$minute';
}

String _remainingLabel(DateTime? endDate) {
  if (endDate == null) return 'Not set';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final endDay = DateTime(endDate.year, endDate.month, endDate.day);
  final days = endDay.difference(today).inDays;
  if (days == 0) return 'Ends today';
  if (days > 0) return '$days days remaining';
  final expiredDays = days.abs();
  return 'Expired $expiredDays ${expiredDays == 1 ? 'day' : 'days'} ago';
}

String _emptyDash(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? '-' : trimmed;
}

String _friendlyHistoryError(Object error) {
  final message = error.toString();
  if (message.toLowerCase().contains('index')) {
    return 'This history needs a Firestore index. Check the console link in debug logs.';
  }
  return 'Could not load this history: $message';
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

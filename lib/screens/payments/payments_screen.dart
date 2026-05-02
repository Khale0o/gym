import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/models/effective_subscription_status.dart';
import 'package:gymsaas/models/gym_settings.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/models/membership_plan.dart';
import 'package:gymsaas/models/subscription.dart';
import 'package:gymsaas/models/transaction_model.dart';
import 'package:gymsaas/navigation/role_capabilities.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';
import 'package:gymsaas/repositories/transaction_repository.dart';
import 'package:gymsaas/widgets/apex_badge.dart';
import 'package:gymsaas/widgets/apex_card.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/shimmer_placeholder.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  Member? _selectedMember;
  MembershipPlan? _selectedPlan;
  String _paymentMethod = TransactionPaymentMethod.cash;
  String _paymentStatus = TransactionPaymentStatus.paid;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final canProcess = profile != null &&
        profile.status == 'active' &&
        RoleCapabilities.canProcessPayments(profile.role);
    final transactionsAsync = ref.watch(gymTransactionsProvider);
    final membersAsync = ref.watch(gymMembersProvider);
    final plansAsync = ref.watch(gymActivePlansProvider);
    final appSettingsAsync = ref.watch(appSettingsProvider);
    final enabledPaymentMethods =
        _enabledPaymentMethods(appSettingsAsync.valueOrNull);

    if (enabledPaymentMethods.isNotEmpty &&
        !enabledPaymentMethods.contains(_paymentMethod)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _paymentMethod = enabledPaymentMethods.first);
      });
    }

    if (!canProcess) {
      return const Scaffold(
        backgroundColor: bgDark,
        body: Center(
          child: ApexText(
            'You do not have permission to record payments.',
            color: redAlert,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GoldHeading('Payments', fontSize: 18),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 900;
                  final form = _PaymentForm(
                    membersAsync: membersAsync,
                    plansAsync: plansAsync,
                    selectedMember: _selectedMember,
                    selectedPlan: _selectedPlan,
                    amountController: _amountController,
                    notesController: _notesController,
                    paymentMethod: _paymentMethod,
                    paymentStatus: _paymentStatus,
                    enabledPaymentMethods: enabledPaymentMethods,
                    saving: _saving,
                    onMemberChanged: _onMemberChanged,
                    onPlanChanged: _onPlanChanged,
                    onMethodChanged: (value) => setState(
                      () => _paymentMethod =
                          value ?? TransactionPaymentMethod.unknown,
                    ),
                    onStatusChanged: (value) => setState(
                      () => _paymentStatus =
                          value ?? TransactionPaymentStatus.paid,
                    ),
                    onSave: _savePayment,
                  );
                  final list = _TransactionsList(async: transactionsAsync);

                  if (isNarrow) {
                    return Column(
                      children: [
                        form,
                        const SizedBox(height: 16),
                        list,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: form),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: list),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMemberChanged(Member? member) {
    setState(() {
      _selectedMember = member;
      _selectedPlan = null;
      _amountController.clear();
    });
  }

  void _onPlanChanged(MembershipPlan? plan) {
    setState(() {
      _selectedPlan = plan;
      if (plan != null) {
        _amountController.text = plan.price.toStringAsFixed(0);
      }
    });
  }

  Future<void> _savePayment() async {
    if (_saving) return;
    final gymId = ref.read(currentGymIdProvider)?.trim();
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final user = ref.read(currentAuthUserProvider);
    final member = _selectedMember;
    final plan = _selectedPlan;
    final amount = double.tryParse(_amountController.text.trim());
    final enabledPaymentMethods =
        _enabledPaymentMethods(ref.read(appSettingsProvider).valueOrNull);

    if (gymId == null || gymId.isEmpty) {
      _showError('Current gym is required.');
      return;
    }
    if (profile == null ||
        profile.status != 'active' ||
        !RoleCapabilities.canProcessPayments(profile.role)) {
      _showError('You do not have permission to record payments.');
      return;
    }
    if (user == null) {
      _showError('You must be signed in to record payments.');
      return;
    }
    if (member == null) {
      _showError('Select a member first.');
      return;
    }
    if (plan == null) {
      _showError('Select a plan for renewal.');
      return;
    }
    if (amount == null || !amount.isFinite || amount <= 0) {
      _showError('Amount must be greater than zero.');
      return;
    }
    if (_paymentMethod.trim().isEmpty ||
        _paymentMethod == TransactionPaymentMethod.unknown) {
      _showError('Payment method is required.');
      return;
    }
    if (enabledPaymentMethods.isEmpty) {
      _showError('No valid payment method is available.');
      return;
    }
    if (!enabledPaymentMethods.contains(_paymentMethod)) {
      _showError('Selected payment method is disabled in Settings.');
      return;
    }

    setState(() => _saving = true);
    try {
      final subscriptionsAsync = ref.read(memberSubscriptionsProvider(member.id));
      if (!subscriptionsAsync.hasValue) {
        _showError('Member subscriptions are still loading. Try again.');
        return;
      }
      final memberSubscriptions =
          subscriptionsAsync.valueOrNull ?? const <GymSubscription>[];
      final baseSubscription = _findRenewalBaseSubscription(
        subscriptions: memberSubscriptions,
        planId: plan.id,
      );
      final created = await ref.read(transactionRepositoryProvider).createRenewalPayment(
            gymId: gymId,
            input: CreateRenewalPaymentInput(
              memberId: member.id,
              memberName: member.fullName,
              planId: plan.id,
              baseSubscriptionId: baseSubscription?.id,
              amount: amount,
              currency: plan.currency,
              paymentMethod: _paymentMethod,
              paymentStatus: _paymentStatus,
              createdByUid: user.uid,
              createdByName: profile.displayName,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          );
      if (!mounted) return;
      setState(() {
        _selectedPlan = null;
        _amountController.clear();
        _notesController.clear();
        _paymentStatus = TransactionPaymentStatus.paid;
        _paymentMethod = enabledPaymentMethods.first;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment recorded. Receipt ${created.receiptNumber}'),
          backgroundColor: greenSuccess,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString().replaceFirst('StateError: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: redAlert),
    );
  }

  GymSubscription? _findRenewalBaseSubscription({
    required List<GymSubscription> subscriptions,
    required String planId,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recentCutoff = today.subtract(const Duration(days: 30));
    final candidates = subscriptions.where((subscription) {
      if (subscription.planId != planId) return false;
      final endDate = subscription.endDate;
      final endDay = endDate == null
          ? null
          : DateTime(endDate.year, endDate.month, endDate.day);
      final isActive = subscription.status == SubscriptionStatus.active &&
          (endDay == null || !endDay.isBefore(today));
      final isRecentlyExpired =
          endDay != null && endDay.isBefore(today) && !endDay.isBefore(recentCutoff);
      return isActive || isRecentlyExpired;
    }).toList();

    candidates.sort((a, b) {
      final aEnd = a.endDate ?? DateTime(1900);
      final bEnd = b.endDate ?? DateTime(1900);
      return bEnd.compareTo(aEnd);
    });
    return candidates.isEmpty ? null : candidates.first;
  }
}

List<String> _enabledPaymentMethods(AppSettings? settings) {
  const supported = AppSettings.defaultPaymentMethods;
  final configured = settings?.enabledPaymentMethods ?? supported;
  final enabled = configured
      .where((method) => supported.contains(method))
      .toSet()
      .toList();
  return enabled.isEmpty ? supported : enabled;
}

String _paymentMethodLabel(String method) {
  switch (method) {
    case TransactionPaymentMethod.cash:
      return 'Cash';
    case TransactionPaymentMethod.instapay:
      return 'Instapay';
    case TransactionPaymentMethod.vodafoneCash:
      return 'Vodafone Cash';
    case TransactionPaymentMethod.card:
      return 'Card';
    case TransactionPaymentMethod.online:
      return 'Online';
    default:
      return method;
  }
}

class _PaymentForm extends ConsumerWidget {
  const _PaymentForm({
    required this.membersAsync,
    required this.plansAsync,
    required this.selectedMember,
    required this.selectedPlan,
    required this.amountController,
    required this.notesController,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.enabledPaymentMethods,
    required this.saving,
    required this.onMemberChanged,
    required this.onPlanChanged,
    required this.onMethodChanged,
    required this.onStatusChanged,
    required this.onSave,
  });

  final AsyncValue<List<Member>> membersAsync;
  final AsyncValue<List<MembershipPlan>> plansAsync;
  final Member? selectedMember;
  final MembershipPlan? selectedPlan;
  final TextEditingController amountController;
  final TextEditingController notesController;
  final String paymentMethod;
  final String paymentStatus;
  final List<String> enabledPaymentMethods;
  final bool saving;
  final ValueChanged<Member?> onMemberChanged;
  final ValueChanged<MembershipPlan?> onPlanChanged;
  final ValueChanged<String?> onMethodChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = selectedMember == null
        ? const AsyncValue<List<GymSubscription>>.data([])
        : ref.watch(memberSubscriptionsProvider(selectedMember!.id));

    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Record Payment'),
          const SizedBox(height: 16),
          membersAsync.when(
            loading: () => const ShimmerCard(),
            error: (error, _) => ApexText(
              'Members unavailable: $error',
              color: redAlert,
            ),
            data: (members) => DropdownButtonFormField<String>(
              initialValue: selectedMember?.id,
              dropdownColor: card2Dark,
              iconEnabledColor: gold,
              decoration: _decoration('Member'),
              items: members
                  .map(
                    (member) => DropdownMenuItem(
                      value: member.id,
                      child: Text(member.fullName),
                    ),
                  )
                  .toList(),
              onChanged: saving
                  ? null
                  : (value) {
                      final member = value == null
                          ? null
                          : members.firstWhere((m) => m.id == value);
                      onMemberChanged(member);
                    },
            ),
          ),
          _SelectedMemberStatus(member: selectedMember),
          const SizedBox(height: 12),
          plansAsync.when(
            loading: () => const ShimmerCard(),
            error: (error, _) => ApexText(
              'Plans unavailable: $error',
              color: orangeWarning,
            ),
            data: (plans) => DropdownButtonFormField<String>(
              initialValue: selectedPlan?.id,
              dropdownColor: card2Dark,
              iconEnabledColor: gold,
              decoration: _decoration('Active plan'),
              items: plans
                  .map(
                    (plan) => DropdownMenuItem(
                      value: plan.id,
                      child: Text(
                        '${plan.name} - ${plan.price.toStringAsFixed(0)} ${plan.currency}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: saving
                  ? null
                  : (value) {
                      final plan = value == null
                          ? null
                          : plans.firstWhere((p) => p.id == value);
                      onPlanChanged(plan);
                    },
            ),
          ),
          _RenewalHint(
            selectedMember: selectedMember,
            selectedPlan: selectedPlan,
            subscriptionsAsync: subscriptionsAsync,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            enabled: !saving,
            keyboardType: TextInputType.number,
            decoration: _decoration('Amount'),
            style: const TextStyle(color: Color(0xFFE8E8E8)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: enabledPaymentMethods.contains(paymentMethod)
                      ? paymentMethod
                      : null,
                  dropdownColor: card2Dark,
                  iconEnabledColor: gold,
                  decoration: _decoration('Payment method'),
                  items: enabledPaymentMethods
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(_paymentMethodLabel(method)),
                        ),
                      )
                      .toList(),
                  onChanged: saving ? null : onMethodChanged,
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: paymentStatus,
                  dropdownColor: card2Dark,
                  iconEnabledColor: gold,
                  decoration: _decoration('Payment status'),
                  items: const [
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'partial', child: Text('Partial')),
                    DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                  ],
                  onChanged: saving ? null : onStatusChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            enabled: !saving,
            maxLines: 3,
            decoration: _decoration('Notes optional'),
            style: const TextStyle(color: Color(0xFFE8E8E8)),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('Record Payment'),
              style: FilledButton.styleFrom(backgroundColor: gold),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF777777)),
      filled: true,
      fillColor: const Color(0xFF090909),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: borderDark),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: gold),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _SelectedMemberStatus extends StatelessWidget {
  const _SelectedMemberStatus({required this.member});

  final Member? member;

  @override
  Widget build(BuildContext context) {
    final value = member;
    if (value == null) return const SizedBox.shrink();

    final state = EffectiveSubscriptionState.fromMember(value);
    final planName = (value.currentPlanName ?? '').trim().isEmpty
        ? 'No current plan'
        : value.currentPlanName!.trim();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          ApexBadge(text: state.label, color: state.color),
          const SizedBox(width: 8),
          Expanded(
            child: ApexText(
              '$planName - ${state.description}',
              fontSize: 11,
              color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewalHint extends StatelessWidget {
  const _RenewalHint({
    required this.selectedMember,
    required this.selectedPlan,
    required this.subscriptionsAsync,
  });

  final Member? selectedMember;
  final MembershipPlan? selectedPlan;
  final AsyncValue<List<GymSubscription>> subscriptionsAsync;

  @override
  Widget build(BuildContext context) {
    if (selectedMember == null || selectedPlan == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: subscriptionsAsync.when(
        loading: () => const ApexText(
          'Checking renewal date...',
          fontSize: 11,
          color: Color(0xFF666666),
        ),
        error: (_, __) => const ApexText(
          'Renewal will start today if subscriptions cannot be loaded.',
          fontSize: 11,
          color: orangeWarning,
        ),
        data: (subscriptions) {
          final base = _findBaseSubscription(
            subscriptions: subscriptions,
            planId: selectedPlan!.id,
          );
          final startDate = _renewalStartDate(base);
          return ApexText(
            base == null
                ? 'New ${selectedPlan!.name} period starts ${_formatDate(startDate)}.'
                : 'Renews ${selectedPlan!.name} from ${_formatDate(startDate)}.',
            fontSize: 11,
            color: const Color(0xFF777777),
          );
        },
      ),
    );
  }

  static GymSubscription? _findBaseSubscription({
    required List<GymSubscription> subscriptions,
    required String planId,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recentCutoff = today.subtract(const Duration(days: 30));
    final candidates = subscriptions.where((subscription) {
      if (subscription.planId != planId) return false;
      final endDate = subscription.endDate;
      final endDay = endDate == null
          ? null
          : DateTime(endDate.year, endDate.month, endDate.day);
      final isActive = subscription.status == SubscriptionStatus.active &&
          (endDay == null || !endDay.isBefore(today));
      final isRecentlyExpired = endDay != null &&
          endDay.isBefore(today) &&
          !endDay.isBefore(recentCutoff);
      return isActive || isRecentlyExpired;
    }).toList();

    candidates.sort((a, b) {
      final aEnd = a.endDate ?? DateTime(1900);
      final bEnd = b.endDate ?? DateTime(1900);
      return bEnd.compareTo(aEnd);
    });
    return candidates.isEmpty ? null : candidates.first;
  }

  static DateTime _renewalStartDate(GymSubscription? base) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final previousEnd = base?.endDate;
    if (previousEnd == null) return today;

    final nextStart = DateTime(
      previousEnd.year,
      previousEnd.month,
      previousEnd.day,
    ).add(const Duration(days: 1));
    return nextStart.isAfter(today) ? nextStart : today;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({required this.async});

  final AsyncValue<List<GymTransaction>> async;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHeading('Recent Receipts'),
          const SizedBox(height: 16),
          async.when(
            loading: () => Column(
              children: List.generate(
                5,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: ShimmerCard(),
                ),
              ),
            ),
            error: (error, _) => ApexText('Error: $error', color: redAlert),
            data: (transactions) {
              if (transactions.isEmpty) {
                return const ApexText(
                  'No payments recorded yet',
                  color: Color(0xFF666666),
                );
              }
              return Column(
                children: transactions
                    .take(12)
                    .map((tx) => _TransactionRow(transaction: tx))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final GymTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showReceiptDetails(context, transaction),
        child: Container(
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
                          ? transaction.description
                          : transaction.memberName,
                      color: const Color(0xFFE2E2E2),
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 3),
                    ApexText(
                      transaction.receiptNumber,
                      fontSize: 10,
                      color: const Color(0xFF666666),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Color(0xFF444444),
                size: 18,
              ),
              const SizedBox(width: 8),
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
                    text: transaction.paymentMethod,
                    color: transaction.paymentStatus ==
                            TransactionPaymentStatus.paid
                        ? greenSuccess
                        : orangeWarning,
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

void _showReceiptDetails(BuildContext context, GymTransaction transaction) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReceiptDetailsSheet(transaction: transaction),
  );
}

class _ReceiptDetailsSheet extends ConsumerWidget {
  const _ReceiptDetailsSheet({required this.transaction});

  final GymTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = transaction.memberId.trim().isEmpty
        ? const AsyncValue<Member?>.data(null)
        : ref.watch(gymMemberByIdProvider(transaction.memberId));

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Container(
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
                  const Expanded(
                    child: GoldHeading('Receipt Details', fontSize: 18),
                  ),
                  IconButton(
                    tooltip: 'Copy receipt number',
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: transaction.receiptNumber),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Receipt number copied.'),
                          backgroundColor: greenSuccess,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    color: const Color(0xFF888888),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF888888),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ReceiptHero(transaction: transaction),
              const SizedBox(height: 14),
              memberAsync.when(
                loading: () => const ShimmerCard(),
                error: (_, __) => _ReceiptFields(
                  transaction: transaction,
                  member: null,
                  memberError: 'Member details unavailable.',
                ),
                data: (member) => _ReceiptFields(
                  transaction: transaction,
                  member: member,
                ),
              ),
              if (transaction.memberId.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/members/${transaction.memberId}');
                  },
                  icon: const Icon(Icons.person_rounded, size: 18),
                  label: const Text('View Member'),
                  style: FilledButton.styleFrom(backgroundColor: gold),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ReceiptHero extends StatelessWidget {
  const _ReceiptHero({required this.transaction});

  final GymTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final statusColor = transaction.paymentStatus == TransactionPaymentStatus.paid
        ? greenSuccess
        : orangeWarning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderDark),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: gold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApexText(
                  transaction.receiptNumber,
                  color: const Color(0xFFE2E2E2),
                  fontWeight: FontWeight.w800,
                ),
                const SizedBox(height: 4),
                ApexText(
                  '${transaction.amount.toStringAsFixed(0)} ${transaction.currency}',
                  color: greenSuccess,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ),
          ApexBadge(
            text: transaction.paymentStatus,
            color: statusColor,
          ),
        ],
      ),
    );
  }
}

class _ReceiptFields extends StatelessWidget {
  const _ReceiptFields({
    required this.transaction,
    required this.member,
    this.memberError,
  });

  final GymTransaction transaction;
  final Member? member;
  final String? memberError;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _ReceiptRow('Member', _fallback(transaction.memberName, 'Unknown member')),
      _ReceiptRow('Member phone', _fallback(member?.phone, 'Not available')),
      _ReceiptRow('Plan / Description', _fallback(transaction.description, 'Not available')),
      _ReceiptRow('Payment method', _paymentMethodLabel(transaction.paymentMethod)),
      _ReceiptRow('Payment status', transaction.paymentStatus),
      _ReceiptRow('Subscription ID', _fallback(transaction.subscriptionId, 'Not linked')),
      _ReceiptRow('Transaction ID', transaction.id),
      _ReceiptRow('Created date', _formatDateTime(transaction.createdAt)),
      _ReceiptRow('Created by', _fallback(transaction.createdByName, transaction.createdByUid.isEmpty ? 'Unknown' : transaction.createdByUid)),
      _ReceiptRow('Notes', _fallback(transaction.notes, 'No notes')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (memberError != null) ...[
          ApexText(memberError!, color: orangeWarning, fontSize: 12),
          const SizedBox(height: 10),
        ],
        ...rows.map(
          (row) => Container(
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
                SizedBox(
                  width: 118,
                  child: ApexText(
                    row.label,
                    fontSize: 11,
                    color: const Color(0xFF777777),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ApexText(
                    row.value,
                    color: const Color(0xFFE0E0E0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptRow {
  const _ReceiptRow(this.label, this.value);

  final String label;
  final String value;
}

String _fallback(String? value, String fallback) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? fallback : trimmed;
}

String _formatDateTime(DateTime? date) {
  if (date == null) return 'Not available';
  final ymd =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final hm =
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  return '$ymd $hm';
}

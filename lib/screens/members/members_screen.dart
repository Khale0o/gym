import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/core/helpers.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/models/membership_plan.dart';
import 'package:gymsaas/models/subscription.dart';
import 'package:gymsaas/navigation/role_capabilities.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/apex_badge.dart';
import 'package:gymsaas/widgets/shimmer_placeholder.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(gymMembersProvider);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final canCreateMember = profile != null &&
        profile.status == 'active' &&
        RoleCapabilities.canCreateMember(profile.role);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: bgDark,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const GoldHeading('Members', fontSize: 18),
                const Spacer(),
                async.maybeWhen(
                  data: (list) => ApexText(
                    '${list.length} total',
                    fontSize: 12,
                    color: const Color(0xFF555555),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                if (canCreateMember) ...[
                  const SizedBox(width: 12),
                  _AddMemberButton(
                    onPressed: () => _showAddMemberDialog(context),
                    compact: isMobile,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search members…',
                hintStyle: const TextStyle(color: Color(0xFF444444), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF444444), size: 18),
                filled: true,
                fillColor: cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: gold),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: async.when(
                loading: () => ListView.separated(
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, __) => const ShimmerCard(),
                ),
                error: (e, _) => Center(
                  child: ApexText('Error: $e', color: redAlert),
                ),
                data: (members) {
                  final filtered = _query.isEmpty
                      ? members
                      : members
                          .where((m) => m.name.toLowerCase().contains(_query))
                          .toList();
                  if (members.isEmpty) {
                    return _MembersEmptyState(
                      canCreateMember: canCreateMember,
                      onAddMember: () => _showAddMemberDialog(context),
                    );
                  }
                  if (filtered.isEmpty) {
                    return const Center(
                      child: ApexText('No members found', color: Color(0xFF444444)),
                    );
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _MemberCard(member: filtered[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMemberDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddMemberDialog(),
    );
  }
}

class _AddMemberButton extends StatelessWidget {
  const _AddMemberButton({
    required this.onPressed,
    required this.compact,
  });

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
      label: ApexText(
        compact ? 'Add' : 'Add Member',
        fontSize: 12,
        color: const Color(0xFF080808),
        fontWeight: FontWeight.w700,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: const Color(0xFF080808),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _MembersEmptyState extends StatelessWidget {
  const _MembersEmptyState({
    required this.canCreateMember,
    required this.onAddMember,
  });

  final bool canCreateMember;
  final VoidCallback onAddMember;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderDark),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.groups_2_rounded,
                color: gold,
                size: 24,
              ),
            ),
            const SizedBox(height: 14),
            const ApexText(
              'No members yet',
              fontSize: 16,
              color: Color(0xFFE8E8E8),
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 6),
            const ApexText(
              'Add your first member',
              fontSize: 12,
              color: Color(0xFF777777),
              textAlign: TextAlign.center,
            ),
            if (canCreateMember) ...[
              const SizedBox(height: 16),
              _AddMemberButton(onPressed: onAddMember, compact: false),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddMemberDialog extends ConsumerStatefulWidget {
  const _AddMemberDialog();

  @override
  ConsumerState<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<_AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _genderController = TextEditingController();
  final _goalController = TextEditingController();
  final _nfcTagIdController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _healthNotesController = TextEditingController();
  final _amountController = TextEditingController();
  final _subscriptionNotesController = TextEditingController();
  MembershipPlan? _selectedPlan;
  String _paymentStatus = SubscriptionPaymentStatus.unpaid;
  String _paymentMethod = SubscriptionPaymentMethod.cash;
  bool _saving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _genderController.dispose();
    _goalController.dispose();
    _nfcTagIdController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _healthNotesController.dispose();
    _amountController.dispose();
    _subscriptionNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final plansAsync = ref.watch(gymActivePlansProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 18 : 22),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderDark),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 26,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: GoldHeading('Add Member', fontSize: 18),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed:
                            _saving ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFF888888),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MemberTextField(
                    controller: _fullNameController,
                    label: 'Full name',
                    requiredField: true,
                    validator: _requiredValidator('Full name is required.'),
                  ),
                  const SizedBox(height: 12),
                  _MemberTextField(
                    controller: _phoneController,
                    label: 'Phone',
                    requiredField: true,
                    keyboardType: TextInputType.phone,
                    validator: _requiredValidator('Phone is required.'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    runSpacing: 12,
                    spacing: 12,
                    children: [
                      _FieldSlot(
                        child: _MemberTextField(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      _FieldSlot(
                        child: _MemberTextField(
                          controller: _genderController,
                          label: 'Gender',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    runSpacing: 12,
                    spacing: 12,
                    children: [
                      _FieldSlot(
                        child: _MemberTextField(
                          controller: _goalController,
                          label: 'Goal',
                        ),
                      ),
                      _FieldSlot(
                        child: _MemberTextField(
                          controller: _nfcTagIdController,
                          label: 'NFC tag ID',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    runSpacing: 12,
                    spacing: 12,
                    children: [
                      _FieldSlot(
                        child: _MemberTextField(
                          controller: _emergencyNameController,
                          label: 'Emergency contact name',
                        ),
                      ),
                      _FieldSlot(
                        child: _MemberTextField(
                          controller: _emergencyPhoneController,
                          label: 'Emergency contact phone',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MemberTextField(
                    controller: _healthNotesController,
                    label: 'Health notes',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const GoldHeading('Initial Subscription', fontSize: 13),
                  const SizedBox(height: 12),
                  plansAsync.when(
                    loading: () => const ApexText(
                      'Loading plans...',
                      color: Color(0xFF777777),
                    ),
                    error: (error, _) => ApexText(
                      'Plans unavailable: $error',
                      color: orangeWarning,
                    ),
                    data: (plans) => Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPlan?.id,
                          dropdownColor: card2Dark,
                          iconEnabledColor: gold,
                          style: const TextStyle(
                            color: Color(0xFFDDDDDD),
                            fontSize: 13,
                          ),
                          decoration: _fieldDecoration('Plan optional'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('No initial plan'),
                            ),
                            ...plans.map(
                              (plan) => DropdownMenuItem<String>(
                                value: plan.id,
                                child: Text(
                                  '${plan.name} - ${plan.price.toStringAsFixed(0)} ${plan.currency}',
                                ),
                              ),
                            ),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) {
                                  final plan = value == null || value.isEmpty
                                      ? null
                                      : plans.firstWhere((p) => p.id == value);
                                  setState(() {
                                    _selectedPlan = plan;
                                    _amountController.text = plan == null
                                        ? ''
                                        : plan.price.toStringAsFixed(0);
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          runSpacing: 12,
                          spacing: 12,
                          children: [
                            _FieldSlot(
                              child: _MemberTextField(
                                controller: _amountController,
                                label: 'Amount',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            _FieldSlot(
                              child: DropdownButtonFormField<String>(
                                initialValue: _paymentStatus,
                                dropdownColor: card2Dark,
                                iconEnabledColor: gold,
                                style: const TextStyle(
                                  color: Color(0xFFDDDDDD),
                                  fontSize: 13,
                                ),
                                decoration: _fieldDecoration('Payment status'),
                                items: const [
                                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                                  DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                                  DropdownMenuItem(value: 'partial', child: Text('Partial')),
                                ],
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(
                                          () => _paymentStatus =
                                              value ?? SubscriptionPaymentStatus.unpaid,
                                        ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          runSpacing: 12,
                          spacing: 12,
                          children: [
                            _FieldSlot(
                              child: DropdownButtonFormField<String>(
                                initialValue: _paymentMethod,
                                dropdownColor: card2Dark,
                                iconEnabledColor: gold,
                                style: const TextStyle(
                                  color: Color(0xFFDDDDDD),
                                  fontSize: 13,
                                ),
                                decoration: _fieldDecoration('Payment method'),
                                items: const [
                                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                                  DropdownMenuItem(value: 'instapay', child: Text('Instapay')),
                                  DropdownMenuItem(value: 'vodafone_cash', child: Text('Vodafone Cash')),
                                  DropdownMenuItem(value: 'card', child: Text('Card')),
                                  DropdownMenuItem(value: 'online', child: Text('Online')),
                                  DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
                                ],
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(
                                          () => _paymentMethod =
                                              value ?? SubscriptionPaymentMethod.unknown,
                                        ),
                              ),
                            ),
                            _FieldSlot(
                              child: _MemberTextField(
                                controller: _subscriptionNotesController,
                                label: 'Subscription notes',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _saving ? null : () => Navigator.of(context).pop(),
                        child: const ApexText(
                          'Cancel',
                          color: Color(0xFF888888),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _saving ? null : _saveMember,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF080808),
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: ApexText(
                          _saving ? 'Saving' : 'Save Member',
                          fontSize: 12,
                          color: const Color(0xFF080808),
                          fontWeight: FontWeight.w700,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: const Color(0xFF080808),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
    );
  }

  String? Function(String?) _requiredValidator(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final gymId = ref.read(currentGymIdProvider)?.trim();
    final authUser = ref.read(currentAuthUserProvider);

    if (gymId == null || gymId.isEmpty) {
      _showError('No gym is selected for this user profile.');
      return;
    }

    if (profile == null ||
        profile.status != 'active' ||
        !RoleCapabilities.canCreateMember(profile.role)) {
      _showError('You do not have permission to create members.');
      return;
    }

    setState(() => _saving = true);

    try {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final fullName = _fullNameController.text.trim();
      final email = _optionalText(_emailController)?.toLowerCase();
      if (email != null) {
        final validEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
        if (!validEmail) {
          throw StateError('Enter a valid email address or leave email empty.');
        }

        final memberInvites = ref.read(memberInviteRepositoryProvider);
        final pendingInviteExists =
            await memberInvites.pendingInviteEmailExists(gymId, email);
        if (pendingInviteExists) {
          throw StateError('A pending member invite already exists for this email.');
        }

        final linkedMemberExists =
            await memberInvites.linkedMemberEmailExists(gymId, email);
        if (linkedMemberExists) {
          throw StateError('A linked member account already uses this email.');
        }
      }

      final selectedPlan = _selectedPlan;
      final startDate = DateTime.now();
      final endDate = selectedPlan == null
          ? null
          : startDate.add(Duration(days: selectedPlan.durationDays));
      final amount = double.tryParse(_amountController.text.trim()) ??
          selectedPlan?.price ??
          0;

      final data = <String, dynamic>{
        'fullName': fullName,
        'name': fullName,
        'phone': _phoneController.text.trim(),
        'email': email,
        'emailNormalized': email,
        'gender': _optionalText(_genderController),
        'goal': _optionalText(_goalController) ?? 'general_fitness',
        'nfcTagId': _optionalText(_nfcTagIdController),
        'emergencyContactName': _optionalText(_emergencyNameController),
        'emergencyContactPhone': _optionalText(_emergencyPhoneController),
        'healthNotes': _optionalText(_healthNotesController),
        'status': 'active',
        'createdByStaffId': authUser?.uid,
        'createdBy': authUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'av': _initials(fullName),
        'last': 'New member',
        'plan': 'Unassigned',
        'sessions': 0,
        'streak': 0,
        'w': 70,
        'age': 25,
        'height': 170,
        'months': 0,
        'att': 0,
        'sessM': 0,
        'sessLM': 0,
        'bf': 0,
        'mm': 0,
        'injuries': <String>[],
        'ptime': 'morning',
        'neglect': <String>[],
        'lifts': <Map<String, dynamic>>[],
        'nut': const {'ct': 2000, 'ca': 0, 'pt': 150, 'pa': 0},
        'subLeft': 0,
        'lastDays': 0,
      };

      await ref.read(memberRepositoryProvider).createMemberWithRelatedRecords(
            gymId: gymId,
            memberData: data,
            inviteData: email == null
                ? null
                : {
                    'email': email,
                    'emailNormalized': email,
                    'fullName': fullName,
                    'phone': _phoneController.text.trim(),
                    'createdBy': authUser?.uid,
                    'expiresAt': Timestamp.fromDate(
                      DateTime.now().add(const Duration(days: 14)),
                    ),
                  },
            subscriptionData: selectedPlan == null
                ? null
                : {
                    'memberName': fullName,
                    'planId': selectedPlan.id,
                    'planName': selectedPlan.name,
                    'startDate': Timestamp.fromDate(startDate),
                    'endDate': Timestamp.fromDate(endDate!),
                    'status': SubscriptionStatus.active,
                    'paymentStatus': _paymentStatus,
                    'amount': amount,
                    'currency': selectedPlan.currency,
                    'paymentMethod': _paymentMethod,
                    'createdBy': authUser?.uid,
                    'notes': _optionalText(_subscriptionNotesController),
                  },
            memberSummaryData: selectedPlan == null
                ? null
                : {
                    'currentPlanId': selectedPlan.id,
                    'currentPlanName': selectedPlan.name,
                    'plan': selectedPlan.name,
                    'subscriptionStatus': SubscriptionStatus.active,
                    'subscriptionEndDate': Timestamp.fromDate(endDate!),
                  },
          );

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(selectedPlan == null
              ? 'Member created successfully.'
              : 'Member and subscription created successfully.'),
          backgroundColor: greenSuccess,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError('Could not create member: $error');
      setState(() => _saving = false);
    }
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String _initials(String fullName) {
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: redAlert,
      ),
    );
  }
}

class _FieldSlot extends StatelessWidget {
  const _FieldSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width < 700 ? double.infinity : 292,
      child: child,
    );
  }
}

class _MemberTextField extends StatelessWidget {
  const _MemberTextField({
    required this.controller,
    required this.label,
    this.requiredField = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final bool requiredField;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 13),
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        labelStyle: const TextStyle(color: Color(0xFF777777), fontSize: 12),
        errorStyle: const TextStyle(color: redAlert, fontSize: 11),
        filled: true,
        fillColor: card2Dark,
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
      ),
    );
  }
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF777777), fontSize: 12),
    filled: true,
    fillColor: card2Dark,
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
  );
}

class _MemberCard extends StatefulWidget {
  final Member member;
  const _MemberCard({required this.member});

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final risk = churnRisk(m);
    final rc = churnColor(risk);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/members/${m.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(isMobile ? 10 : 14),
          decoration: BoxDecoration(
            color: _hovered ? card2Dark : cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? gold.withValues(alpha: 0.2) : borderDark,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 36 : 44,
                height: isMobile ? 36 : 44,
                decoration: BoxDecoration(
                  color: avatarColor(m.av),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: ApexText(m.av, fontSize: isMobile ? 12 : 14,
                      color: const Color(0xFFE8E8E8), fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ApexText(m.name, fontSize: isMobile ? 12 : 13,
                              color: const Color(0xFFDDDDDD), fontWeight: FontWeight.w600),
                        ),
                        if (m.streak > 0)
                          ApexText('🔥 ${m.streak}', fontSize: isMobile ? 10 : 11),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ApexText(m.last, fontSize: isMobile ? 10 : 11,
                        color: const Color(0xFF555555)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isMobile) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ApexBadge(
                          text: m.plan,
                          color: m.plan == 'Elite' ? gold : m.plan == 'Premium' ? blueInfo : const Color(0xFF555555),
                        ),
                        const SizedBox(width: 6),
                        ApexBadge(
                          text: m.status,
                          color: m.status == 'active' ? greenSuccess : redAlert,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(color: rc, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        ApexText('${risk[0].toUpperCase()}${risk.substring(1)} risk',
                            fontSize: 10, color: rc),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right_rounded,
                  color: const Color(0xFF333333), size: isMobile ? 16 : 18),
            ],
          ),
        ),
      ),
    );
  }
}

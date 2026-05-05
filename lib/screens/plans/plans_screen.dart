import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/core/firestore_error_messages.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/models/membership_plan.dart';
import 'package:gymsaas/navigation/role_capabilities.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';
import 'package:gymsaas/widgets/apex_badge.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/shimmer_placeholder.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(gymPlansProvider);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final canManage = profile != null &&
        profile.status == 'active' &&
        RoleCapabilities.canManagePlans(profile.role);

    return Scaffold(
      backgroundColor: bgDark,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final actions = canManage
                    ? [
                        TextButton.icon(
                          onPressed: () => _seedDefaults(context, ref),
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: gold,
                          ),
                          label: const ApexText(
                            'Create default plans',
                            color: gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => const _PlanDialog(),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const ApexText(
                            'Add Plan',
                            color: Color(0xFF080808),
                            fontWeight: FontWeight.w700,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: gold,
                          ),
                        ),
                      ]
                    : const <Widget>[];

                if (constraints.maxWidth < 560) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GoldHeading('Plans', fontSize: 18),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, runSpacing: 8, children: actions),
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: GoldHeading('Plans', fontSize: 18),
                    ),
                    if (actions.isNotEmpty)
                      Wrap(spacing: 8, runSpacing: 8, children: actions),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: plansAsync.when(
                loading: () => ListView.separated(
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, __) => const ShimmerCard(),
                ),
                error: (error, _) => Center(
                  child: ApexText(
                    friendlyFirestoreErrorMessage(error),
                    color: redAlert,
                  ),
                ),
                data: (plans) {
                  if (plans.isEmpty) {
                    return const Center(
                      child: ApexText('No plans yet', color: Color(0xFF777777)),
                    );
                  }
                  return ListView.separated(
                    itemCount: plans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _PlanCard(plan: plans[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedDefaults(BuildContext context, WidgetRef ref) async {
    final gymId = ref.read(currentGymIdProvider)?.trim();
    if (gymId == null || gymId.isEmpty) return;
    try {
      await ref.read(planRepositoryProvider).seedDefaultPlansIfEmpty(gymId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default plans created.'),
          backgroundColor: greenSuccess,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create defaults: ${friendlyFirestoreErrorMessage(error)}',
          ),
          backgroundColor: redAlert,
        ),
      );
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final MembershipPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApexText(
                  plan.name,
                  color: const Color(0xFFE2E2E2),
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 4),
                ApexText(
                  plan.description ?? '${plan.durationDays} days',
                  color: const Color(0xFF777777),
                ),
              ],
            ),
          ),
          ApexText(
            '${plan.price.toStringAsFixed(0)} ${plan.currency}',
            color: gold,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(width: 10),
          ApexBadge(
            text: plan.isActive ? 'Active' : 'Inactive',
            color: plan.isActive ? greenSuccess : orangeWarning,
          ),
        ],
      ),
    );
  }
}

class _PlanDialog extends ConsumerStatefulWidget {
  const _PlanDialog();

  @override
  ConsumerState<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends ConsumerState<_PlanDialog> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _duration = TextEditingController(text: '30');
  final _description = TextEditingController();
  bool _isActive = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: cardDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GoldHeading('Add Plan', fontSize: 16),
            const SizedBox(height: 14),
            _PlanField(controller: _name, label: 'Name'),
            const SizedBox(height: 10),
            _PlanField(controller: _price, label: 'Price', numeric: true),
            const SizedBox(height: 10),
            _PlanField(
              controller: _duration,
              label: 'Duration days',
              numeric: true,
            ),
            const SizedBox(height: 10),
            _PlanField(controller: _description, label: 'Description'),
            SwitchListTile(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeThumbColor: gold,
              title: const ApexText('Active', color: Color(0xFFCCCCCC)),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const ApexText('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(backgroundColor: gold),
                  child: const Text('SAVE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final gymId = ref.read(currentGymIdProvider)?.trim();
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());
    final duration = int.tryParse(_duration.text.trim());
    if (gymId == null || gymId.isEmpty || name.isEmpty || price == null || duration == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(planRepositoryProvider).createPlan(gymId, {
        'name': name,
        'description': _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        'price': price,
        'currency': 'EGP',
        'durationDays': duration,
        'features': <String>[],
        'isActive': _isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save plan: ${friendlyFirestoreErrorMessage(error)}',
          ),
          backgroundColor: redAlert,
        ),
      );
      setState(() => _saving = false);
    }
  }
}

class _PlanField extends StatelessWidget {
  const _PlanField({
    required this.controller,
    required this.label,
    this.numeric = false,
  });

  final TextEditingController controller;
  final String label;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF777777), fontSize: 12),
        filled: true,
        fillColor: card2Dark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDark),
        ),
      ),
    );
  }
}

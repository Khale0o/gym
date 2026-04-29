import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/models/staff.dart';
import 'package:gymsaas/models/staff_invite.dart';
import 'package:gymsaas/navigation/role_capabilities.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';
import 'package:gymsaas/widgets/apex_badge.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/shimmer_placeholder.dart';

class StaffManagementScreen extends ConsumerWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(gymStaffProvider);
    final invitesAsync = ref.watch(gymStaffInvitesProvider);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final canManageStaff = profile != null &&
        profile.status.trim().toLowerCase() == 'active' &&
        RoleCapabilities.canManageStaff(profile.role);
    final isMobile = MediaQuery.of(context).size.width < 760;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgDark,
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const GoldHeading('Staff Management', fontSize: 18),
                  const Spacer(),
                  if (canManageStaff)
                    _InviteStaffButton(
                      compact: isMobile,
                      onPressed: () => _showInviteDialog(context),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderDark),
                ),
                child: const TabBar(
                  indicatorColor: gold,
                  labelColor: gold,
                  unselectedLabelColor: Color(0xFF666666),
                  tabs: [
                    Tab(text: 'Linked Staff'),
                    Tab(text: 'Pending Invites'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    _LinkedStaffSection(staffAsync: staffAsync),
                    _PendingInvitesSection(
                      invitesAsync: invitesAsync,
                      currentRole: profile?.role ?? '',
                      canManageStaff: canManageStaff,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _InviteStaffDialog(),
    );
  }
}

class _InviteStaffButton extends StatelessWidget {
  const _InviteStaffButton({
    required this.compact,
    required this.onPressed,
  });

  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
      label: ApexText(
        compact ? 'Invite' : 'Invite Staff',
        fontSize: 12,
        color: const Color(0xFF080808),
        fontWeight: FontWeight.w700,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: const Color(0xFF080808),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _LinkedStaffSection extends StatelessWidget {
  const _LinkedStaffSection({required this.staffAsync});

  final AsyncValue<List<Staff>> staffAsync;

  @override
  Widget build(BuildContext context) {
    return staffAsync.when(
      loading: () => const _LoadingList(),
      error: (error, _) => Center(
        child: ApexText('Error: $error', color: redAlert),
      ),
      data: (staff) {
        if (staff.isEmpty) {
          return const _EmptyState(
            title: 'No linked staff yet',
            subtitle: 'Staff accounts appear here after invites are claimed.',
          );
        }

        return ListView.separated(
          itemCount: staff.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) => _StaffCard(staff: staff[index]),
        );
      },
    );
  }
}

class _PendingInvitesSection extends ConsumerWidget {
  const _PendingInvitesSection({
    required this.invitesAsync,
    required this.currentRole,
    required this.canManageStaff,
  });

  final AsyncValue<List<StaffInvite>> invitesAsync;
  final String currentRole;
  final bool canManageStaff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return invitesAsync.when(
      loading: () => const _LoadingList(),
      error: (error, _) => Center(
        child: ApexText('Error: $error', color: redAlert),
      ),
      data: (invites) {
        final pending = invites
            .where((invite) => invite.status == StaffInviteStatus.pending)
            .toList();

        if (pending.isEmpty) {
          return const _EmptyState(
            title: 'No pending invites',
            subtitle: 'Invite your first team member',
          );
        }

        return ListView.separated(
          itemCount: pending.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final invite = pending[index];
            final canCancel = canManageStaff &&
                RoleCapabilities.canCancelStaffInvite(
                  currentRole,
                  invite.role,
                );
            return _InviteCard(
              invite: invite,
              canCancel: canCancel,
              onCancel: () => _cancelInvite(context, ref, invite),
            );
          },
        );
      },
    );
  }

  Future<void> _cancelInvite(
    BuildContext context,
    WidgetRef ref,
    StaffInvite invite,
  ) async {
    final gymId = ref.read(currentGymIdProvider)?.trim();
    final profile = ref.read(currentUserProfileProvider).valueOrNull;

    if (gymId == null || gymId.isEmpty) {
      _showSnack(context, 'No gym is selected for this user profile.', redAlert);
      return;
    }

    if (invite.status != StaffInviteStatus.pending) {
      _showSnack(context, 'Only pending invites can be cancelled.', redAlert);
      return;
    }

    if (profile == null ||
        profile.status.trim().toLowerCase() != 'active' ||
        !RoleCapabilities.canCancelStaffInvite(profile.role, invite.role)) {
      _showSnack(context, 'You cannot cancel this invite.', redAlert);
      return;
    }

    try {
      await ref
          .read(staffInviteRepositoryProvider)
          .cancelStaffInvite(gymId, invite.id);
      if (!context.mounted) return;
      _showSnack(context, 'Invite cancelled.', greenSuccess);
    } catch (error) {
      if (!context.mounted) return;
      _showSnack(context, 'Could not cancel invite: $error', redAlert);
    }
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.staff});

  final Staff staff;

  @override
  Widget build(BuildContext context) {
    final hasLogin = (staff.authUid ?? '').trim().isNotEmpty;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ApexText(
                  staff.fullName,
                  color: const Color(0xFFE2E2E2),
                  fontWeight: FontWeight.w700,
                ),
              ),
              ApexBadge(
                text: hasLogin ? 'Login Enabled' : 'Login Not Linked',
                color: hasLogin ? greenSuccess : orangeWarning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetaWrap(
            children: [
              _MetaItem('Email', staff.email ?? '-'),
              _MetaItem('Phone', staff.phone ?? '-'),
              _MetaItem('Role', _roleLabel(staff.role)),
              _MetaItem('Status', staff.status),
              _MetaItem('Created', _formatDate(staff.createdAt)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.canCancel,
    required this.onCancel,
  });

  final StaffInvite invite;
  final bool canCancel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ApexText(
                  invite.fullName,
                  color: const Color(0xFFE2E2E2),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const ApexBadge(text: 'Pending Signup', color: gold),
              if (canCancel) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Cancel invite',
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  color: redAlert,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _MetaWrap(
            children: [
              _MetaItem('Email', invite.email),
              _MetaItem('Phone', invite.phone ?? '-'),
              _MetaItem('Role', _roleLabel(invite.role)),
              _MetaItem('Status', invite.status),
              _MetaItem('Created', _formatDate(invite.createdAt)),
              _MetaItem('Expires', _formatDate(invite.expiresAt)),
              _MetaItem('Created By', invite.createdBy ?? '-'),
            ],
          ),
          if ((invite.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            ApexText(
              invite.notes!,
              color: const Color(0xFF777777),
              fontSize: 12,
            ),
          ],
        ],
      ),
    );
  }
}

class _InviteStaffDialog extends ConsumerStatefulWidget {
  const _InviteStaffDialog();

  @override
  ConsumerState<_InviteStaffDialog> createState() => _InviteStaffDialogState();
}

class _InviteStaffDialogState extends ConsumerState<_InviteStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedRole;
  bool _saving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final allowedRoles = RoleCapabilities.invitableStaffRoles(
      profile?.role ?? '',
    );
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (_selectedRole != null && !allowedRoles.contains(_selectedRole)) {
      _selectedRole = null;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
                        child: GoldHeading('Invite Staff', fontSize: 18),
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
                  _StaffTextField(
                    controller: _fullNameController,
                    label: 'Full name',
                    validator: _requiredValidator('Full name is required.'),
                  ),
                  const SizedBox(height: 12),
                  _StaffTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 12),
                  _StaffTextField(
                    controller: _phoneController,
                    label: 'Phone',
                    keyboardType: TextInputType.phone,
                    validator: _requiredValidator('Phone is required.'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    dropdownColor: card2Dark,
                    iconEnabledColor: gold,
                    style: const TextStyle(
                      color: Color(0xFFDDDDDD),
                      fontSize: 13,
                    ),
                    decoration: _inputDecoration('Role'),
                    items: allowedRoles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(_roleLabel(role)),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _selectedRole = value),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Role is required.';
                      }
                      if (!allowedRoles.contains(value)) {
                        return 'You cannot invite this role.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _StaffTextField(
                    controller: _notesController,
                    label: 'Notes',
                    maxLines: 3,
                    requiredField: false,
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
                        onPressed: _saving ? null : _createInvite,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF080808),
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 17),
                        label: ApexText(
                          _saving ? 'Creating' : 'Create Invite',
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

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required.';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) return 'Enter a valid email address.';
    return null;
  }

  Future<void> _createInvite() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final authUser = ref.read(currentAuthUserProvider);
    final gymId = ref.read(currentGymIdProvider)?.trim();
    final selectedRole = _selectedRole;

    if (gymId == null || gymId.isEmpty) {
      _showSnack(context, 'No gym is selected for this user profile.', redAlert);
      return;
    }

    if (profile == null ||
        profile.status.trim().toLowerCase() != 'active' ||
        !RoleCapabilities.canManageStaff(profile.role)) {
      _showSnack(context, 'You do not have permission to invite staff.', redAlert);
      return;
    }

    if (selectedRole == null ||
        !RoleCapabilities.canInviteStaffRole(profile.role, selectedRole)) {
      _showSnack(context, 'You cannot invite this role.', redAlert);
      return;
    }

    setState(() => _saving = true);

    try {
      final repository = ref.read(staffInviteRepositoryProvider);
      final email = _emailController.text.trim().toLowerCase();
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final staffExists = await repository.staffEmailExists(gymId, email);
      if (staffExists) {
        throw StateError('A linked staff profile already uses this email.');
      }

      final inviteExists = await repository.pendingInviteEmailExists(
        gymId,
        email,
      );
      if (inviteExists) {
        throw StateError('A pending invite already exists for this email.');
      }

      await repository.createStaffInvite(gymId, {
        'fullName': _fullNameController.text.trim(),
        'email': email,
        'phone': _phoneController.text.trim(),
        'role': selectedRole,
        'notes': _optionalText(_notesController),
        'status': StaffInviteStatus.pending,
        'createdBy': authUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 14)),
        ),
      });

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Staff invite created.'),
          backgroundColor: greenSuccess,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Could not create invite: $error', redAlert);
      setState(() => _saving = false);
    }
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }
}

class _StaffTextField extends StatelessWidget {
  const _StaffTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.requiredField = true,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 13),
      decoration: _inputDecoration(requiredField ? '$label *' : label),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.highlight = false,
  });

  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF11100C) : cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? goldDark : borderDark),
      ),
      child: child,
    );
  }
}

class _MetaWrap extends StatelessWidget {
  const _MetaWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: children,
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: card2Dark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ApexText(label, fontSize: 10, color: const Color(0xFF555555)),
          const SizedBox(height: 3),
          ApexText(
            value,
            fontSize: 12,
            color: const Color(0xFFCCCCCC),
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

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
            const Icon(Icons.manage_accounts_rounded, color: gold, size: 30),
            const SizedBox(height: 14),
            ApexText(
              title,
              fontSize: 16,
              color: const Color(0xFFE8E8E8),
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ApexText(
              subtitle,
              color: const Color(0xFF777777),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const ShimmerCard(),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
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
  );
}

void _showSnack(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
    ),
  );
}

String _roleLabel(String role) {
  final normalized = role.trim().toLowerCase();
  if (normalized.isEmpty) return '-';
  return normalized
      .split('_')
      .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gymsaas/core/firestore_error_messages.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/l10n/app_localizations.dart';
import 'package:gymsaas/models/gym_tenant.dart';
import 'package:gymsaas/navigation/role_access.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/platform_admin_provider.dart';
import 'package:gymsaas/widgets/apex_badge.dart';
import 'package:gymsaas/widgets/apex_card.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/shimmer_placeholder.dart';

class PlatformAdminScreen extends ConsumerWidget {
  const PlatformAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    if (!isPlatformOwnerRole(profile?.role)) {
      return const Scaffold(
        backgroundColor: bgDark,
        body: Center(
          child: ApexText(
            'You do not have permission to access Platform Admin.',
            color: redAlert,
          ),
        ),
      );
    }

    final gymsAsync = ref.watch(platformGymsProvider);
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoldHeading(context.t(L10nKeys.platformAdmin), fontSize: 20),
              const SizedBox(height: 6),
              ApexText(
                context.t(L10nKeys.platformAdminSubtitle),
                color: ApexColors.textMuted,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: gymsAsync.when(
                  loading: () => ListView.separated(
                    itemBuilder: (_, __) => const ShimmerCard(),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: 4,
                  ),
                  error: (error, _) => ApexCard(
                    child: ApexText(
                      friendlyFirestoreErrorMessage(
                        error,
                        fallback: 'Could not load gyms.',
                      ),
                      color: redAlert,
                    ),
                  ),
                  data: (gyms) {
                    if (gyms.isEmpty) {
                      return ApexCard(
                        child: ApexText(
                          context.t(L10nKeys.noGymsFound),
                          color: ApexColors.textMuted,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemBuilder: (context, index) =>
                          _GymTenantCard(gym: gyms[index]),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: gyms.length,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GymTenantCard extends ConsumerStatefulWidget {
  const _GymTenantCard({required this.gym});

  final PlatformGym gym;

  @override
  ConsumerState<_GymTenantCard> createState() => _GymTenantCardState();
}

class _GymTenantCardState extends ConsumerState<_GymTenantCard> {
  bool _saving = false;

  Future<void> _suspend() async {
    if (_saving) return;
    setState(() => _saving = true);
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _TenantReasonDialog(
        title: context.t(L10nKeys.suspendGym),
        label: context.t(L10nKeys.suspensionReason),
        actionLabel: context.t(L10nKeys.suspended),
        action: (reason) {
          final user = ref.read(currentAuthUserProvider);
          if (user == null) {
            throw StateError('A signed-in platform owner is required.');
          }
          return ref.read(platformAdminRepositoryProvider).suspendGym(
                gymId: widget.gym.id,
                reason: reason,
                updatedBy: user.uid,
              );
        },
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (completed == true) _showSuccess(context.t(L10nKeys.gymSuspendedSuccess));
  }

  Future<void> _resume() async {
    if (_saving) return;
    setState(() => _saving = true);
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _TenantConfirmDialog(
        title: context.t(L10nKeys.resumeGym),
        message:
            '${context.t(L10nKeys.actionAffectsGymAccess)} ${widget.gym.name}',
        actionLabel: context.t(L10nKeys.active),
        action: () {
          final user = ref.read(currentAuthUserProvider);
          if (user == null) {
            throw StateError('A signed-in platform owner is required.');
          }
          return ref.read(platformAdminRepositoryProvider).resumeGym(
                gymId: widget.gym.id,
                updatedBy: user.uid,
              );
        },
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (completed == true) _showSuccess(context.t(L10nKeys.gymResumedSuccess));
  }

  Future<void> _cancel() async {
    if (_saving) return;
    setState(() => _saving = true);
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _TenantReasonDialog(
        title: context.t(L10nKeys.markCancelled),
        label: context.t(L10nKeys.cancellationReason),
        actionLabel: context.t(L10nKeys.cancelled),
        action: (reason) {
          final user = ref.read(currentAuthUserProvider);
          if (user == null) {
            throw StateError('A signed-in platform owner is required.');
          }
          return ref.read(platformAdminRepositoryProvider).cancelGym(
                gymId: widget.gym.id,
                reason: reason,
                updatedBy: user.uid,
              );
        },
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (completed == true) _showSuccess(context.t(L10nKeys.gymCancelledSuccess));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: greenSuccess),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gym = widget.gym;
    return ApexCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 760;
          final details = Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _InfoChip(label: context.t(L10nKeys.slug), value: gym.slug),
              _InfoChip(label: context.t(L10nKeys.status), value: gym.status),
              _InfoChip(label: context.t(L10nKeys.country), value: gym.country),
              _InfoChip(
                label: context.t(L10nKeys.currency),
                value: gym.currency,
              ),
              _InfoChip(label: context.t(L10nKeys.phone), value: gym.phone),
              _InfoChip(label: context.t(L10nKeys.email), value: gym.email),
              _InfoChip(
                label: context.t(L10nKeys.createdAt),
                value: _formatDate(gym.createdAt),
              ),
              _InfoChip(
                label: context.t(L10nKeys.updatedAt),
                value: _formatDate(gym.updatedAt),
              ),
            ],
          );
          final actions = _TenantActions(
            gym: gym,
            saving: _saving,
            onSuspend: _suspend,
            onResume: _resume,
            onCancel: _cancel,
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GymHeader(gym: gym),
                const SizedBox(height: 12),
                details,
                const SizedBox(height: 14),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GymHeader(gym: gym),
                    const SizedBox(height: 12),
                    details,
                  ],
                ),
              ),
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _GymHeader extends StatelessWidget {
  const _GymHeader({required this.gym});

  final PlatformGym gym;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApexText(
                gym.name,
                color: ApexColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              const SizedBox(height: 4),
              ApexText(
                gym.id,
                color: ApexColors.textMuted,
                fontSize: 11,
              ),
            ],
          ),
        ),
        ApexBadge(
          text: _localizedTenantStatus(context, gym.tenantStatus),
          color: _statusColor(gym.tenantStatus),
        ),
      ],
    );
  }
}

class _TenantActions extends StatelessWidget {
  const _TenantActions({
    required this.gym,
    required this.saving,
    required this.onSuspend,
    required this.onResume,
    required this.onCancel,
  });

  final PlatformGym gym;
  final bool saving;
  final VoidCallback onSuspend;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: saving || gym.isSuspended || gym.isCancelled
              ? null
              : onSuspend,
          icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
          label: Text(context.t(L10nKeys.suspendGym)),
        ),
        FilledButton.icon(
          onPressed: saving || gym.isActive ? null : onResume,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_circle_outline_rounded, size: 18),
          label: Text(
            saving ? context.t(L10nKeys.saving) : context.t(L10nKeys.resumeGym),
          ),
        ),
        OutlinedButton.icon(
          onPressed: saving || gym.isCancelled ? null : onCancel,
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: Text(context.t(L10nKeys.cancel)),
          style: OutlinedButton.styleFrom(foregroundColor: redAlert),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? 'Not set' : value.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ApexColors.surfaceAlt,
        borderRadius: BorderRadius.circular(ApexRadius.sm),
        border: Border.all(color: ApexColors.border),
      ),
      child: RichText(
        text: TextSpan(
          style: ApexTextStyles.caption,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: ApexColors.textMuted),
            ),
            TextSpan(
              text: display,
              style: const TextStyle(
                color: ApexColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantReasonDialog extends StatefulWidget {
  const _TenantReasonDialog({
    required this.title,
    required this.label,
    required this.actionLabel,
    required this.action,
  });

  final String title;
  final String label;
  final String actionLabel;
  final Future<void> Function(String reason) action;

  @override
  State<_TenantReasonDialog> createState() => _TenantReasonDialogState();
}

class _TenantReasonDialogState extends State<_TenantReasonDialog> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = context.t(L10nKeys.reasonRequired));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.action(reason);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseException catch (error, stackTrace) {
      _debugLogTenantActionError(error, stackTrace);
      if (!mounted) return;
      setState(() => _error = _tenantActionErrorMessage(error));
    } on StateError catch (error, stackTrace) {
      _debugLogTenantActionError(error, stackTrace);
      if (!mounted) return;
      setState(() => _error = 'Could not update gym. Please try again.');
    } catch (error, stackTrace) {
      _debugLogTenantActionError(error, stackTrace);
      if (!mounted) return;
      setState(() => _error = 'Could not update gym. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_saving,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(context.t(L10nKeys.close)),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(_saving ? context.t(L10nKeys.saving) : widget.actionLabel),
        ),
      ],
    );
  }
}

class _TenantConfirmDialog extends StatefulWidget {
  const _TenantConfirmDialog({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.action,
  });

  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() action;

  @override
  State<_TenantConfirmDialog> createState() => _TenantConfirmDialogState();
}

class _TenantConfirmDialogState extends State<_TenantConfirmDialog> {
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.action();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseException catch (error, stackTrace) {
      _debugLogTenantActionError(error, stackTrace);
      if (!mounted) return;
      setState(() => _error = _tenantActionErrorMessage(error));
    } on StateError catch (error, stackTrace) {
      _debugLogTenantActionError(error, stackTrace);
      if (!mounted) return;
      setState(() => _error = 'Could not update gym. Please try again.');
    } catch (error, stackTrace) {
      _debugLogTenantActionError(error, stackTrace);
      if (!mounted) return;
      setState(() => _error = 'Could not update gym. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ApexText(_error!, color: redAlert),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(context.t(L10nKeys.close)),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(_saving ? context.t(L10nKeys.saving) : widget.actionLabel),
        ),
      ],
    );
  }
}

String _tenantActionErrorMessage(FirebaseException error) {
  switch (error.code) {
    case 'permission-denied':
      return 'You do not have permission to update this gym.';
    case 'unavailable':
    case 'deadline-exceeded':
      return 'Could not update gym right now. Please try again.';
    default:
      return 'Firestore error: ${error.code}';
  }
}

void _debugLogTenantActionError(Object error, StackTrace stackTrace) {
  if (kDebugMode) {
    debugPrint('Platform tenant action failed: $error');
    debugPrint('$stackTrace');
  }
}

Color _statusColor(String status) {
  switch (status) {
    case GymTenantStatus.suspended:
      return orangeWarning;
    case GymTenantStatus.cancelled:
      return redAlert;
    default:
      return greenSuccess;
  }
}

String _localizedTenantStatus(BuildContext context, String status) {
  switch (status) {
    case GymTenantStatus.suspended:
      return context.t(L10nKeys.suspended);
    case GymTenantStatus.cancelled:
      return context.t(L10nKeys.cancelled);
    default:
      return context.t(L10nKeys.active);
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return '';
  return DateFormat('yyyy-MM-dd HH:mm').format(value);
}

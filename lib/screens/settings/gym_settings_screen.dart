import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/core/firestore_error_messages.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/l10n/app_localizations.dart';
import 'package:gymsaas/models/gym_settings.dart';
import 'package:gymsaas/navigation/role_capabilities.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';
import 'package:gymsaas/providers/language_provider.dart';
import 'package:gymsaas/repositories/gym_settings_repository.dart';
import 'package:gymsaas/widgets/apex_card.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/shimmer_placeholder.dart';

class GymSettingsScreen extends ConsumerWidget {
  const GymSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final canManage = profile != null &&
        profile.status == 'active' &&
        RoleCapabilities.canManageSettings(profile.role);

    if (!canManage) {
      return const Scaffold(
        backgroundColor: bgDark,
        body: Center(
          child: ApexText(
            'You do not have permission to manage gym settings.',
            color: redAlert,
          ),
        ),
      );
    }

    final gymProfile = ref.watch(gymProfileProvider);
    final occupancy = ref.watch(occupancySettingsProvider);
    final appSettings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoldHeading(context.t(L10nKeys.settings), fontSize: 20),
              const SizedBox(height: 6),
              ApexText(
                context.t(L10nKeys.settingsSubtitle),
                color: Color(0xFF777777),
              ),
              const SizedBox(height: 20),
              const _LanguageSettingsCard(),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 900;
                  final profileCard = gymProfile.when(
                    loading: () => const ShimmerCard(),
                    error: (error, _) => _SettingsError(
                      message:
                          'Gym profile unavailable: ${friendlyFirestoreErrorMessage(error)}',
                    ),
                    data: (settings) => _GymProfileCard(settings: settings),
                  );
                  final occupancyCard = occupancy.when(
                    loading: () => const ShimmerCard(),
                    error: (error, _) => _SettingsError(
                      message:
                          'Occupancy settings unavailable: ${friendlyFirestoreErrorMessage(error)}',
                    ),
                    data: (settings) =>
                        _OccupancySettingsCard(settings: settings),
                  );
                  final appCard = appSettings.when(
                    loading: () => const ShimmerCard(),
                    error: (error, _) => _SettingsError(
                      message:
                          'Business settings unavailable: ${friendlyFirestoreErrorMessage(error)}',
                    ),
                    data: (settings) => _AppSettingsCard(settings: settings),
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        profileCard,
                        const SizedBox(height: 16),
                        occupancyCard,
                        const SizedBox(height: 16),
                        appCard,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            profileCard,
                            const SizedBox(height: 16),
                            occupancyCard,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: appCard),
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
}

class _LanguageSettingsCard extends ConsumerWidget {
  const _LanguageSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);

    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldHeading(context.t(L10nKeys.language), fontSize: 16),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChoiceChip(
                label: Text(context.t(L10nKeys.english)),
                selected: language == AppLanguage.english,
                onSelected: (_) => _changeLanguage(
                  context,
                  ref,
                  AppLanguage.english,
                ),
              ),
              ChoiceChip(
                label: Text(context.t(L10nKeys.arabicEgyptian)),
                selected: language == AppLanguage.arabicEgyptian,
                onSelected: (_) => _changeLanguage(
                  context,
                  ref,
                  AppLanguage.arabicEgyptian,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _changeLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLanguage language,
  ) async {
    await ref.read(appLanguageProvider.notifier).setLanguage(language);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.t(L10nKeys.languageChanged)),
        backgroundColor: greenSuccess,
      ),
    );
  }
}

class _GymProfileCard extends ConsumerStatefulWidget {
  const _GymProfileCard({required this.settings});

  final GymProfileSettings settings;

  @override
  ConsumerState<_GymProfileCard> createState() => _GymProfileCardState();
}

class _GymProfileCardState extends ConsumerState<_GymProfileCard> {
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _country = TextEditingController();
  final _currency = TextEditingController();
  final _timezone = TextEditingController();
  final _status = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _logoUrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sync(widget.settings);
  }

  @override
  void didUpdateWidget(covariant _GymProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings && !_saving) {
      _sync(widget.settings);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _country.dispose();
    _currency.dispose();
    _timezone.dispose();
    _status.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _logoUrl.dispose();
    super.dispose();
  }

  void _sync(GymProfileSettings settings) {
    _name.text = settings.name;
    _slug.text = settings.slug;
    _country.text = settings.country;
    _currency.text = settings.currency;
    _timezone.text = settings.timezone;
    _status.text = settings.status;
    _phone.text = settings.phone;
    _email.text = settings.email;
    _address.text = settings.address;
    _logoUrl.text = settings.logoUrl;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final currency = _currency.text.trim().toUpperCase();
    final gymId = ref.read(currentGymIdProvider)?.trim();
    final user = ref.read(currentAuthUserProvider);
    if (gymId == null || gymId.isEmpty || user == null) {
      _showError(context, 'Current gym and signed-in user are required.');
      return;
    }
    if (name.isEmpty) {
      _showError(context, 'Gym name is required.');
      return;
    }
    if (currency.isEmpty) {
      _showError(context, 'Currency is required.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(gymSettingsRepositoryProvider).updateGymProfile(
        gymId: gymId,
        updatedBy: user.uid,
        data: {
          'name': name,
          'slug': _slug.text.trim(),
          'country': _country.text.trim(),
          'currency': currency,
          'timezone': _timezone.text.trim(),
          'status': _status.text.trim().isEmpty ? 'active' : _status.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'address': _address.text.trim(),
          'logoUrl': _logoUrl.text.trim(),
        },
      );
      if (!mounted) return;
      _showSuccess(context, 'Gym profile saved.');
    } catch (error) {
      if (!mounted) return;
      _showError(
        context,
        'Could not save gym profile: ${friendlyFirestoreErrorMessage(error)}',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldHeading(context.t(L10nKeys.gymProfile), fontSize: 16),
          const SizedBox(height: 14),
          _SettingsField(controller: _name, label: context.t(L10nKeys.name)),
          _SettingsField(controller: _slug, label: context.t(L10nKeys.slug)),
          _SettingsWrap(
            children: [
              _SettingsField(controller: _country, label: context.t(L10nKeys.country)),
              _SettingsField(controller: _currency, label: context.t(L10nKeys.currency)),
              _SettingsField(controller: _timezone, label: context.t(L10nKeys.timezone)),
              _SettingsField(controller: _status, label: context.t(L10nKeys.status)),
            ],
          ),
          _SettingsWrap(
            children: [
              _SettingsField(controller: _phone, label: context.t(L10nKeys.phone)),
              _SettingsField(controller: _email, label: context.t(L10nKeys.email)),
            ],
          ),
          _SettingsField(controller: _address, label: context.t(L10nKeys.address), maxLines: 2),
          _SettingsField(controller: _logoUrl, label: 'Logo URL optional'),
          _SaveButton(
            saving: _saving,
            label: context.t(L10nKeys.saveProfile),
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _OccupancySettingsCard extends ConsumerStatefulWidget {
  const _OccupancySettingsCard({required this.settings});

  final OccupancySettings settings;

  @override
  ConsumerState<_OccupancySettingsCard> createState() =>
      _OccupancySettingsCardState();
}

class _OccupancySettingsCardState
    extends ConsumerState<_OccupancySettingsCard> {
  final _capacity = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _capacity.text = '${widget.settings.capacity}';
  }

  @override
  void didUpdateWidget(covariant _OccupancySettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings && !_saving) {
      _capacity.text = '${widget.settings.capacity}';
    }
  }

  @override
  void dispose() {
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final capacity = int.tryParse(_capacity.text.trim());
    final gymId = ref.read(currentGymIdProvider)?.trim();
    final user = ref.read(currentAuthUserProvider);
    if (gymId == null || gymId.isEmpty || user == null) {
      _showError(context, 'Current gym and signed-in user are required.');
      return;
    }
    if (capacity == null || capacity < 0) {
      _showError(context, 'Capacity must be a non-negative integer.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(gymSettingsRepositoryProvider).updateOccupancySettings(
            gymId: gymId,
            updatedBy: user.uid,
            capacity: capacity,
          );
      if (!mounted) return;
      _showSuccess(context, 'Occupancy settings saved.');
    } catch (error) {
      if (!mounted) return;
      _showError(
        context,
        'Could not save occupancy settings: ${friendlyFirestoreErrorMessage(error)}',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldHeading(context.t(L10nKeys.occupancySettings), fontSize: 16),
          const SizedBox(height: 14),
          _ReadOnlyRow(label: 'Current count', value: '${widget.settings.count}'),
          _SettingsField(
            controller: _capacity,
            label: context.t(L10nKeys.capacity),
            keyboardType: TextInputType.number,
          ),
          const ApexText(
            'Changing capacity does not reset current occupancy.',
            color: Color(0xFF777777),
            fontSize: 12,
          ),
          _SaveButton(
            saving: _saving,
            label: context.t(L10nKeys.saveOccupancy),
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _AppSettingsCard extends ConsumerStatefulWidget {
  const _AppSettingsCard({required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<_AppSettingsCard> createState() => _AppSettingsCardState();
}

class _AppSettingsCardState extends ConsumerState<_AppSettingsCard> {
  final _expiringSoonDays = TextEditingController();
  final _receiptPrefix = TextEditingController();
  bool _allowPartialPayments = true;
  bool _checkInRequiresPaidOrPartial = true;
  Set<String> _enabledMethods = AppSettings.defaultPaymentMethods.toSet();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sync(widget.settings);
  }

  @override
  void didUpdateWidget(covariant _AppSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings && !_saving) {
      _sync(widget.settings);
    }
  }

  @override
  void dispose() {
    _expiringSoonDays.dispose();
    _receiptPrefix.dispose();
    super.dispose();
  }

  void _sync(AppSettings settings) {
    _allowPartialPayments = settings.allowPartialPayments;
    _checkInRequiresPaidOrPartial = settings.checkInRequiresPaidOrPartial;
    _expiringSoonDays.text = '${settings.expiringSoonDays}';
    _receiptPrefix.text = settings.defaultReceiptPrefix;
    _enabledMethods = settings.enabledPaymentMethods.toSet();
  }

  Future<void> _save() async {
    final days = int.tryParse(_expiringSoonDays.text.trim());
    final prefix = _receiptPrefix.text.trim();
    final gymId = ref.read(currentGymIdProvider)?.trim();
    final user = ref.read(currentAuthUserProvider);
    if (gymId == null || gymId.isEmpty || user == null) {
      _showError(context, 'Current gym and signed-in user are required.');
      return;
    }
    if (days == null || days < 0) {
      _showError(context, 'Expiring soon days must be zero or greater.');
      return;
    }
    if (prefix.isEmpty) {
      _showError(context, 'Receipt prefix is required.');
      return;
    }
    if (_enabledMethods.isEmpty) {
      _showError(context, 'Enable at least one payment method.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(gymSettingsRepositoryProvider).updateAppSettings(
            gymId: gymId,
            updatedBy: user.uid,
            input: AppSettingsUpdate(
              allowPartialPayments: _allowPartialPayments,
              expiringSoonDays: days,
              checkInRequiresPaidOrPartial: _checkInRequiresPaidOrPartial,
              defaultReceiptPrefix: prefix,
              enabledPaymentMethods: _enabledMethods.toList()..sort(),
            ),
          );
      if (!mounted) return;
      _showSuccess(context, 'Business settings saved.');
    } catch (error) {
      if (!mounted) return;
      _showError(
        context,
        'Could not save business settings: ${friendlyFirestoreErrorMessage(error)}',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldHeading(context.t(L10nKeys.businessSettings), fontSize: 16),
          const SizedBox(height: 14),
          _SwitchRow(
            title: 'Allow partial payments',
            value: _allowPartialPayments,
            onChanged: (value) => setState(() => _allowPartialPayments = value),
          ),
          _SwitchRow(
            title: 'Check-in requires paid or partial',
            value: _checkInRequiresPaidOrPartial,
            onChanged: (value) =>
                setState(() => _checkInRequiresPaidOrPartial = value),
          ),
          _SettingsWrap(
            children: [
              _SettingsField(
                controller: _expiringSoonDays,
                label: 'Expiring soon days',
                keyboardType: TextInputType.number,
              ),
              _SettingsField(
                controller: _receiptPrefix,
                label: 'Default receipt prefix',
              ),
            ],
          ),
          const SizedBox(height: 8),
          GoldHeading(context.t(L10nKeys.paymentMethods), fontSize: 13),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppSettings.defaultPaymentMethods.map((method) {
              final selected = _enabledMethods.contains(method);
              return FilterChip(
                label: Text(_methodLabel(method)),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _enabledMethods.add(method);
                    } else {
                      _enabledMethods.remove(method);
                    }
                  });
                },
                selectedColor: gold.withValues(alpha: 0.18),
                checkmarkColor: gold,
                backgroundColor: const Color(0xFF0A0A0A),
                labelStyle: TextStyle(
                  color: selected ? gold : const Color(0xFFBBBBBB),
                  fontSize: 12,
                ),
                side: const BorderSide(color: borderDark),
              );
            }).toList(),
          ),
          _SaveButton(
            saving: _saving,
            label: context.t(L10nKeys.saveBusinessSettings),
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _SettingsWrap extends StatelessWidget {
  const _SettingsWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children
          .map(
            (child) => SizedBox(
              width: MediaQuery.of(context).size.width < 700 ? double.infinity : 240,
              child: child,
            ),
          )
          .toList(),
    );
  }
}

class _SettingsField extends StatelessWidget {
  const _SettingsField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Color(0xFFE8E8E8), fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF777777), fontSize: 12),
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
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: gold,
      contentPadding: EdgeInsets.zero,
      title: ApexText(
        title,
        color: const Color(0xFFE2E2E2),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: ApexText(label, color: const Color(0xFF777777), fontSize: 12),
          ),
          ApexText(
            value,
            color: const Color(0xFFE8E8E8),
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.saving,
    required this.label,
    required this.onPressed,
  });

  final bool saving;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: saving ? null : onPressed,
        icon: saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_rounded, size: 18),
        label: Text(saving ? context.t(L10nKeys.saving) : label),
        style: FilledButton.styleFrom(backgroundColor: gold),
      ),
    );
  }
}

class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: ApexText(message, color: redAlert),
    );
  }
}

String _methodLabel(String method) {
  switch (method) {
    case 'cash':
      return 'Cash';
    case 'instapay':
      return 'Instapay';
    case 'vodafone_cash':
      return 'Vodafone Cash';
    case 'card':
      return 'Card';
    case 'online':
      return 'Online';
    default:
      return method;
  }
}

void _showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: greenSuccess),
  );
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: redAlert),
  );
}

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/core/firestore_error_messages.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/core/helpers.dart';
import 'package:gymsaas/l10n/app_localizations.dart';
import 'package:gymsaas/models/attendance_session.dart';
import 'package:gymsaas/models/checkin.dart';
import 'package:gymsaas/models/member_access_eligibility.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/occupancy_provider.dart';
import 'package:gymsaas/providers/checkins_provider.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';
import 'package:gymsaas/repositories/member_repository.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/apex_card.dart';
import 'package:gymsaas/widgets/apex_badge.dart';
import 'package:gymsaas/widgets/apex_progress_bar.dart';
import 'package:gymsaas/widgets/occupancy_ring.dart';
import 'package:gymsaas/widgets/shimmer_placeholder.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen>
    with SingleTickerProviderStateMixin {
  final _accessCodeController = TextEditingController();
  bool _scanning = false;
  bool _checkingIn = false;
  String? _checkingOutMemberId;
  bool _success = false;
  String? _scannedName;
  String? _scannedPlan;
  String? _scannedMethod;
  DateTime? _scannedAt;

  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _scanAnim = Tween<double>(begin: 0, end: 1).animate(_scanCtrl);
  }

  @override
  void dispose() {
    _accessCodeController.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: redAlert,
      ),
    );
  }

  Future<void> _changeOccupancy(double nextCount) async {
    final gymId = ref.read(currentGymIdProvider)?.trim();
    if (gymId == null || gymId.isEmpty) {
      _showError('Missing gym context.');
      return;
    }

    try {
      await ref
          .read(checkInRepositoryProvider)
          .setOccupancy(gymId, nextCount.clamp(0.0, gymCapacity.toDouble()));
    } catch (error) {
      _showError(friendlyFirestoreErrorMessage(error));
    }
  }

  Future<void> _simulateScan() async {
    if (_scanning || _checkingIn) return;

    setState(() {
      _scanning = true;
      _success = false;
      _scannedName = null;
      _scannedPlan = null;
      _scannedMethod = null;
      _scannedAt = null;
    });

    await Future.delayed(const Duration(milliseconds: 1800));

    final gymId = ref.read(currentGymIdProvider)?.trim();
    if (gymId == null || gymId.isEmpty) {
      if (!mounted) return;
      setState(() => _scanning = false);
      _showError('Missing gym context.');
      return;
    }

    final members = ref.read(gymMembersProvider).asData?.value ?? [];

    if (members.isNotEmpty && mounted) {
      final m = members[Random().nextInt(members.length)];

      try {
        final admission = await ref
            .read(checkInRepositoryProvider)
            .checkInMemberWithSession(
          gymId: gymId,
          memberId: m.id,
          method: 'NFC',
          createdBy: ref.read(currentAuthUserProvider)?.uid,
        );
        if (!mounted) return;
        setState(() {
          _success = true;
          _scannedName = admission.memberName;
          _scannedPlan = admission.planName;
          _scannedMethod = 'NFC';
          _scannedAt = DateTime.now();
        });
      } on StateError catch (error) {
        _showError(_stateErrorMessage(error));
        return;
      } on FirebaseException catch (error) {
        _showError(_friendlyFirestoreError(error));
        return;
      } catch (error, stackTrace) {
        _debugCheckInError(error, stackTrace);
        _showError('Check-in failed. Please try again.');
        return;
      } finally {
        if (mounted) {
          setState(() => _scanning = false);
        }
      }

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _success = false);
      });
    } else {
      setState(() => _scanning = false);
    }
  }

  Future<void> _checkInByAccessCode() async {
    if (_checkingIn || _scanning) return;

    final code = _accessCodeController.text.trim();
    if (code.isEmpty) {
      _showError('Enter or scan an access code.');
      return;
    }

    final gymId = ref.read(currentGymIdProvider)?.trim();
    if (gymId == null || gymId.isEmpty) {
      _showError('Missing gym context.');
      return;
    }

    setState(() {
      _checkingIn = true;
      _success = false;
      _scannedName = null;
      _scannedPlan = null;
      _scannedMethod = null;
      _scannedAt = null;
    });

    try {
      final member = await ref.read(memberRepositoryProvider).findMemberByAccessCode(
            gymId: gymId,
            code: code,
          );
      if (member == null) {
        throw StateError('Access code not found');
      }

      final accessMessage = blockedAccessStatusMessage(member.accessStatus);
      if (accessMessage != null) {
        throw StateError(accessMessage);
      }

      final accessMethod = _accessMethodFor(member, code);
      final admission =
          await ref.read(checkInRepositoryProvider).checkInMemberWithSession(
            gymId: gymId,
            memberId: member.id,
            method: accessMethod,
            createdBy: ref.read(currentAuthUserProvider)?.uid,
          );
      if (!mounted) return;
      setState(() {
        _success = true;
        _scannedName = admission.memberName;
        _scannedPlan = admission.planName;
        _scannedMethod = accessMethod;
        _scannedAt = DateTime.now();
      });
      _accessCodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check-in successful: ${admission.memberName}'),
          backgroundColor: greenSuccess,
        ),
      );

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _success = false);
      });
    } on StateError catch (error) {
      _showError(_stateErrorMessage(error));
    } on FirebaseException catch (error) {
      _showError(_friendlyFirestoreError(error));
    } catch (error, stackTrace) {
      _debugCheckInError(error, stackTrace);
      _showError('Check-in failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _checkingIn = false);
      }
    }
  }

  String _accessMethodFor(Member member, String code) {
    final normalized = MemberRepository.normalizeAccessIdentifier(code);
    if (normalized != null &&
        MemberRepository.normalizeAccessIdentifier(member.nfcTagId) ==
            normalized) {
      return 'NFC';
    }
    if (normalized != null &&
        MemberRepository.normalizeAccessIdentifier(member.qrCode) ==
            normalized) {
      return 'QR';
    }
    return 'Access Code';
  }

  Future<void> _checkOutMember(AttendanceSession session) async {
    if (_checkingOutMemberId != null) return;

    final gymId = ref.read(currentGymIdProvider)?.trim();
    if (gymId == null || gymId.isEmpty) {
      _showError('Missing gym context.');
      return;
    }

    setState(() => _checkingOutMemberId = session.memberId);
    try {
      await ref.read(checkInRepositoryProvider).checkOutMember(
            gymId: gymId,
            memberId: session.memberId,
            method: 'manual',
            checkedOutBy: ref.read(currentAuthUserProvider)?.uid,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checked out ${session.memberName}.'),
          backgroundColor: greenSuccess,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(friendlyFirestoreErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _checkingOutMemberId = null);
      }
    }
  }

  String _stateErrorMessage(StateError error) {
    final message = error.toString();
    const badStatePrefix = 'Bad state: ';
    const stateErrorPrefix = 'StateError: ';
    if (message.startsWith(badStatePrefix)) {
      return message.substring(badStatePrefix.length);
    }
    if (message.startsWith(stateErrorPrefix)) {
      final clean = message.substring(stateErrorPrefix.length);
      return clean == 'You cannot check in because this member account is archived.'
          ? context.t(L10nKeys.archivedCheckinBlocked)
          : clean;
    }
    return message == 'You cannot check in because this member account is archived.'
        ? context.t(L10nKeys.archivedCheckinBlocked)
        : message;
  }

  String _friendlyFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to check members in or out. Your account may be inactive or not linked to this gym.';
      case 'unavailable':
        return 'Firestore is unavailable right now. Please try again.';
      case 'deadline-exceeded':
        return 'Check-in took too long. Please try again.';
      default:
        return 'Check-in failed. Please try again.';
    }
  }

  void _debugCheckInError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('Check-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final occupancyAsync = ref.watch(occupancyStreamProvider);
    final checkinsAsync = ref.watch(recentCheckinsProvider);
    final activeSessionsAsync = ref.watch(activeAttendanceSessionsProvider);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CheckInHeader(occupancyAsync: occupancyAsync),
            const SizedBox(height: 20),

            /// ✅ RESPONSIVE WRAPPER
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 900;

                if (isMobile) {
                  /// 📱 MOBILE
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNFC(),
                      const SizedBox(height: 16),
                      _buildOccupancy(occupancyAsync),
                    ],
                  );
                }

                /// 🖥 DESKTOP (ORIGINAL UI 100%)
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _buildNFC()),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildOccupancy(occupancyAsync),
                          const SizedBox(height: 16),
                          _ActiveSessionsSummary(async: activeSessionsAsync),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            _ActiveSessionsCard(
              async: activeSessionsAsync,
              checkingOutMemberId: _checkingOutMemberId,
              onCheckOut: _checkOutMember,
            ),

            const SizedBox(height: 20),

            _RecentAccessLog(async: checkinsAsync),
          ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔴 NFC — FULL ORIGINAL WITH SUCCESS MESSAGE
  Widget _buildNFC() {
    return ApexCard(
      glow: _scanning || _checkingIn,
      child: Column(
        children: [
          const GoldHeading('Access Check-in', fontSize: 18),
          const SizedBox(height: 6),
          ApexText(
            context.t(L10nKeys.scanAccessCode),
            color: ApexColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _simulateScan,
            child: AnimatedBuilder(
              animation: _scanAnim,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _scanning
                            ? gold.withValues(
                                alpha: 0.3 + 0.4 * _scanAnim.value)
                            : borderDark,
                        width: 2,
                      ),
                      color: _success
                          ? greenSuccess.withValues(alpha: 0.08)
                          : _scanning
                              ? gold.withValues(alpha: 0.05)
                              : cardDark,
                    ),
                  ),
                  if (_scanning)
                    Positioned(
                      top: 80 * _scanAnim.value,
                      child: Container(
                        width: 120,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              gold.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  Icon(
                    _success
                        ? Icons.check_circle_rounded
                        : Icons.nfc_rounded,
                    size: 56,
                    color: _success
                        ? greenSuccess
                        : _scanning
                            ? gold
                            : const Color(0xFF333333),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _accessCodeController,
            enabled: !_checkingIn && !_scanning,
            style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 13),
            decoration: InputDecoration(
              hintText: context.t(L10nKeys.scanAccessCode),
              labelStyle: const TextStyle(
                color: Color(0xFF777777),
                fontSize: 12,
              ),
              prefixIcon: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFF555555),
                size: 18,
              ),
              filled: true,
              fillColor: ApexColors.surface,
              border: ApexDecorations.inputBorder(),
              enabledBorder: ApexDecorations.inputBorder(),
              focusedBorder: ApexDecorations.inputBorder(gold),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
            onSubmitted: (_) => _checkInByAccessCode(),
          ),
          const SizedBox(height: 8),
          const ApexText(
            'Hardware scanners that type into this field will work automatically.',
            fontSize: 11,
            color: ApexColors.textMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _checkingIn || _scanning ? null : _checkInByAccessCode,
              icon: _checkingIn
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF080808),
                      ),
                    )
                  : const Icon(Icons.login_rounded, size: 18),
              label: ApexText(
                _checkingIn
                    ? context.t(L10nKeys.loading)
                    : context.t(L10nKeys.checkIn),
                fontSize: 12,
                color: const Color(0xFF080808),
                fontWeight: FontWeight.w700,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: const Color(0xFF080808),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // رسالة النجاح الأصلية
          if (_success && _scannedName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: greenSuccess.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: greenSuccess.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const ApexText('✓ Access Granted',
                      fontSize: 13,
                      color: greenSuccess,
                      fontWeight: FontWeight.w600),
                  const SizedBox(height: 4),
                  ApexText(_scannedName!,
                      fontSize: 15,
                      color: const Color(0xFFE8E8E8),
                      fontWeight: FontWeight.w700),
                  const SizedBox(height: 4),
                  ApexBadge(text: _scannedPlan ?? '', color: gold),
                  if (_scannedAt != null || _scannedMethod != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        if (_scannedAt != null)
                          ApexBadge(
                            text: _timeLabel(_scannedAt!),
                            color: greenSuccess,
                          ),
                        if (_scannedMethod != null)
                          ApexBadge(
                            text: _scannedMethod!,
                            color: _methodColor(_scannedMethod!),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ] else
            ApexText(
              _checkingIn || _scanning
                  ? 'Validating access...'
                  : 'Ready for front-desk check-in.',
              fontSize: 12,
              color: _checkingIn || _scanning ? gold : const Color(0xFF555555),
            ),
        ],
      ),
    );
  }

  /// 🔴 OCCUPANCY — FULL WITH +/- BUTTONS & SLIDER
  Widget _buildOccupancy(AsyncValue<double> occupancyAsync) {
    return occupancyAsync.when(
      loading: () => const ShimmerCard(),
      error: (error, _) => ApexText(
        friendlyFirestoreErrorMessage(error),
        color: orangeWarning,
      ),
      data: (occupancyCount) {
        final pct = (occupancyCount / gymCapacity * 100).clamp(0.0, 100.0);
        final status = _occupancyStatus(occupancyCount);
        return ApexCard(
          child: Column(
            children: [
              GoldHeading(context.t(L10nKeys.liveOccupancy), fontSize: 16),
              const SizedBox(height: 16),
              OccupancyRing(
                current: occupancyCount,
                capacity: gymCapacity,
                compact: true,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ApexBadge(
                    text:
                        '${occupancyCount.round()} ${context.t(L10nKeys.currentCount)}',
                    color: ocColor(pct),
                  ),
                  ApexBadge(
                    text: '$gymCapacity ${context.t(L10nKeys.capacity)}',
                    color: blueInfo,
                  ),
                  ApexBadge(
                    text: _occupancyStatusLabel(context, status),
                    color: status.color,
                  ),
                  ApexBadge(text: '${pct.round()}%', color: ocColor(pct)),
                ],
              ),
              const SizedBox(height: 16),
              // أزرار التحكم
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _OccBtn(
                    icon: Icons.remove_rounded,
                    onTap: () => _changeOccupancy(
                      (occupancyCount - 1).clamp(0.0, gymCapacity.toDouble()),
                    ),
                  ),
                  const SizedBox(width: 24),
                  _OccBtn(
                    icon: Icons.add_rounded,
                    onTap: () => _changeOccupancy(
                      (occupancyCount + 1).clamp(0.0, gymCapacity.toDouble()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: occupancyCount.clamp(0.0, gymCapacity.toDouble()),
                min: 0,
                max: gymCapacity.toDouble(),
                divisions: gymCapacity,
                activeColor: ocColor(pct),
                inactiveColor: borderDark,
                onChanged: (v) => _changeOccupancy(v),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔴 STATS — FULL ORIGINAL WITH METHOD BARS & SECURITY ALERTS
  Widget buildStats() {
    return Column(
      children: [
        ApexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GoldHeading('Method Breakdown'),
              const SizedBox(height: 16),
              _MethodBar(method: 'NFC', count: 38, total: 58, color: blueInfo),
              const SizedBox(height: 10),
              _MethodBar(method: 'QR Code', count: 14, total: 58, color: greenSuccess),
              const SizedBox(height: 10),
              _MethodBar(method: 'Manual', count: 6, total: 58, color: orangeWarning),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ApexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GoldHeading('Security Alerts'),
              const SizedBox(height: 14),
              _AlertRow(icon: Icons.block_rounded, label: 'Duplicates Blocked', count: 3, color: orangeWarning),
              _AlertRow(icon: Icons.wifi_off_rounded, label: 'Invalid NFC Tags', count: 1, color: redAlert),
              _AlertRow(icon: Icons.schedule_rounded, label: 'Expired Subs', count: 2, color: redAlert),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── الأدوات الصغيرة (بالكامل) ────────────────────────
class _CheckInHeader extends StatelessWidget {
  const _CheckInHeader({required this.occupancyAsync});

  final AsyncValue<double> occupancyAsync;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return ApexCard(
      glow: true,
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 18,
        runSpacing: 14,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: isMobile ? double.infinity : 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoldHeading(context.t(L10nKeys.checkInTitle), fontSize: 22),
                const SizedBox(height: 6),
                ApexText(
                  context.t(L10nKeys.checkInSubtitle),
                  color: ApexColors.textSecondary,
                ),
              ],
            ),
          ),
          occupancyAsync.maybeWhen(
            data: (occupancyCount) {
              final status = _occupancyStatus(occupancyCount);
              final pct =
                  (occupancyCount / gymCapacity * 100).clamp(0.0, 100.0);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ApexBadge(
                    text:
                        '${occupancyCount.round()} / $gymCapacity ${context.t(L10nKeys.currentlyInside)}',
                    color: ocColor(pct),
                  ),
                  ApexBadge(
                    text: _occupancyStatusLabel(context, status),
                    color: status.color,
                  ),
                ],
              );
            },
            orElse: () => ApexBadge(
              text: context.t(L10nKeys.loading),
              color: gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionsSummary extends StatelessWidget {
  const _ActiveSessionsSummary({required this.async});

  final AsyncValue<List<AttendanceSession>> async;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: async.when(
        loading: () => const ShimmerCard(),
        error: (error, _) => ApexText(
          friendlyFirestoreErrorMessage(error),
          color: orangeWarning,
        ),
        data: (sessions) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              GoldHeading(context.t(L10nKeys.activeSessions), fontSize: 14),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ApexBadge(
                  text: '${sessions.length} ${context.t(L10nKeys.active)}',
                  color: sessions.isEmpty ? ApexColors.textMuted : greenSuccess,
                ),
                ApexBadge(
                  text: sessions.isEmpty
                      ? context.t(L10nKeys.noActiveSessions)
                      : context.t(L10nKeys.liveOccupancy),
                  color: sessions.isEmpty ? blueInfo : gold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentAccessLog extends StatelessWidget {
  const _RecentAccessLog({required this.async});

  final AsyncValue<List<CheckIn>> async;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldHeading(context.t(L10nKeys.recentCheckins), fontSize: 16),
          const SizedBox(height: 6),
          const ApexText(
            'Legacy access log, kept as a lower-priority operational reference.',
            fontSize: 12,
            color: ApexColors.textSecondary,
          ),
          const SizedBox(height: 14),
          async.when(
            loading: () => Column(
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: ShimmerCard(),
                ),
              ),
            ),
            error: (error, _) => ApexText(
              friendlyFirestoreErrorMessage(error),
              color: orangeWarning,
            ),
            data: (list) {
              if (list.isEmpty) {
                return ApexText(
                  context.t(L10nKeys.noRecentCheckins),
                  color: ApexColors.textMuted,
                );
              }
              return Column(
                children: list.take(8).toList().asMap().entries.map((entry) {
                  final i = entry.key;
                  final ci = entry.value;
                  final method = ci.method;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: i == 0
                          ? greenSuccess.withValues(alpha: 0.06)
                          : ApexColors.surface,
                      borderRadius: ApexRadius.card,
                      border: Border.all(
                        color: i == 0
                            ? greenSuccess.withValues(alpha: 0.22)
                            : ApexColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(_methodIcon(method),
                            color: _methodColor(method), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ApexText(
                            ci.name,
                            color: ApexColors.textPrimary,
                            fontWeight:
                                i == 0 ? FontWeight.w700 : FontWeight.w500,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ApexBadge(text: method, color: _methodColor(method)),
                        const SizedBox(width: 10),
                        ApexText(
                          timeAgo(ci.time),
                          fontSize: 10,
                          color: ApexColors.textMuted,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OccBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _OccBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderDark),
        ),
        child: Icon(icon, color: gold, size: 20),
      ),
    );
  }
}

class _ActiveSessionsCard extends StatelessWidget {
  const _ActiveSessionsCard({
    required this.async,
    required this.checkingOutMemberId,
    required this.onCheckOut,
  });

  final AsyncValue<List<AttendanceSession>> async;
  final String? checkingOutMemberId;
  final ValueChanged<AttendanceSession> onCheckOut;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldHeading(context.t(L10nKeys.activeSessions), fontSize: 18),
          const SizedBox(height: 6),
          const ApexText(
            'Members currently inside the gym.',
            fontSize: 12,
            color: ApexColors.textSecondary,
          ),
          const SizedBox(height: 16),
          async.when(
            loading: () => Column(
              children: List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: ShimmerCard(),
                ),
              ),
            ),
            error: (error, _) => ApexText(
              'Could not load active sessions: ${friendlyFirestoreErrorMessage(error)}',
              color: orangeWarning,
              fontSize: 12,
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return _EmptyOperationalState(
                  icon: Icons.event_available_rounded,
                  text: context.t(L10nKeys.noActiveSessions),
                );
              }

              return Column(
                children: sessions
                    .map(
                      (session) => _ActiveSessionRow(
                        session: session,
                        checkingOut:
                            checkingOutMemberId == session.memberId,
                        onCheckOut: () => onCheckOut(session),
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

class _EmptyOperationalState extends StatelessWidget {
  const _EmptyOperationalState({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ApexColors.surface,
        borderRadius: ApexRadius.card,
        border: Border.all(color: ApexColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: ApexColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: ApexText(text, color: ApexColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionRow extends StatelessWidget {
  const _ActiveSessionRow({
    required this.session,
    required this.checkingOut,
    required this.onCheckOut,
  });

  final AttendanceSession session;
  final bool checkingOut;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final duration = DateTime.now().difference(session.checkInAt);
    final durationLabel = _durationLabel(duration);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ApexColors.surface,
        borderRadius: ApexRadius.card,
        border: Border.all(color: ApexColors.border),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ActiveSessionInfo(
                  session: session,
                  durationLabel: durationLabel,
                ),
                const SizedBox(height: 10),
                _ActiveSessionBadges(session: session),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: _CheckOutButton(
                    checkingOut: checkingOut,
                    onPressed: onCheckOut,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _ActiveSessionInfo(
                    session: session,
                    durationLabel: durationLabel,
                  ),
                ),
                _ActiveSessionBadges(session: session),
                const SizedBox(width: 12),
                _CheckOutButton(
                  checkingOut: checkingOut,
                  onPressed: onCheckOut,
                ),
              ],
            ),
    );
  }

  static String _durationLabel(Duration duration) {
    final minutes = duration.inMinutes.clamp(0, 1 << 30);
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return '${hours}h ${rest}m';
  }
}

class _ActiveSessionInfo extends StatelessWidget {
  const _ActiveSessionInfo({
    required this.session,
    required this.durationLabel,
  });

  final AttendanceSession session;
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person_pin_circle_rounded, color: gold, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApexText(
                session.memberName,
                color: const Color(0xFFDDDDDD),
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 3),
              ApexText(
                'In ${_timeLabel(session.checkInAt)} • $durationLabel',
                fontSize: 11,
                color: const Color(0xFF777777),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _timeLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ActiveSessionBadges extends StatelessWidget {
  const _ActiveSessionBadges({required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context) {
    final phone = (session.memberPhone ?? '').trim();
    final plan = (session.planName ?? '').trim();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ApexBadge(text: context.t(L10nKeys.active), color: greenSuccess),
        ApexBadge(
          text: session.checkInMethod,
          color: _methodColor(session.checkInMethod),
        ),
        if (phone.isNotEmpty) ApexBadge(text: phone, color: blueInfo),
        if (plan.isNotEmpty) ApexBadge(text: plan, color: ApexColors.secondary),
      ],
    );
  }
}

class _CheckOutButton extends StatelessWidget {
  const _CheckOutButton({
    required this.checkingOut,
    required this.onPressed,
  });

  final bool checkingOut;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: checkingOut ? null : onPressed,
      icon: checkingOut
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF080808),
              ),
            )
          : const Icon(Icons.logout_rounded, size: 16),
      label: Text(
        checkingOut ? context.t(L10nKeys.loading) : context.t(L10nKeys.checkOut),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: const Color(0xFF080808),
      ),
    );
  }
}

class _MethodBar extends StatelessWidget {
  final String method;
  final int count;
  final int total;
  final Color color;
  const _MethodBar({
    required this.method,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ApexText(method, fontSize: 12, color: const Color(0xFF888888)),
            const Spacer(),
            ApexText('$count', fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ],
        ),
        const SizedBox(height: 5),
        ApexProgressBar(
          value: count.toDouble(),
          max: total.toDouble(),
          color: color,
          height: 4,
        ),
      ],
    );
  }
}

class _AlertRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _AlertRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: ApexText(label, fontSize: 12, color: const Color(0xFF888888)),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: ApexText('$count', fontSize: 10, color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupancyStatus {
  const _OccupancyStatus(this.label, this.color);

  final String label;
  final Color color;
}

_OccupancyStatus _occupancyStatus(double count) {
  if (count <= 0) return const _OccupancyStatus('Empty', ApexColors.textMuted);
  final pct = count / gymCapacity * 100;
  if (pct < 35) return const _OccupancyStatus('Low', greenSuccess);
  if (pct < 70) return const _OccupancyStatus('Moderate', gold);
  if (pct < 100) return const _OccupancyStatus('Busy', orangeWarning);
  return const _OccupancyStatus('Full', redAlert);
}

String _occupancyStatusLabel(BuildContext context, _OccupancyStatus status) {
  switch (status.label) {
    case 'Empty':
      return context.t(L10nKeys.empty);
    case 'Low':
      return context.t(L10nKeys.low);
    case 'Moderate':
      return context.t(L10nKeys.moderate);
    case 'Busy':
      return context.t(L10nKeys.busy);
    case 'Full':
      return context.t(L10nKeys.full);
    default:
      return status.label;
  }
}

Color _methodColor(String method) {
  switch (method.trim().toLowerCase()) {
    case 'nfc':
      return blueInfo;
    case 'qr':
    case 'qr code':
      return greenSuccess;
    case 'access code':
      return gold;
    case 'manual':
      return orangeWarning;
    default:
      return ApexColors.secondary;
  }
}

IconData _methodIcon(String method) {
  switch (method.trim().toLowerCase()) {
    case 'nfc':
      return Icons.nfc_rounded;
    case 'qr':
    case 'qr code':
      return Icons.qr_code_rounded;
    case 'access code':
      return Icons.password_rounded;
    default:
      return Icons.edit_rounded;
  }
}

String _timeLabel(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

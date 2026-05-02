import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/core/helpers.dart';
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
  bool _success = false;
  String? _scannedName;
  String? _scannedPlan;

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
      _showError(error.toString().replaceFirst('StateError: ', ''));
    }
  }

  Future<void> _simulateScan() async {
    if (_scanning || _checkingIn) return;

    setState(() {
      _scanning = true;
      _success = false;
      _scannedName = null;
      _scannedPlan = null;
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
        final admission = await ref.read(checkInRepositoryProvider).checkInMember(
          gymId: gymId,
          memberId: m.id,
          method: 'NFC',
        );
        if (!mounted) return;
        setState(() {
          _scanning = false;
          _success = true;
          _scannedName = admission.memberName;
          _scannedPlan = admission.planName;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() => _scanning = false);
        _showError(error.toString().replaceFirst('StateError: ', ''));
        return;
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

      final admission = await ref.read(checkInRepositoryProvider).checkInMember(
            gymId: gymId,
            memberId: member.id,
            method: _accessMethodFor(member, code),
          );
      if (!mounted) return;
      setState(() {
        _checkingIn = false;
        _success = true;
        _scannedName = admission.memberName;
        _scannedPlan = admission.planName;
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
    } catch (error) {
      if (!mounted) return;
      setState(() => _checkingIn = false);
      _showError(error.toString().replaceFirst('StateError: ', ''));
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

  @override
  Widget build(BuildContext context) {
    final occupancyAsync = ref.watch(occupancyStreamProvider);
    final checkinsAsync = ref.watch(recentCheckinsProvider);

    return Scaffold(
      backgroundColor: bgDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GoldHeading('Check-in Station', fontSize: 18),
            const SizedBox(height: 24),

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
                      const SizedBox(height: 16),
                      _buildStats(),
                    ],
                  );
                }

                /// 🖥 DESKTOP (ORIGINAL UI 100%)
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildNFC()),
                    const SizedBox(width: 16),
                    Expanded(
                        flex: 2,
                        child: _buildOccupancy(occupancyAsync)),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildStats()),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            /// ACCESS LOG (FULL ORIGINAL)
            ApexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GoldHeading('Live Access Log'),
                  const SizedBox(height: 16),
                  checkinsAsync.when(
                    loading: () => Column(
                      children: List.generate(
                        4,
                        (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: ShimmerCard(),
                        ),
                      ),
                    ),
                    error: (_, __) => const ApexText('Error'),
                    data: (list) => Column(
                      children: list.take(8).toList().asMap().entries.map((e) {
                        final i = e.key;
                        final ci = e.value;

                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300 + i * 50),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: i == 0
                                ? greenSuccess.withOpacity(0.05)
                                : const Color(0xFF0A0A0A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: i == 0
                                  ? greenSuccess.withOpacity(0.2)
                                  : borderDark,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                ci.method == 'NFC'
                                    ? Icons.nfc_rounded
                                    : ci.method == 'QR'
                                        ? Icons.qr_code_rounded
                                        : Icons.edit_rounded,
                                color: i == 0
                                    ? greenSuccess
                                    : const Color(0xFF444444),
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ApexText(
                                  ci.name,
                                  fontSize: 12,
                                  color: i == 0
                                      ? const Color(0xFFDDDDDD)
                                      : const Color(0xFF888888),
                                  fontWeight: i == 0
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              ApexBadge(
                                  text: ci.method,
                                  color: ci.method == 'NFC'
                                      ? blueInfo
                                      : ci.method == 'QR'
                                          ? greenSuccess
                                          : orangeWarning),
                              const SizedBox(width: 10),
                              ApexText(timeAgo(ci.time), fontSize: 10, color: const Color(0xFF444444)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          const GoldHeading('Access Check-in'),
          const SizedBox(height: 24),
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
                            ? gold.withOpacity(
                                0.3 + 0.4 * _scanAnim.value)
                            : borderDark,
                        width: 2,
                      ),
                      color: _success
                          ? greenSuccess.withOpacity(0.08)
                          : _scanning
                              ? gold.withOpacity(0.05)
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
                              gold.withOpacity(0.8),
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
              labelText: 'Scan NFC / QR / Access Code',
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
            ),
            onSubmitted: (_) => _checkInByAccessCode(),
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
                _checkingIn ? 'Checking' : 'Check In',
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
                color: greenSuccess.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: greenSuccess.withOpacity(0.2)),
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
                ],
              ),
            ),
          ] else
            ApexText(
              _checkingIn || _scanning
                  ? 'Validating access...'
                  : 'Tap scanner circle for demo/test random check-in',
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
      error: (_, __) => const ApexText('Error'),
      data: (count) {
        final pct =
            (count / gymCapacity * 100).clamp(0.0, 100.0);
        return ApexCard(
          child: Column(
            children: [
              const GoldHeading('Live Occupancy'),
              const SizedBox(height: 16),
              OccupancyRing(
                current: count,
                capacity: gymCapacity,
                compact: true,
              ),
              const SizedBox(height: 16),
              // أزرار التحكم
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _OccBtn(
                    icon: Icons.remove_rounded,
                    onTap: () => _changeOccupancy(
                      (count - 1).clamp(0.0, gymCapacity.toDouble()),
                    ),
                  ),
                  const SizedBox(width: 24),
                  _OccBtn(
                    icon: Icons.add_rounded,
                    onTap: () => _changeOccupancy(
                      (count + 1).clamp(0.0, gymCapacity.toDouble()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: count.clamp(0.0, gymCapacity.toDouble()),
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
  Widget _buildStats() {
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
              color: color.withOpacity(0.1),
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

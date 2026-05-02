import 'package:flutter/material.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/models/effective_subscription_status.dart';
import 'package:gymsaas/models/member.dart';

enum MemberAccessSeverity {
  info,
  warning,
  danger,
}

class MemberAccessEligibility {
  const MemberAccessEligibility({
    required this.allowed,
    required this.severity,
    required this.title,
    required this.message,
    required this.reasons,
    required this.subscriptionState,
  });

  final bool allowed;
  final MemberAccessSeverity severity;
  final String title;
  final String message;
  final List<String> reasons;
  final EffectiveSubscriptionState subscriptionState;

  Color get color {
    switch (severity) {
      case MemberAccessSeverity.info:
        return greenSuccess;
      case MemberAccessSeverity.warning:
        return orangeWarning;
      case MemberAccessSeverity.danger:
        return redAlert;
    }
  }
}

MemberAccessEligibility evaluateMemberAccessEligibility(Member member) {
  final subscriptionState = EffectiveSubscriptionState.fromMember(member);
  final reasons = <String>[];
  var hasWarning = false;

  final memberStatus = member.status.trim().toLowerCase();
  final accountStatus = member.accountStatus?.trim().toLowerCase() ?? '';
  final accessStatus = member.accessStatus?.trim().toLowerCase() ?? '';

  if (memberStatus != 'active') {
    reasons.add('Member profile is inactive.');
  }

  if (accountStatus.isNotEmpty && accountStatus != 'active') {
    reasons.add('Member account is inactive.');
  }

  final accessMessage = blockedAccessStatusMessage(accessStatus);
  if (accessMessage != null) {
    reasons.add(accessMessage);
  }

  switch (subscriptionState.status) {
    case EffectiveSubscriptionStatus.active:
      break;
    case EffectiveSubscriptionStatus.expiringSoon:
      reasons.add('Subscription is expiring soon.');
      hasWarning = true;
      break;
    case EffectiveSubscriptionStatus.partial:
      reasons.add('Subscription has a partial payment.');
      hasWarning = true;
      break;
    case EffectiveSubscriptionStatus.expired:
      reasons.add('Subscription expired.');
      break;
    case EffectiveSubscriptionStatus.unpaid:
      reasons.add('Subscription is unpaid.');
      break;
    case EffectiveSubscriptionStatus.none:
      reasons.add('No active subscription found.');
      break;
    case EffectiveSubscriptionStatus.cancelled:
      reasons.add('No active subscription found.');
      break;
  }

  final allowed = reasons.every((reason) =>
      reason == 'Subscription is expiring soon.' ||
      reason == 'Subscription has a partial payment.');

  if (!allowed) {
    return MemberAccessEligibility(
      allowed: false,
      severity: MemberAccessSeverity.danger,
      title: 'Access blocked',
      message: reasons.first,
      reasons: reasons,
      subscriptionState: subscriptionState,
    );
  }

  if (hasWarning) {
    return MemberAccessEligibility(
      allowed: true,
      severity: MemberAccessSeverity.warning,
      title: 'Access allowed with warning',
      message: reasons.first,
      reasons: reasons,
      subscriptionState: subscriptionState,
    );
  }

  return MemberAccessEligibility(
    allowed: true,
    severity: MemberAccessSeverity.info,
    title: 'Access allowed',
    message: 'Member can check in if subscription/payment rules remain valid.',
    reasons: const [],
    subscriptionState: subscriptionState,
  );
}

String? blockedAccessStatusMessage(String? accessStatus) {
  switch (accessStatus?.trim().toLowerCase()) {
    case 'disabled':
      return 'Access credential is disabled.';
    case 'lost':
      return 'Access credential was reported lost.';
    case 'replaced':
      return 'Access credential was replaced.';
    default:
      return null;
  }
}

String memberAccessStatusLabel(Member member) {
  final hasIdentifier =
      (member.nfcTagId ?? '').trim().isNotEmpty ||
      (member.qrCode ?? '').trim().isNotEmpty ||
      (member.accessCode ?? '').trim().isNotEmpty;
  if (!hasIdentifier) {
    return 'Not Assigned';
  }

  switch ((member.accessStatus ?? '').trim().toLowerCase()) {
    case '':
    case 'active':
      return 'Access Active';
    case 'disabled':
      return 'Disabled';
    case 'lost':
      return 'Lost';
    case 'replaced':
      return 'Replaced';
    default:
      return 'Access Active';
  }
}

Color memberAccessStatusColor(Member member) {
  switch (memberAccessStatusLabel(member)) {
    case 'Access Active':
      return greenSuccess;
    case 'Disabled':
    case 'Lost':
    case 'Replaced':
      return redAlert;
    default:
      return const Color(0xFF666666);
  }
}

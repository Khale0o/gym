import 'package:flutter/material.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/models/subscription.dart';

enum EffectiveSubscriptionStatus {
  active,
  expiringSoon,
  expired,
  unpaid,
  partial,
  none,
  cancelled,
}

class EffectiveSubscriptionState {
  const EffectiveSubscriptionState({
    required this.status,
    required this.label,
    required this.description,
    required this.color,
  });

  final EffectiveSubscriptionStatus status;
  final String label;
  final String description;
  final Color color;

  static EffectiveSubscriptionState fromMember(
    Member member, {
    int warningThresholdDays = 7,
  }) {
    return resolveEffectiveSubscriptionStatus(
      subscriptionStatus: member.subscriptionStatus,
      subscriptionEndDate: member.subscriptionEndDate,
      paymentStatus: member.paymentStatus,
      warningThresholdDays: warningThresholdDays,
    );
  }
}

EffectiveSubscriptionState resolveEffectiveSubscriptionStatus({
  required String? subscriptionStatus,
  required DateTime? subscriptionEndDate,
  required String? paymentStatus,
  int warningThresholdDays = 7,
}) {
  final normalizedSubscription = _normalize(subscriptionStatus);
  final normalizedPayment = _normalize(paymentStatus);

  if (normalizedSubscription.isEmpty && subscriptionEndDate == null) {
    return _state(EffectiveSubscriptionStatus.none);
  }

  if (normalizedSubscription == SubscriptionStatus.cancelled) {
    return _state(EffectiveSubscriptionStatus.cancelled);
  }

  if (normalizedPayment == SubscriptionPaymentStatus.unpaid) {
    return _state(EffectiveSubscriptionStatus.unpaid);
  }

  if (_isBeforeToday(subscriptionEndDate)) {
    return _state(EffectiveSubscriptionStatus.expired);
  }

  if (normalizedPayment == SubscriptionPaymentStatus.partial) {
    return _state(EffectiveSubscriptionStatus.partial);
  }

  if (_isWithinWarningWindow(subscriptionEndDate, warningThresholdDays)) {
    return _state(EffectiveSubscriptionStatus.expiringSoon);
  }

  return _state(EffectiveSubscriptionStatus.active);
}

String _normalize(String? value) => value?.trim().toLowerCase() ?? '';

bool _isBeforeToday(DateTime? date) {
  if (date == null) return false;
  final today = _today();
  final value = DateTime(date.year, date.month, date.day);
  return value.isBefore(today);
}

bool _isWithinWarningWindow(DateTime? date, int warningThresholdDays) {
  if (date == null) return false;
  final today = _today();
  final value = DateTime(date.year, date.month, date.day);
  final threshold = warningThresholdDays < 0 ? 0 : warningThresholdDays;
  final lastWarningDay = today.add(Duration(days: threshold));
  return !value.isBefore(today) && !value.isAfter(lastWarningDay);
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

EffectiveSubscriptionState _state(EffectiveSubscriptionStatus status) {
  switch (status) {
    case EffectiveSubscriptionStatus.active:
      return const EffectiveSubscriptionState(
        status: EffectiveSubscriptionStatus.active,
        label: 'Active',
        description: 'Subscription is active.',
        color: greenSuccess,
      );
    case EffectiveSubscriptionStatus.expiringSoon:
      return const EffectiveSubscriptionState(
        status: EffectiveSubscriptionStatus.expiringSoon,
        label: 'Expiring Soon',
        description: 'Subscription is valid but nearing its end date.',
        color: orangeWarning,
      );
    case EffectiveSubscriptionStatus.expired:
      return const EffectiveSubscriptionState(
        status: EffectiveSubscriptionStatus.expired,
        label: 'Expired',
        description: 'Subscription end date has passed.',
        color: redAlert,
      );
    case EffectiveSubscriptionStatus.unpaid:
      return const EffectiveSubscriptionState(
        status: EffectiveSubscriptionStatus.unpaid,
        label: 'Unpaid',
        description: 'Payment is unpaid.',
        color: redAlert,
      );
    case EffectiveSubscriptionStatus.partial:
      return const EffectiveSubscriptionState(
        status: EffectiveSubscriptionStatus.partial,
        label: 'Partial',
        description: 'Subscription has a partial payment.',
        color: blueInfo,
      );
    case EffectiveSubscriptionStatus.none:
      return const EffectiveSubscriptionState(
        status: EffectiveSubscriptionStatus.none,
        label: 'No Subscription',
        description: 'No current subscription summary is available.',
        color: Color(0xFF666666),
      );
    case EffectiveSubscriptionStatus.cancelled:
      return const EffectiveSubscriptionState(
        status: EffectiveSubscriptionStatus.cancelled,
        label: 'Cancelled',
        description: 'Subscription is cancelled.',
        color: redAlert,
      );
  }
}

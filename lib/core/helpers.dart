import 'package:flutter/material.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/models/member.dart';

/// Returns churn risk level for a member.
String churnRisk(Member m) {
  if (m.sessM < m.sessLM * 0.6 || m.att < 0.6) return 'high';
  if (m.sessM < m.sessLM * 0.8 || m.att < 0.75) return 'medium';
  return 'low';
}

/// Maps churn risk string to a display color.
Color churnColor(String risk) {
  switch (risk) {
    case 'high':
      return redAlert;
    case 'medium':
      return orangeWarning;
    default:
      return greenSuccess;
  }
}

/// Formats a number as Egyptian currency.
String formatCurrency(double amount) =>
    '${amount.toStringAsFixed(0)} EGP';

/// Returns a human-readable "time ago" string.
String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

/// Converts initials string to a consistent avatar color.
Color avatarColor(String initials) {
  final colors = [
    const Color(0xFF7A5C1E),
    const Color(0xFF1E4D7A),
    const Color(0xFF1E7A4D),
    const Color(0xFF7A1E4D),
    const Color(0xFF4D1E7A),
  ];
  int idx = 0;
  for (final c in initials.codeUnits) {
    idx += c;
  }
  return colors[idx % colors.length];
}

/// Returns a short day label.
String dayLabel(int weekday) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[(weekday - 1) % 7];
}

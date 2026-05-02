import 'package:cloud_firestore/cloud_firestore.dart';

class GymProfileSettings {
  const GymProfileSettings({
    required this.id,
    required this.name,
    required this.slug,
    required this.country,
    required this.currency,
    required this.timezone,
    required this.status,
    required this.phone,
    required this.email,
    required this.address,
    required this.logoUrl,
    required this.updatedAt,
    required this.updatedBy,
  });

  final String id;
  final String name;
  final String slug;
  final String country;
  final String currency;
  final String timezone;
  final String status;
  final String phone;
  final String email;
  final String address;
  final String logoUrl;
  final DateTime? updatedAt;
  final String? updatedBy;

  factory GymProfileSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return GymProfileSettings(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      slug: (data['slug'] as String?) ?? '',
      country: (data['country'] as String?) ?? '',
      currency: (data['currency'] as String?) ?? 'EGP',
      timezone: (data['timezone'] as String?) ?? 'Africa/Cairo',
      status: (data['status'] as String?) ?? 'active',
      phone: (data['phone'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      logoUrl: (data['logoUrl'] as String?) ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] as String?,
    );
  }
}

class OccupancySettings {
  const OccupancySettings({
    required this.capacity,
    required this.maxCapacity,
    required this.count,
    required this.updatedAt,
    required this.updatedBy,
  });

  final int capacity;
  final int maxCapacity;
  final int count;
  final DateTime? updatedAt;
  final String? updatedBy;

  factory OccupancySettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final capacity = _safeInt(data['capacity']);
    final maxCapacity = _safeInt(data['maxCapacity']);
    return OccupancySettings(
      capacity: capacity > 0 ? capacity : maxCapacity,
      maxCapacity: maxCapacity,
      count: _safeInt(data['count']),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] as String?,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.allowPartialPayments,
    required this.expiringSoonDays,
    required this.checkInRequiresPaidOrPartial,
    required this.defaultReceiptPrefix,
    required this.enabledPaymentMethods,
    required this.updatedAt,
    required this.updatedBy,
  });

  static const defaultPaymentMethods = <String>[
    'cash',
    'instapay',
    'vodafone_cash',
    'card',
    'online',
  ];

  final bool allowPartialPayments;
  final int expiringSoonDays;
  final bool checkInRequiresPaidOrPartial;
  final String defaultReceiptPrefix;
  final List<String> enabledPaymentMethods;
  final DateTime? updatedAt;
  final String? updatedBy;

  factory AppSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final methods = List<String>.from(
      data['enabledPaymentMethods'] ?? defaultPaymentMethods,
    );
    return AppSettings(
      allowPartialPayments: (data['allowPartialPayments'] as bool?) ?? true,
      expiringSoonDays: _safeInt(data['expiringSoonDays'], fallback: 7),
      checkInRequiresPaidOrPartial:
          (data['checkInRequiresPaidOrPartial'] as bool?) ?? true,
      defaultReceiptPrefix:
          (data['defaultReceiptPrefix'] as String?)?.trim().isNotEmpty == true
              ? (data['defaultReceiptPrefix'] as String).trim()
              : 'R',
      enabledPaymentMethods:
          methods.isEmpty ? defaultPaymentMethods : methods.toSet().toList(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] as String?,
    );
  }
}

int _safeInt(dynamic value, {int fallback = 0}) {
  if (value is num) {
    final intValue = value.toInt();
    return intValue < 0 ? 0 : intValue;
  }
  return fallback;
}

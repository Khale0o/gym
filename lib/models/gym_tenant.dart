import 'package:cloud_firestore/cloud_firestore.dart';

class GymTenantStatus {
  static const active = 'active';
  static const suspended = 'suspended';
  static const cancelled = 'cancelled';

  static const all = <String>{active, suspended, cancelled};

  static String normalize(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return all.contains(normalized) ? normalized : active;
  }
}

class GymTenantAccess {
  const GymTenantAccess({
    required this.gymId,
    required this.tenantStatus,
  });

  final String gymId;
  final String tenantStatus;

  bool get isUsable => tenantStatus == GymTenantStatus.active;

  String? get blockedMessage {
    switch (tenantStatus) {
      case GymTenantStatus.suspended:
        return 'Gym access is temporarily suspended. Please contact platform support.';
      case GymTenantStatus.cancelled:
        return 'Gym access is no longer active. Please contact platform support.';
      default:
        return null;
    }
  }

  factory GymTenantAccess.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return GymTenantAccess(
      gymId: doc.id,
      tenantStatus: GymTenantStatus.normalize(data['tenantStatus'] as String?),
    );
  }
}

class PlatformGym {
  const PlatformGym({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.tenantStatus,
    required this.country,
    required this.currency,
    required this.phone,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final String status;
  final String tenantStatus;
  final String country;
  final String currency;
  final String phone;
  final String email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => tenantStatus == GymTenantStatus.active;
  bool get isSuspended => tenantStatus == GymTenantStatus.suspended;
  bool get isCancelled => tenantStatus == GymTenantStatus.cancelled;

  factory PlatformGym.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PlatformGym(
      id: doc.id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : doc.id,
      slug: (data['slug'] as String?) ?? '',
      status: (data['status'] as String?) ?? '',
      tenantStatus: GymTenantStatus.normalize(data['tenantStatus'] as String?),
      country: (data['country'] as String?) ?? '',
      currency: (data['currency'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

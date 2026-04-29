import 'package:cloud_firestore/cloud_firestore.dart';

class Staff {
  final String id;
  final String gymId;
  final String? authUid;
  final String fullName;
  final String? phone;
  final String? email;
  final String name;
  final String role;
  final String status;
  final List<String> permissions;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool onDuty;

  const Staff({
    required this.id,
    this.gymId = '',
    this.authUid,
    String? fullName,
    this.phone,
    this.email,
    required this.name,
    required this.role,
    this.status = 'active',
    this.permissions = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    required this.onDuty,
  }) : fullName = fullName ?? name;

  factory Staff.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    final fullName = (m['fullName'] ?? m['name'] ?? '') as String;
    return Staff(
      id: doc.id,
      gymId: (m['gymId'] ?? '') as String,
      authUid: m['authUid'] as String?,
      fullName: fullName,
      phone: m['phone'] as String?,
      email: m['email'] as String?,
      name: fullName,
      role: m['role'] ?? '',
      status: (m['status'] ?? 'active') as String,
      permissions: List<String>.from(m['permissions'] ?? []),
      createdBy: m['createdBy'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      onDuty: (m['onDuty'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'gymId': gymId,
        'authUid': authUid,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'name': name,
        'role': role,
        'status': status,
        'permissions': permissions,
        'createdBy': createdBy,
        'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
        'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
        'onDuty': onDuty,
      };
}

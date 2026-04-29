import 'package:cloud_firestore/cloud_firestore.dart';

class StaffInviteStatus {
  static const pending = 'pending';
  static const claimed = 'claimed';
  static const cancelled = 'cancelled';
  static const expired = 'expired';

  static const all = <String>{
    pending,
    claimed,
    cancelled,
    expired,
  };
}

class StaffInvite {
  final String id;
  final String gymId;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final DateTime? expiresAt;
  final DateTime? claimedAt;
  final String? claimedByUid;

  const StaffInvite({
    required this.id,
    required this.gymId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.expiresAt,
    required this.claimedAt,
    required this.claimedByUid,
  });

  factory StaffInvite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return StaffInvite(
      id: doc.id,
      gymId: (data['gymId'] as String?) ?? '',
      fullName: (data['fullName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: data['phone'] as String?,
      role: (data['role'] as String?) ?? '',
      status: (data['status'] as String?) ?? StaffInviteStatus.pending,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      claimedAt: (data['claimedAt'] as Timestamp?)?.toDate(),
      claimedByUid: data['claimedByUid'] as String?,
    );
  }
}

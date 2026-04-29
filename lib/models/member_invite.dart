import 'package:cloud_firestore/cloud_firestore.dart';

class MemberInviteStatus {
  static const pending = 'pending';
  static const claimed = 'claimed';
  static const cancelled = 'cancelled';
  static const expired = 'expired';
}

class MemberInvite {
  final String id;
  final String gymId;
  final String memberId;
  final String email;
  final String emailNormalized;
  final String fullName;
  final String? phone;
  final String role;
  final String status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final DateTime? claimedAt;
  final String? claimedByUid;

  const MemberInvite({
    required this.id,
    required this.gymId,
    required this.memberId,
    required this.email,
    required this.emailNormalized,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    required this.claimedAt,
    required this.claimedByUid,
  });

  factory MemberInvite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final email = (data['email'] as String?) ?? '';
    return MemberInvite(
      id: doc.id,
      gymId: (data['gymId'] as String?) ?? '',
      memberId: (data['memberId'] as String?) ?? '',
      email: email,
      emailNormalized: (data['emailNormalized'] as String?) ?? email.toLowerCase(),
      fullName: (data['fullName'] as String?) ?? '',
      phone: data['phone'] as String?,
      role: (data['role'] as String?) ?? 'member',
      status: (data['status'] as String?) ?? MemberInviteStatus.pending,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      claimedAt: (data['claimedAt'] as Timestamp?)?.toDate(),
      claimedByUid: data['claimedByUid'] as String?,
    );
  }
}

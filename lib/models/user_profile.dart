import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? phone;
  final String role;
  final String? defaultGymId;
  final String? linkedMemberId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.role,
    required this.defaultGymId,
    required this.linkedMemberId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserProfile(
      uid: doc.id,
      displayName: (data['displayName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: data['phone'] as String?,
      role: (data['role'] as String?) ?? '',
      defaultGymId: data['defaultGymId'] as String?,
      linkedMemberId: data['linkedMemberId'] as String?,
      status: (data['status'] as String?) ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

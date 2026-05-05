import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceSessionStatus {
  static const active = 'active';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
}

class AttendanceSession {
  const AttendanceSession({
    required this.id,
    required this.gymId,
    required this.memberId,
    required this.memberName,
    this.memberPhone,
    this.subscriptionId,
    this.planId,
    this.planName,
    required this.checkInAt,
    this.checkOutAt,
    this.durationMinutes,
    required this.status,
    required this.checkInMethod,
    this.checkOutMethod,
    this.createdBy,
    this.checkedOutBy,
    this.createdAt,
    this.updatedAt,
    this.notes,
  });

  final String id;
  final String gymId;
  final String memberId;
  final String memberName;
  final String? memberPhone;
  final String? subscriptionId;
  final String? planId;
  final String? planName;
  final DateTime checkInAt;
  final DateTime? checkOutAt;
  final int? durationMinutes;
  final String status;
  final String checkInMethod;
  final String? checkOutMethod;
  final String? createdBy;
  final String? checkedOutBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? notes;

  factory AttendanceSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return AttendanceSession(
      id: doc.id,
      gymId: (data['gymId'] as String?) ?? '',
      memberId: (data['memberId'] as String?) ?? '',
      memberName: (data['memberName'] as String?) ?? '',
      memberPhone: data['memberPhone'] as String?,
      subscriptionId: data['subscriptionId'] as String?,
      planId: data['planId'] as String?,
      planName: data['planName'] as String?,
      checkInAt: ((data['checkInAt'] as Timestamp?) ??
              (data['createdAt'] as Timestamp?) ??
              Timestamp.now())
          .toDate(),
      checkOutAt: (data['checkOutAt'] as Timestamp?)?.toDate(),
      durationMinutes: (data['durationMinutes'] as num?)?.round(),
      status: (data['status'] as String?) ?? AttendanceSessionStatus.active,
      checkInMethod: (data['checkInMethod'] as String?) ?? 'manual',
      checkOutMethod: data['checkOutMethod'] as String?,
      createdBy: data['createdBy'] as String?,
      checkedOutBy: data['checkedOutBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
    );
  }
}

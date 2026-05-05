import 'package:cloud_firestore/cloud_firestore.dart';

class StaffPayrollStatus {
  static const paid = 'paid';
  static const pending = 'pending';
  static const cancelled = 'cancelled';
}

class GymStaffPayroll {
  const GymStaffPayroll({
    required this.id,
    required this.gymId,
    required this.staffId,
    required this.staffName,
    required this.role,
    required this.salaryAmount,
    required this.currency,
    required this.periodMonth,
    required this.paymentDate,
    required this.paymentMethod,
    required this.status,
    required this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.cancelledAt,
    required this.cancelledBy,
    required this.cancellationReason,
  });

  final String id;
  final String gymId;
  final String staffId;
  final String staffName;
  final String role;
  final double salaryAmount;
  final String currency;
  final DateTime periodMonth;
  final DateTime paymentDate;
  final String paymentMethod;
  final String status;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;

  factory GymStaffPayroll.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final fallbackDate = DateTime.now();
    return GymStaffPayroll(
      id: doc.id,
      gymId: (data['gymId'] as String?) ?? '',
      staffId: (data['staffId'] as String?) ?? '',
      staffName: (data['staffName'] as String?) ?? 'Unknown staff',
      role: (data['role'] as String?) ?? '',
      salaryAmount: ((data['salaryAmount'] as num?) ?? 0).toDouble(),
      currency: (data['currency'] as String?) ?? 'EGP',
      periodMonth: _date(data['periodMonth']) ?? fallbackDate,
      paymentDate: _date(data['paymentDate']) ?? fallbackDate,
      paymentMethod: (data['paymentMethod'] as String?) ?? 'cash',
      status: (data['status'] as String?) ?? StaffPayrollStatus.paid,
      notes: data['notes'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      cancelledAt: _date(data['cancelledAt']),
      cancelledBy: data['cancelledBy'] as String?,
      cancellationReason: data['cancellationReason'] as String?,
    );
  }
}

DateTime? _date(dynamic value) {
  return value is Timestamp ? value.toDate() : null;
}

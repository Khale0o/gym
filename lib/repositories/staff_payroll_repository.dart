import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsaas/models/staff_payroll.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class StaffPayrollRepository {
  StaffPayrollRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<List<GymStaffPayroll>> streamPayrollForMonth(
    String gymId,
    DateTime monthDate,
  ) {
    return _paths.staffPayrollCollection(gymId).snapshots().map((snap) {
      final start = DateTime(monthDate.year, monthDate.month);
      final end = DateTime(monthDate.year, monthDate.month + 1);
      final rows = snap.docs
          .map(GymStaffPayroll.fromFirestore)
          .where((item) =>
              !item.periodMonth.isBefore(start) && item.periodMonth.isBefore(end))
          .toList()
        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return rows;
    });
  }

  Future<void> createPayrollPayment({
    required String gymId,
    required String staffId,
    required String staffName,
    required String role,
    required double salaryAmount,
    required String currency,
    required DateTime periodMonth,
    required DateTime paymentDate,
    required String paymentMethod,
    required String status,
    required String? notes,
    required String? createdBy,
  }) {
    _validate(
      gymId: gymId,
      staffId: staffId,
      salaryAmount: salaryAmount,
      currency: currency,
      periodMonth: periodMonth,
      paymentMethod: paymentMethod,
      status: status,
    );
    final now = FieldValue.serverTimestamp();
    return _paths.staffPayrollCollection(gymId).add({
      'gymId': gymId,
      'staffId': staffId,
      'staffName': staffName.trim().isEmpty ? 'Unknown staff' : staffName.trim(),
      'role': role,
      'salaryAmount': salaryAmount,
      'currency': currency.trim().toUpperCase(),
      'periodMonth': Timestamp.fromDate(DateTime(periodMonth.year, periodMonth.month)),
      'paymentDate': Timestamp.fromDate(paymentDate),
      'paymentMethod': paymentMethod,
      'status': status,
      'notes': _optional(notes),
      'createdBy': createdBy,
      'createdAt': now,
      'updatedAt': now,
      'cancelledAt': null,
      'cancelledBy': null,
    });
  }

  Future<void> updatePayrollPayment({
    required String gymId,
    required String payrollId,
    required Map<String, dynamic> data,
  }) {
    if (gymId.trim().isEmpty || payrollId.trim().isEmpty) {
      throw StateError('Payroll and gym are required.');
    }
    return _paths.staffPayrollDoc(gymId, payrollId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> cancelPayrollPayment({
    required String gymId,
    required String payrollId,
    required String cancelledBy,
    required String reason,
  }) {
    if (gymId.trim().isEmpty || payrollId.trim().isEmpty) {
      throw StateError('Payroll and gym are required.');
    }
    if (reason.trim().isEmpty) {
      throw StateError('Cancellation reason is required.');
    }
    return _paths.staffPayrollDoc(gymId, payrollId).set({
      'status': StaffPayrollStatus.cancelled,
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': cancelledBy,
      'cancellationReason': reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _validate({
    required String gymId,
    required String staffId,
    required double salaryAmount,
    required String currency,
    required DateTime periodMonth,
    required String paymentMethod,
    required String status,
  }) {
    if (gymId.trim().isEmpty) throw StateError('Gym is required.');
    if (staffId.trim().isEmpty) throw StateError('Staff is required.');
    if (!salaryAmount.isFinite || salaryAmount <= 0) {
      throw StateError('Salary amount must be greater than zero.');
    }
    if (currency.trim().isEmpty) throw StateError('Currency is required.');
    if (periodMonth.year < 2000) throw StateError('Period month is required.');
    if (paymentMethod.trim().isEmpty) {
      throw StateError('Payment method is required.');
    }
    if (![StaffPayrollStatus.paid, StaffPayrollStatus.pending].contains(status)) {
      throw StateError('Unsupported payroll status.');
    }
  }
}

String? _optional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

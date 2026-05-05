import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsaas/models/gym_expense.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class ExpenseRepository {
  ExpenseRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<List<GymExpense>> streamExpensesForMonth(
    String gymId,
    DateTime monthDate,
  ) {
    return _paths.expensesCollection(gymId).snapshots().map((snap) {
      final range = _monthRange(monthDate);
      final rows = snap.docs
          .map(GymExpense.fromFirestore)
          .where((item) => _inRange(item.date, range))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return rows;
    });
  }

  Future<void> createExpense({
    required String gymId,
    required String title,
    required String category,
    required double amount,
    required String currency,
    required String paymentMethod,
    required DateTime date,
    required String status,
    required String? notes,
    required String? createdBy,
  }) {
    _validate(
      gymId: gymId,
      title: title,
      category: category,
      amount: amount,
      currency: currency,
      paymentMethod: paymentMethod,
      status: status,
    );
    final now = FieldValue.serverTimestamp();
    return _paths.expensesCollection(gymId).add({
      'gymId': gymId,
      'title': title.trim(),
      'category': category,
      'amount': amount,
      'currency': currency.trim().toUpperCase(),
      'paymentMethod': paymentMethod,
      'date': Timestamp.fromDate(date),
      'notes': _optional(notes),
      'status': status,
      'createdBy': createdBy,
      'createdAt': now,
      'updatedAt': now,
      'cancelledAt': null,
      'cancelledBy': null,
    });
  }

  Future<void> updateExpense({
    required String gymId,
    required String expenseId,
    required Map<String, dynamic> data,
  }) {
    if (gymId.trim().isEmpty || expenseId.trim().isEmpty) {
      throw StateError('Expense and gym are required.');
    }
    final update = {...data, 'updatedAt': FieldValue.serverTimestamp()};
    return _paths.expenseDoc(gymId, expenseId).set(update, SetOptions(merge: true));
  }

  Future<void> cancelExpense({
    required String gymId,
    required String expenseId,
    required String cancelledBy,
    required String reason,
  }) {
    if (gymId.trim().isEmpty || expenseId.trim().isEmpty) {
      throw StateError('Expense and gym are required.');
    }
    if (reason.trim().isEmpty) {
      throw StateError('Cancellation reason is required.');
    }
    return _paths.expenseDoc(gymId, expenseId).set({
      'status': GymExpenseStatus.cancelled,
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': cancelledBy,
      'cancellationReason': reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _validate({
    required String gymId,
    required String title,
    required String category,
    required double amount,
    required String currency,
    required String paymentMethod,
    required String status,
  }) {
    if (gymId.trim().isEmpty) throw StateError('Gym is required.');
    if (title.trim().isEmpty) throw StateError('Expense title is required.');
    if (!amount.isFinite || amount <= 0) {
      throw StateError('Expense amount must be greater than zero.');
    }
    if (currency.trim().isEmpty) throw StateError('Currency is required.');
    if (!GymExpenseCategory.all.contains(category)) {
      throw StateError('Expense category is required.');
    }
    if (paymentMethod.trim().isEmpty) {
      throw StateError('Payment method is required.');
    }
    if (![
      GymExpenseStatus.paid,
      GymExpenseStatus.pending,
    ].contains(status)) {
      throw StateError('Unsupported expense status.');
    }
  }
}

({DateTime start, DateTime end}) _monthRange(DateTime monthDate) {
  final start = DateTime(monthDate.year, monthDate.month);
  final end = DateTime(monthDate.year, monthDate.month + 1);
  return (start: start, end: end);
}

bool _inRange(DateTime date, ({DateTime start, DateTime end}) range) {
  return !date.isBefore(range.start) && date.isBefore(range.end);
}

String? _optional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

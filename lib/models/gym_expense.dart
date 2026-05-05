import 'package:cloud_firestore/cloud_firestore.dart';

class GymExpenseStatus {
  static const paid = 'paid';
  static const pending = 'pending';
  static const cancelled = 'cancelled';
}

class GymExpenseCategory {
  static const rent = 'rent';
  static const salaries = 'salaries';
  static const equipment = 'equipment';
  static const maintenance = 'maintenance';
  static const utilities = 'utilities';
  static const marketing = 'marketing';
  static const supplies = 'supplies';
  static const supplementsStock = 'supplements_stock';
  static const other = 'other';

  static const all = <String>[
    rent,
    salaries,
    equipment,
    maintenance,
    utilities,
    marketing,
    supplies,
    supplementsStock,
    other,
  ];
}

class GymExpense {
  const GymExpense({
    required this.id,
    required this.gymId,
    required this.title,
    required this.category,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.date,
    required this.notes,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.cancelledAt,
    required this.cancelledBy,
    required this.cancellationReason,
  });

  final String id;
  final String gymId;
  final String title;
  final String category;
  final double amount;
  final String currency;
  final String paymentMethod;
  final DateTime date;
  final String? notes;
  final String status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;

  factory GymExpense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return GymExpense(
      id: doc.id,
      gymId: (data['gymId'] as String?) ?? '',
      title: (data['title'] as String?) ?? 'Untitled expense',
      category: (data['category'] as String?) ?? GymExpenseCategory.other,
      amount: ((data['amount'] as num?) ?? 0).toDouble(),
      currency: (data['currency'] as String?) ?? 'EGP',
      paymentMethod: (data['paymentMethod'] as String?) ?? 'cash',
      date: _date(data['date']) ?? _date(data['createdAt']) ?? DateTime.now(),
      notes: data['notes'] as String?,
      status: (data['status'] as String?) ?? GymExpenseStatus.paid,
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

import 'package:cloud_firestore/cloud_firestore.dart';

class GymTransaction {
  final String id;
  final String category;
  final double amount;
  final String type; // income / expense
  final DateTime date;

  const GymTransaction({
    required this.id,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
  });

  factory GymTransaction.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return GymTransaction(
      id: doc.id,
      category: m['category'] ?? '',
      amount: (m['amount'] ?? 0).toDouble(),
      type: m['type'] ?? 'income',
      date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'category': category,
        'amount': amount,
        'type': type,
        'date': Timestamp.fromDate(date),
      };
}

import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionStatus {
  static const active = 'active';
  static const expired = 'expired';
  static const pending = 'pending';
  static const cancelled = 'cancelled';
}

class SubscriptionPaymentStatus {
  static const paid = 'paid';
  static const unpaid = 'unpaid';
  static const partial = 'partial';
}

class SubscriptionPaymentMethod {
  static const cash = 'cash';
  static const instapay = 'instapay';
  static const vodafoneCash = 'vodafone_cash';
  static const card = 'card';
  static const online = 'online';
  static const unknown = 'unknown';
}

class GymSubscription {
  final String id;
  final String gymId;
  final String memberId;
  final String memberName;
  final String planId;
  final String planName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final String paymentStatus;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final String? notes;

  const GymSubscription({
    required this.id,
    required this.gymId,
    required this.memberId,
    required this.memberName,
    required this.planId,
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.paymentStatus,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.cancelledAt,
    required this.notes,
  });

  factory GymSubscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return GymSubscription(
      id: doc.id,
      gymId: (data['gymId'] as String?) ?? '',
      memberId: (data['memberId'] as String?) ?? '',
      memberName: (data['memberName'] as String?) ?? '',
      planId: (data['planId'] as String?) ?? '',
      planName: (data['planName'] as String?) ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      status: (data['status'] as String?) ?? SubscriptionStatus.pending,
      paymentStatus:
          (data['paymentStatus'] as String?) ?? SubscriptionPaymentStatus.unpaid,
      amount: ((data['amount'] as num?) ?? 0).toDouble(),
      currency: (data['currency'] as String?) ?? 'EGP',
      paymentMethod:
          (data['paymentMethod'] as String?) ?? SubscriptionPaymentMethod.unknown,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'gymId': gymId,
        'memberId': memberId,
        'memberName': memberName,
        'planId': planId,
        'planName': planName,
        'startDate': startDate == null ? null : Timestamp.fromDate(startDate!),
        'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),
        'status': status,
        'paymentStatus': paymentStatus,
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'createdBy': createdBy,
        'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
        'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
        'cancelledAt':
            cancelledAt == null ? null : Timestamp.fromDate(cancelledAt!),
        'notes': notes,
      };
}

import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionType {
  static const subscriptionPayment = 'subscription_payment';
  static const renewal = 'renewal';
  static const productSale = 'product_sale';
  static const service = 'service';
  static const adjustment = 'adjustment';
  static const refund = 'refund';
}

class TransactionPaymentMethod {
  static const cash = 'cash';
  static const instapay = 'instapay';
  static const vodafoneCash = 'vodafone_cash';
  static const card = 'card';
  static const online = 'online';
  static const unknown = 'unknown';
}

class TransactionPaymentStatus {
  static const paid = 'paid';
  static const partial = 'partial';
  static const unpaid = 'unpaid';
  static const refunded = 'refunded';
}

class GymTransaction {
  final String id;
  final String gymId;
  final String memberId;
  final String memberName;
  final String? subscriptionId;
  final String? planId;
  final String type;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final String description;
  final String receiptNumber;
  final String createdByUid;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const GymTransaction({
    required this.id,
    required this.gymId,
    required this.memberId,
    required this.memberName,
    required this.subscriptionId,
    required this.planId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.description,
    required this.receiptNumber,
    required this.createdByUid,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    required this.notes,
    required this.metadata,
  });

  factory GymTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final legacyDate = (data['date'] as Timestamp?)?.toDate();
    final legacyCategory = data['category'] as String?;
    return GymTransaction(
      id: doc.id,
      gymId: (data['gymId'] as String?) ?? '',
      memberId: (data['memberId'] as String?) ?? '',
      memberName: (data['memberName'] as String?) ?? '',
      subscriptionId: data['subscriptionId'] as String?,
      planId: data['planId'] as String?,
      type: (data['type'] as String?) ?? TransactionType.subscriptionPayment,
      amount: ((data['amount'] as num?) ?? 0).toDouble(),
      currency: (data['currency'] as String?) ?? 'EGP',
      paymentMethod:
          (data['paymentMethod'] as String?) ?? TransactionPaymentMethod.unknown,
      paymentStatus:
          (data['paymentStatus'] as String?) ?? TransactionPaymentStatus.paid,
      description: (data['description'] as String?) ?? legacyCategory ?? '',
      receiptNumber: (data['receiptNumber'] as String?) ?? doc.id,
      createdByUid: (data['createdByUid'] as String?) ?? '',
      createdByName: data['createdByName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? legacyDate,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
      metadata: (data['metadata'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'gymId': gymId,
        'memberId': memberId,
        'memberName': memberName,
        'subscriptionId': subscriptionId,
        'planId': planId,
        'type': type,
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'description': description,
        'receiptNumber': receiptNumber,
        'createdByUid': createdByUid,
        'createdByName': createdByName,
        'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
        'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
        'notes': notes,
        'metadata': metadata,
      };

  // Legacy compatibility for the existing ERP row widget.
  String get category => description.isEmpty ? type : description;
  DateTime get date => createdAt ?? DateTime.now();
}

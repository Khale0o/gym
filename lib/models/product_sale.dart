import 'package:cloud_firestore/cloud_firestore.dart';

class ProductSaleStatus {
  static const paid = 'paid';
  static const pending = 'pending';
  static const cancelled = 'cancelled';
}

class ProductSale {
  const ProductSale({
    required this.id,
    required this.gymId,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.memberId,
    required this.memberName,
    required this.quantity,
    required this.unitSellingPrice,
    required this.unitCostPrice,
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.saleDate,
    required this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.cancelledAt,
    required this.cancelledBy,
    required this.cancellationReason,
    required this.stockWasTracked,
  });

  final String id;
  final String gymId;
  final String productId;
  final String productName;
  final String productCategory;
  final String? memberId;
  final String? memberName;
  final int quantity;
  final double unitSellingPrice;
  final double unitCostPrice;
  final double totalRevenue;
  final double totalCost;
  final double grossProfit;
  final String currency;
  final String paymentMethod;
  final String status;
  final DateTime saleDate;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final bool stockWasTracked;

  factory ProductSale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final quantity = ((data['quantity'] as num?) ?? 0).toInt();
    final unitSelling = ((data['unitSellingPrice'] as num?) ?? 0).toDouble();
    final unitCost = ((data['unitCostPrice'] as num?) ?? 0).toDouble();
    final totalRevenue =
        ((data['totalRevenue'] as num?) ?? unitSelling * quantity).toDouble();
    final totalCost =
        ((data['totalCost'] as num?) ?? unitCost * quantity).toDouble();
    return ProductSale(
      id: doc.id,
      gymId: (data['gymId'] as String?) ?? '',
      productId: (data['productId'] as String?) ?? '',
      productName: (data['productName'] as String?) ?? 'Unknown product',
      productCategory:
          (data['productCategory'] as String?) ?? (data['category'] as String?) ?? 'other',
      memberId: data['memberId'] as String?,
      memberName: data['memberName'] as String?,
      quantity: quantity,
      unitSellingPrice: unitSelling,
      unitCostPrice: unitCost,
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      grossProfit:
          ((data['grossProfit'] as num?) ?? totalRevenue - totalCost).toDouble(),
      currency: (data['currency'] as String?) ?? 'EGP',
      paymentMethod: (data['paymentMethod'] as String?) ?? 'cash',
      status: (data['status'] as String?) ?? ProductSaleStatus.paid,
      saleDate: _date(data['saleDate']) ?? _date(data['createdAt']) ?? DateTime.now(),
      notes: data['notes'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      cancelledAt: _date(data['cancelledAt']),
      cancelledBy: data['cancelledBy'] as String?,
      cancellationReason: data['cancellationReason'] as String?,
      stockWasTracked: (data['stockWasTracked'] as bool?) ?? false,
    );
  }
}

DateTime? _date(dynamic value) {
  return value is Timestamp ? value.toDate() : null;
}

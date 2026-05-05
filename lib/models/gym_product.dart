import 'package:cloud_firestore/cloud_firestore.dart';

class GymProductCategory {
  static const supplement = 'supplement';
  static const drink = 'drink';
  static const equipment = 'equipment';
  static const clothing = 'clothing';
  static const other = 'other';

  static const all = <String>[
    supplement,
    drink,
    equipment,
    clothing,
    other,
  ];
}

class GymProductStatus {
  static const active = 'active';
  static const inactive = 'inactive';
  static const discontinued = 'discontinued';
}

class GymProduct {
  const GymProduct({
    required this.id,
    required this.gymId,
    required this.name,
    required this.category,
    required this.description,
    required this.sellingPrice,
    required this.costPrice,
    required this.currency,
    required this.stockQuantity,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String gymId;
  final String name;
  final String category;
  final String? description;
  final double sellingPrice;
  final double costPrice;
  final String currency;
  final int? stockQuantity;
  final String status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get tracksStock => stockQuantity != null;

  factory GymProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return GymProduct(
      id: doc.id,
      gymId: (data['gymId'] as String?) ?? '',
      name: (data['name'] as String?) ?? 'Unnamed product',
      category: (data['category'] as String?) ?? GymProductCategory.other,
      description: data['description'] as String?,
      sellingPrice: ((data['sellingPrice'] as num?) ?? 0).toDouble(),
      costPrice: ((data['costPrice'] as num?) ?? 0).toDouble(),
      currency: (data['currency'] as String?) ?? 'EGP',
      stockQuantity: (data['stockQuantity'] as num?)?.toInt(),
      status: (data['status'] as String?) ?? GymProductStatus.active,
      createdBy: data['createdBy'] as String?,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }
}

DateTime? _date(dynamic value) {
  return value is Timestamp ? value.toDate() : null;
}

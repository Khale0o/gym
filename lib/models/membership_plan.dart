import 'package:cloud_firestore/cloud_firestore.dart';

class MembershipPlan {
  final String id;
  final String gymId;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final int durationDays;
  final List<String> features;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MembershipPlan({
    required this.id,
    required this.gymId,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.features,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MembershipPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return MembershipPlan(
      id: doc.id,
      gymId: (data['gymId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      description: data['description'] as String?,
      price: ((data['price'] as num?) ?? 0).toDouble(),
      currency: (data['currency'] as String?) ?? 'EGP',
      durationDays: ((data['durationDays'] as num?) ?? 30).toInt(),
      features: List<String>.from(data['features'] ?? const []),
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'gymId': gymId,
        'name': name,
        'description': description,
        'price': price,
        'currency': currency,
        'durationDays': durationDays,
        'features': features,
        'isActive': isActive,
        'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
        'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      };
}

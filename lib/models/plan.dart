import 'package:cloud_firestore/cloud_firestore.dart';

class GymPlan {
  final String id;
  final String name;
  final double price;
  final int membersCount;

  const GymPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.membersCount,
  });

  factory GymPlan.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return GymPlan(
      id: doc.id,
      name: m['name'] ?? '',
      price: (m['price'] ?? 0).toDouble(),
      membersCount: (m['membersCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'membersCount': membersCount,
      };
}

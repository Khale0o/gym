import 'package:cloud_firestore/cloud_firestore.dart';

class Staff {
  final String id;
  final String name;
  final String role;
  final bool onDuty;

  const Staff({
    required this.id,
    required this.name,
    required this.role,
    required this.onDuty,
  });

  factory Staff.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return Staff(
      id: doc.id,
      name: m['name'] ?? '',
      role: m['role'] ?? '',
      onDuty: (m['onDuty'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role,
        'onDuty': onDuty,
      };
}

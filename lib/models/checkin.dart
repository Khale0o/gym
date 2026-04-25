import 'package:cloud_firestore/cloud_firestore.dart';

class CheckIn {
  final String id;
  final String memberId;
  final String name;
  final DateTime time;
  final String method; // NFC / QR / Manual
  final String plan;

  const CheckIn({
    required this.id,
    required this.memberId,
    required this.name,
    required this.time,
    required this.method,
    required this.plan,
  });

  factory CheckIn.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return CheckIn(
      id: doc.id,
      memberId: m['memberId'] ?? '',
      name: m['name'] ?? '',
      time: (m['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      method: m['method'] ?? 'Manual',
      plan: m['plan'] ?? 'Basic',
    );
  }

  Map<String, dynamic> toMap() => {
        'memberId': memberId,
        'name': name,
        'time': Timestamp.fromDate(time),
        'method': method,
        'plan': plan,
      };
}

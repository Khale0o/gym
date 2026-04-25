import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream of the current occupancy count from `occupancy/current`.
final occupancyStreamProvider = StreamProvider<double>((ref) {
  return FirebaseFirestore.instance
      .doc('occupancy/current')
      .snapshots()
      .map((snap) {
    if (!snap.exists) return 0.0;
    final data = snap.data() as Map<String, dynamic>;
    return (data['count'] ?? 0).toDouble();
  });
});

/// Writes a new occupancy count to Firestore.
Future<void> updateOccupancy(double count) async {
  await FirebaseFirestore.instance
      .doc('occupancy/current')
      .set({'count': count.round()}, SetOptions(merge: true));
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream of the current occupancy count from `occupancy/current`.
final occupancyStreamProvider = StreamProvider<double>((ref) {
  return FirebaseFirestore.instance.doc('occupancy/current').snapshots().map((snap) {
    if (!snap.exists) return 0.0;
    final data = snap.data() as Map<String, dynamic>;
    return (data['count'] ?? 0).toDouble();
  });
});

/// Writes a new occupancy count to Firestore safely.
Future<void> updateOccupancy(double count) async {
  final db = FirebaseFirestore.instance;
  final occupancyRef = db.doc('occupancy/current');
  final nextCount = count.round().clamp(0, 1 << 30);

  try {
    await db.runTransaction((transaction) async {
      final snap = await transaction.get(occupancyRef);
      final currentData = snap.data();
      final currentCount = (currentData?['count'] ?? 0).toInt();
      final safeCount = nextCount < 0 ? 0 : nextCount;

      transaction.set(
        occupancyRef,
        {
          'count': safeCount < 0 ? 0 : safeCount,
          if (!snap.exists && currentCount == 0) 'createdAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );
    });
  } on FirebaseException catch (error) {
    throw StateError(
      'Occupancy update failed: ${error.message ?? error.code}',
    );
  } catch (_) {
    throw StateError('Occupancy update failed. Please try again.');
  }
}

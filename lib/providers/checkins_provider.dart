import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/models/checkin.dart';

/// Streams the 8 most recent check-ins ordered by timestamp descending.
final recentCheckinsProvider = StreamProvider<List<CheckIn>>((ref) {
  return FirebaseFirestore.instance
      .collection('checkins')
      .orderBy('time', descending: true)
      .limit(8)
      .snapshots()
      .map((snap) => snap.docs.map(CheckIn.fromFirestore).toList());
});

/// Adds a new check-in and increments occupancy in a single transaction.
Future<void> addCheckIn({
  required String memberId,
  required String name,
  required String method,
  required String plan,
}) async {
  final db = FirebaseFirestore.instance;
  final occupancyRef = db.doc('occupancy/current');
  final checkinRef = db.collection('checkins').doc();

  try {
    await db.runTransaction((transaction) async {
      final occupancySnap = await transaction.get(occupancyRef);
      final occupancyData = occupancySnap.data();
      final currentCount = (occupancyData?['count'] ?? 0).toInt();

      transaction.set(checkinRef, {
        'memberId': memberId,
        'name': name,
        'time': Timestamp.now(),
        'method': method,
        'plan': plan,
      });

      transaction.set(
        occupancyRef,
        {'count': currentCount + 1},
        SetOptions(merge: true),
      );
    });
  } on FirebaseException catch (error) {
    throw StateError(
      'Check-in transaction failed: ${error.message ?? error.code}',
    );
  } catch (_) {
    throw StateError('Check-in transaction failed. Please try again.');
  }
}

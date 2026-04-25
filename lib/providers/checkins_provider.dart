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

/// Adds a new check-in and increments occupancy.
Future<void> addCheckIn({
  required String memberId,
  required String name,
  required String method,
  required String plan,
}) async {
  final db = FirebaseFirestore.instance;
  await db.collection('checkins').add({
    'memberId': memberId,
    'name': name,
    'time': Timestamp.now(),
    'method': method,
    'plan': plan,
  });
  // increment occupancy
  await db.doc('occupancy/current').update({
    'count': FieldValue.increment(1),
  });
}

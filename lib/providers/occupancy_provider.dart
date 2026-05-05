import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';

/// Stream of the current gym occupancy from `gyms/{gymId}/settings/occupancy`.
final occupancyStreamProvider = StreamProvider<double>((ref) {
  final gymId = ref.watch(currentGymIdProvider)?.trim();
  if (gymId == null || gymId.isEmpty) {
    throw StateError('Missing gym context for occupancy.');
  }
  return ref.watch(checkInRepositoryProvider).streamOccupancy(gymId);
});

/// Legacy helper retained for older screens that have not been migrated yet.
/// The Phase 2F check-in screen uses the gym-scoped repository directly.
Future<void> updateOccupancy({
  required String gymId,
  required double count,
}) async {
  final trimmedGymId = gymId.trim();
  if (trimmedGymId.isEmpty) {
    throw StateError('Missing gym context for occupancy.');
  }

  final db = FirebaseFirestore.instance;
  final occupancyRef = db
      .collection('gyms')
      .doc(trimmedGymId)
      .collection('settings')
      .doc('occupancy');
  final safeCount = count.round().clamp(0, 1 << 30);

  try {
    await db.runTransaction((transaction) async {
      final snap = await transaction.get(occupancyRef);
      transaction.set(
        occupancyRef,
        {
          'count': safeCount,
          if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsaas/models/subscription.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<List<GymSubscription>> streamSubscriptions(String gymId) {
    return _paths
        .subscriptionsCollection(gymId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(GymSubscription.fromFirestore).toList());
  }

  Stream<List<GymSubscription>> streamMemberSubscriptions(
    String gymId,
    String memberId,
  ) {
    return _paths
        .subscriptionsCollection(gymId)
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((snap) {
      final subscriptions =
          snap.docs.map(GymSubscription.fromFirestore).toList();
      subscriptions.sort((a, b) =>
          (b.startDate ?? DateTime(1900)).compareTo(a.startDate ?? DateTime(1900)));
      return subscriptions;
    });
  }

  Stream<GymSubscription?> streamActiveSubscriptionForMember(
    String gymId,
    String memberId,
  ) {
    return _paths
        .subscriptionsCollection(gymId)
        .where('memberId', isEqualTo: memberId)
        .where('status', isEqualTo: SubscriptionStatus.active)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : GymSubscription.fromFirestore(snap.docs.first));
  }

  Future<DocumentReference<Map<String, dynamic>>> createSubscription(
    String gymId,
    Map<String, dynamic> subscription,
  ) {
    final now = FieldValue.serverTimestamp();
    return _paths.subscriptionsCollection(gymId).add({
      ...subscription,
      'gymId': gymId,
      'createdAt': subscription['createdAt'] ?? now,
      'updatedAt': subscription['updatedAt'] ?? now,
    });
  }

  Future<void> updateSubscription(
    String gymId,
    String subscriptionId,
    Map<String, dynamic> data,
  ) {
    return _paths.subscriptionDoc(gymId, subscriptionId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

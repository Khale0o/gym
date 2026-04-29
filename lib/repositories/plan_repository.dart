import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsaas/models/membership_plan.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class PlanRepository {
  PlanRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<List<MembershipPlan>> streamPlans(String gymId) {
    return _paths
        .plansCollection(gymId)
        .orderBy('price')
        .snapshots()
        .map((snap) => snap.docs.map(MembershipPlan.fromFirestore).toList());
  }

  Stream<List<MembershipPlan>> streamActivePlans(String gymId) {
    return _paths
        .plansCollection(gymId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final plans = snap.docs.map(MembershipPlan.fromFirestore).toList();
      plans.sort((a, b) => a.price.compareTo(b.price));
      return plans;
    });
  }

  Future<MembershipPlan?> getPlan(String gymId, String planId) async {
    final doc = await _paths.planDoc(gymId, planId).get();
    if (!doc.exists) return null;
    return MembershipPlan.fromFirestore(doc);
  }

  Future<DocumentReference<Map<String, dynamic>>> createPlan(
    String gymId,
    Map<String, dynamic> plan,
  ) {
    final now = FieldValue.serverTimestamp();
    return _paths.plansCollection(gymId).add({
      ...plan,
      'gymId': gymId,
      'createdAt': plan['createdAt'] ?? now,
      'updatedAt': plan['updatedAt'] ?? now,
    });
  }

  Future<void> updatePlan(
    String gymId,
    String planId,
    Map<String, dynamic> data,
  ) {
    return _paths.planDoc(gymId, planId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> seedDefaultPlansIfEmpty(String gymId) async {
    final existing = await _paths.plansCollection(gymId).limit(1).get();
    if (existing.docs.isNotEmpty) {
      throw StateError('Plans already exist for this gym.');
    }

    final batch = _paths.plansCollection(gymId).firestore.batch();
    final now = FieldValue.serverTimestamp();
    final defaults = [
      {
        'name': 'Basic',
        'description': 'Starter monthly membership.',
        'price': 500,
        'durationDays': 30,
        'features': ['Gym access'],
      },
      {
        'name': 'Premium',
        'description': 'Monthly membership with extra support.',
        'price': 800,
        'durationDays': 30,
        'features': ['Gym access', 'Group classes'],
      },
      {
        'name': 'Elite',
        'description': 'Full monthly membership experience.',
        'price': 1200,
        'durationDays': 30,
        'features': ['Gym access', 'Group classes', 'Coach check-ins'],
      },
    ];

    for (final plan in defaults) {
      final ref = _paths.plansCollection(gymId).doc();
      batch.set(ref, {
        ...plan,
        'gymId': gymId,
        'currency': 'EGP',
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      });
    }

    await batch.commit();
  }
}

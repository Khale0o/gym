import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsaas/models/gym_tenant.dart';

class PlatformAdminRepository {
  PlatformAdminRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<PlatformGym>> streamGyms() {
    return _firestore.collection('gyms').snapshots().map((snapshot) {
      final gyms = snapshot.docs.map(PlatformGym.fromFirestore).toList();
      gyms.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return gyms;
    });
  }

  Future<void> suspendGym({
    required String gymId,
    required String reason,
    required String updatedBy,
  }) {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw StateError('Suspension reason is required.');
    }

    return _firestore.collection('gyms').doc(gymId).set({
      'tenantStatus': GymTenantStatus.suspended,
      'suspendedAt': FieldValue.serverTimestamp(),
      'suspendedBy': updatedBy,
      'suspensionReason': trimmedReason,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    }, SetOptions(merge: true));
  }

  Future<void> resumeGym({
    required String gymId,
    required String updatedBy,
  }) {
    return _firestore.collection('gyms').doc(gymId).set({
      'tenantStatus': GymTenantStatus.active,
      'resumedAt': FieldValue.serverTimestamp(),
      'resumedBy': updatedBy,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    }, SetOptions(merge: true));
  }

  Future<void> cancelGym({
    required String gymId,
    required String reason,
    required String updatedBy,
  }) {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw StateError('Cancellation reason is required.');
    }

    return _firestore.collection('gyms').doc(gymId).set({
      'tenantStatus': GymTenantStatus.cancelled,
      'cancellationReason': trimmedReason,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    }, SetOptions(merge: true));
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsaas/models/staff.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class StaffRepository {
  StaffRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<List<Staff>> streamStaff(String gymId) {
    return _paths
        .staffCollection(gymId)
        .orderBy('fullName')
        .snapshots()
        .map((snap) => snap.docs.where((doc) {
              final data = doc.data();
              final accountStatus =
                  (data['accountStatus'] as String?)?.trim().toLowerCase();
              return accountStatus != 'archived' &&
                  !data.containsKey('deletedAt');
            }).map(Staff.fromFirestore).toList());
  }

  Future<Staff?> getStaff(String gymId, String staffId) async {
    final doc = await _paths.staffDoc(gymId, staffId).get();
    if (!doc.exists) {
      return null;
    }
    return Staff.fromFirestore(doc);
  }

  Future<DocumentReference<Map<String, dynamic>>> createStaff(
    String gymId,
    Map<String, dynamic> staffData,
  ) {
    final now = FieldValue.serverTimestamp();
    return _paths.staffCollection(gymId).add({
      ...staffData,
      'gymId': gymId,
      'createdAt': staffData['createdAt'] ?? now,
      'updatedAt': staffData['updatedAt'] ?? now,
    });
  }

  Future<void> updateStaff(
    String gymId,
    String staffId,
    Map<String, dynamic> data,
  ) {
    return _paths.staffDoc(gymId, staffId).set({
      ...data,
      'gymId': gymId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> archiveStaff({
    required String gymId,
    required String staffId,
    required String reason,
    required String performedByUid,
  }) async {
    final trimmedGymId = gymId.trim();
    final trimmedStaffId = staffId.trim();
    final trimmedReason = reason.trim();
    final trimmedPerformedBy = performedByUid.trim();

    if (trimmedGymId.isEmpty) {
      throw StateError('Gym ID is required.');
    }
    if (trimmedStaffId.isEmpty) {
      throw StateError('Staff ID is required.');
    }
    if (trimmedReason.isEmpty) {
      throw StateError('Reason is required.');
    }
    if (trimmedPerformedBy.isEmpty) {
      throw StateError('Signed-in user is required.');
    }
    if (trimmedStaffId == trimmedPerformedBy) {
      throw StateError('You cannot archive yourself.');
    }

    final staffRef = _paths.staffDoc(trimmedGymId, trimmedStaffId);
    final staffSnap = await staffRef.get();
    if (!staffSnap.exists) {
      throw StateError('Staff profile not found.');
    }

    final staffData = staffSnap.data() ?? <String, dynamic>{};
    final authUid = (staffData['authUid'] as String?)?.trim();
    if (authUid != null && authUid == trimmedPerformedBy) {
      throw StateError('You cannot archive yourself.');
    }

    final role = (staffData['role'] as String?)?.trim().toLowerCase();
    if (role == 'owner') {
      final owners = await _paths
          .staffCollection(trimmedGymId)
          .where('role', isEqualTo: 'owner')
          .get();
      final activeOwners = owners.docs.where((doc) {
        final data = doc.data();
        final status = (data['status'] as String?)?.trim().toLowerCase();
        final accountStatus =
            (data['accountStatus'] as String?)?.trim().toLowerCase();
        return status != 'inactive' &&
            accountStatus != 'archived' &&
            !data.containsKey('deletedAt');
      }).length;
      if (activeOwners <= 1) {
        throw StateError('You cannot archive the last owner.');
      }
    }

    final firestore = _paths.staffCollection(trimmedGymId).firestore;
    final batch = firestore.batch();
    final now = FieldValue.serverTimestamp();
    final archiveData = <String, dynamic>{
      'status': 'inactive',
      'accountStatus': 'archived',
      'deletedAt': now,
      'deletedBy': trimmedPerformedBy,
      'deleteReason': trimmedReason,
      'updatedAt': now,
    };

    batch.update(staffRef, archiveData);
    if (authUid != null && authUid.isNotEmpty) {
      batch.update(firestore.collection('users').doc(authUid), {
        'status': 'inactive',
        'accountStatus': 'archived',
        'updatedAt': now,
      });
    }
    await batch.commit();
  }
}

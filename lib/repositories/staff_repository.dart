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
        .map((snap) => snap.docs.map(Staff.fromFirestore).toList());
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
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class MemberRepository {
  MemberRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<List<Member>> streamMembers(String gymId) {
    return _paths
        .membersCollection(gymId)
        .orderBy('fullName')
        .snapshots()
        .map((snap) => snap.docs.map(Member.fromFirestore).toList());
  }

  Future<Member?> getMember(String gymId, String memberId) async {
    final doc = await _paths.memberDoc(gymId, memberId).get();
    if (!doc.exists) {
      return null;
    }
    return Member.fromFirestore(doc);
  }

  Future<Member?> getMemberByAuthUid(String gymId, String authUid) async {
    final snap = await _paths
        .membersCollection(gymId)
        .where('authUid', isEqualTo: authUid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      return null;
    }
    return Member.fromFirestore(snap.docs.first);
  }

  Future<DocumentReference<Map<String, dynamic>>> createMember(
    String gymId,
    Map<String, dynamic> memberData,
  ) {
    final now = FieldValue.serverTimestamp();
    return _paths.membersCollection(gymId).add({
      ...memberData,
      'gymId': gymId,
      'createdAt': memberData['createdAt'] ?? now,
      'updatedAt': memberData['updatedAt'] ?? now,
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> createMemberWithRelatedRecords({
    required String gymId,
    required Map<String, dynamic> memberData,
    Map<String, dynamic>? inviteData,
    Map<String, dynamic>? subscriptionData,
    Map<String, dynamic>? memberSummaryData,
  }) async {
    final firestore = _paths.membersCollection(gymId).firestore;
    final batch = firestore.batch();
    final now = FieldValue.serverTimestamp();
    final memberRef = _paths.membersCollection(gymId).doc();

    batch.set(memberRef, {
      ...memberData,
      'gymId': gymId,
      'createdAt': memberData['createdAt'] ?? now,
      'updatedAt': memberData['updatedAt'] ?? now,
    });

    if (inviteData != null) {
      final inviteRef = _paths.memberInvitesCollection(gymId).doc();
      batch.set(inviteRef, {
        ...inviteData,
        'gymId': gymId,
        'memberId': memberRef.id,
        'role': 'member',
        'status': 'pending',
        'createdAt': inviteData['createdAt'] ?? now,
        'updatedAt': inviteData['updatedAt'] ?? now,
      });
    }

    if (subscriptionData != null) {
      final subscriptionRef = _paths.subscriptionsCollection(gymId).doc();
      batch.set(subscriptionRef, {
        ...subscriptionData,
        'gymId': gymId,
        'memberId': memberRef.id,
        'createdAt': subscriptionData['createdAt'] ?? now,
        'updatedAt': subscriptionData['updatedAt'] ?? now,
      });
    }

    if (memberSummaryData != null) {
      batch.set(memberRef, {
        ...memberSummaryData,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }

    await batch.commit();
    return memberRef;
  }

  Future<void> updateMember(
    String gymId,
    String memberId,
    Map<String, dynamic> data,
  ) {
    return _paths.memberDoc(gymId, memberId).set({
      ...data,
      'gymId': gymId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

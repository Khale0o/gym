import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gymsaas/models/member_invite.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class MemberInviteRepository {
  MemberInviteRepository(this._db, this._paths);

  final FirebaseFirestore _db;
  final GymFirestorePaths _paths;

  Future<DocumentReference<Map<String, dynamic>>> createMemberInvite(
    String gymId,
    Map<String, dynamic> invite,
  ) {
    final email = _normalizeEmail(invite['email'] as String? ?? '');
    final now = FieldValue.serverTimestamp();
    return _paths.memberInvitesCollection(gymId).add({
      ...invite,
      'gymId': gymId,
      'email': email,
      'emailNormalized': email,
      'role': 'member',
      'status': MemberInviteStatus.pending,
      'createdAt': invite['createdAt'] ?? now,
      'updatedAt': invite['updatedAt'] ?? now,
    });
  }

  Future<void> cancelMemberInvite(String gymId, String inviteId) {
    return _paths.memberInviteDoc(gymId, inviteId).set({
      'status': MemberInviteStatus.cancelled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> pendingInviteEmailExists(String gymId, String email) async {
    final normalized = _normalizeEmail(email);
    final snapshot = await _paths
        .memberInvitesCollection(gymId)
        .where('emailNormalized', isEqualTo: normalized)
        .where('status', isEqualTo: MemberInviteStatus.pending)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<bool> linkedMemberEmailExists(String gymId, String email) async {
    final normalized = _normalizeEmail(email);
    final snapshot = await _paths
        .membersCollection(gymId)
        .where('emailNormalized', isEqualTo: normalized)
        .limit(5)
        .get();
    return snapshot.docs.any((doc) {
      final data = doc.data();
      return ((data['authUid'] as String?) ?? '').trim().isNotEmpty;
    });
  }

  Future<MemberInviteClaimTarget?> findValidPendingInviteForSignupOrNull(
    String email,
  ) async {
    final normalized = _normalizeEmail(email);
    _debugLog('Member invite lookup started for: $normalized');

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _db
          .collectionGroup('memberInvites')
          .where('emailNormalized', isEqualTo: normalized)
          .where('status', isEqualTo: MemberInviteStatus.pending)
          .get();
    } on FirebaseException catch (error) {
      _debugLog('Member invite lookup FirebaseException: ${error.code} ${error.message}');
      throw StateError(_mapLookupError(error));
    }

    _debugLog('Member invite candidates found: ${snapshot.docs.length}');
    if (snapshot.docs.isEmpty) return null;

    final now = DateTime.now();
    final matching = snapshot.docs.where((doc) {
      final invite = MemberInvite.fromFirestore(doc);
      return _normalizeEmail(invite.email) == normalized;
    }).toList();
    if (matching.isEmpty) return null;

    final valid = matching.where((doc) {
      final invite = MemberInvite.fromFirestore(doc);
      return invite.role == 'member' &&
          invite.gymId.trim().isNotEmpty &&
          invite.memberId.trim().isNotEmpty &&
          (invite.expiresAt == null || invite.expiresAt!.isAfter(now));
    }).toList();

    if (valid.isEmpty) {
      throw StateError(
        'Member invite found, but it is expired or invalid. Ask the gym to send a new invite.',
      );
    }
    if (valid.length > 1) {
      throw StateError(
        'Multiple pending member invites found. Please contact the gym owner.',
      );
    }

    final doc = valid.single;
    final invite = MemberInvite.fromFirestore(doc);
    _debugLog('Selected member invite ${invite.id} for gym ${invite.gymId}');
    return MemberInviteClaimTarget(invite: invite, inviteRef: doc.reference);
  }

  Future<void> claimMemberInvite({
    required MemberInviteClaimTarget target,
    required String uid,
    required String fullName,
    required String email,
    required String? phone,
  }) async {
    final normalized = _normalizeEmail(email);
    _debugLog('Member claim transaction starting for uid: $uid');

    try {
      await _db.runTransaction((transaction) async {
        final inviteSnap = await transaction.get(target.inviteRef);
        if (!inviteSnap.exists) throw StateError('Member invite no longer exists.');

        final invite = MemberInvite.fromFirestore(inviteSnap);
        if (invite.status != MemberInviteStatus.pending) {
          throw StateError('This member invite has already been used or cancelled.');
        }
        if (_normalizeEmail(invite.email) != normalized) {
          throw StateError('Member invite email does not match this account.');
        }
        if (invite.role != 'member') {
          throw StateError('This invite is not a member invite.');
        }
        if (invite.gymId.trim().isEmpty || invite.memberId.trim().isEmpty) {
          throw StateError('Member invite is missing gym or member details.');
        }
        if (invite.expiresAt != null && !invite.expiresAt!.isAfter(DateTime.now())) {
          throw StateError('This member invite has expired.');
        }

        final userRef = _db.collection('users').doc(uid);
        final userSnap = await transaction.get(userRef);
        if (userSnap.exists) {
          throw StateError('A user profile already exists for this account.');
        }

        final memberRef = _paths.memberDoc(invite.gymId, invite.memberId);
        final memberSnap = await transaction.get(memberRef);
        if (!memberSnap.exists) throw StateError('Linked member no longer exists.');
        final memberData = memberSnap.data() ?? <String, dynamic>{};
        if (((memberData['authUid'] as String?) ?? '').trim().isNotEmpty) {
          throw StateError('This member is already linked to a login account.');
        }

        final displayName =
            fullName.trim().isNotEmpty ? fullName.trim() : invite.fullName;
        final resolvedPhone =
            phone != null && phone.trim().isNotEmpty ? phone.trim() : invite.phone;
        final now = FieldValue.serverTimestamp();

        transaction.set(userRef, {
          'displayName': displayName,
          'email': normalized,
          'phone': resolvedPhone,
          'role': 'member',
          'status': 'active',
          'defaultGymId': invite.gymId,
          'createdAt': now,
          'updatedAt': now,
          'inviteId': invite.id,
          'createdFromInvite': true,
          'linkedMemberId': invite.memberId,
        });
        _debugLog('users/$uid member profile creation queued.');

        transaction.update(memberRef, {
          'authUid': uid,
          'email': normalized,
          'emailNormalized': normalized,
          'accountStatus': 'active',
          'updatedAt': now,
        });
        _debugLog('gyms/${invite.gymId}/members/${invite.memberId} link queued.');

        transaction.update(target.inviteRef, {
          'status': MemberInviteStatus.claimed,
          'claimedAt': now,
          'claimedByUid': uid,
          'updatedAt': now,
        });
        _debugLog('Member invite ${invite.id} claimed update queued.');
      });
    } on FirebaseException catch (error) {
      _debugLog('Member claim FirebaseException: ${error.code} ${error.message}');
      throw StateError(_mapClaimError(error));
    }
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  String _mapLookupError(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Member invite lookup was blocked by Firestore rules.';
    }
    if (error.code == 'failed-precondition') {
      return 'Member invite lookup requires a Firestore collection group index for memberInvites on emailNormalized and status.';
    }
    return 'Member invite lookup failed (${error.code}): ${error.message ?? 'Firestore error'}';
  }

  String _mapClaimError(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Member invite claim was blocked by Firestore rules.';
    }
    return 'Member invite claim failed (${error.code}): ${error.message ?? 'Firestore error'}';
  }

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[MemberInviteSignup] $message');
  }
}

class MemberInviteClaimTarget {
  final MemberInvite invite;
  final DocumentReference<Map<String, dynamic>> inviteRef;

  const MemberInviteClaimTarget({
    required this.invite,
    required this.inviteRef,
  });
}
